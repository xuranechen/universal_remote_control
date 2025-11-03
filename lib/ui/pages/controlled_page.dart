import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../models/device_info.dart';
import '../../models/connection_state.dart' as remote;
import '../../services/websocket_service.dart';
import '../../services/input_simulator_service.dart';

/// 被控端页面
class ControlledPage extends StatefulWidget {
  final DeviceInfo localDevice;

  const ControlledPage({
    super.key,
    required this.localDevice,
  });

  @override
  State<ControlledPage> createState() => _ControlledPageState();
}

class _ControlledPageState extends State<ControlledPage> {
  remote.RemoteConnectionState _connectionState = remote.RemoteConnectionState.disconnected();
  String? _localIp;
  int _eventCount = 0;
  bool _isServerRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeServer();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  /// 初始化服务器
  Future<void> _initializeServer() async {
    try {
      // 获取本地IP
      final networkInfo = NetworkInfo();
      _localIp = await networkInfo.getWifiIP();

      // 初始化输入模拟器
      final simulator = context.read<InputSimulatorService>();
      await simulator.initialize();

      // 启动WebSocket服务器
      final wsService = context.read<WebSocketService>();

      // 监听连接状态
      wsService.stateStream.listen((state) {
        setState(() {
          _connectionState = state;
        });
      });

      // 监听接收到的事件
      wsService.eventStream.listen((event) {
        setState(() {
          _eventCount++;
        });
        // 执行输入模拟
        simulator.handleEvent(event);
      });

      await wsService.startServer(port: widget.localDevice.port);

      setState(() {
        _isServerRunning = true;
      });
    } catch (e) {
      print('初始化服务器失败: $e');
      _showError('初始化失败: $e');
    }
  }

  /// 停止服务器
  Future<void> _stopServer() async {
    try {
      final wsService = context.read<WebSocketService>();
      await wsService.disconnect();
      setState(() {
        _isServerRunning = false;
      });
    } catch (e) {
      print('停止服务器失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('被控端模式'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 状态卡片
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        _connectionState.isConnected
                            ? Icons.link
                            : Icons.wifi_tethering,
                        size: 64,
                        color: _connectionState.isConnected
                            ? Colors.green
                            : Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _connectionState.isConnected
                            ? '已连接'
                            : '等待连接',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connectionState.isConnected
                            ? '控制端正在控制此设备'
                            : '等待控制端连接',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 连接信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '连接信息',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('设备名称', widget.localDevice.name),
                      _buildInfoRow('IP地址', _localIp ?? '获取中...'),
                      _buildInfoRow('端口', widget.localDevice.port.toString()),
                      _buildInfoRow(
                        '服务状态',
                        _isServerRunning ? '运行中' : '已停止',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 统计信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '统计信息',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('已处理事件', _eventCount.toString()),
                      _buildInfoRow(
                        '连接时长',
                        _connectionState.connectedAt != null
                            ? _formatDuration(
                                DateTime.now().difference(
                                  _connectionState.connectedAt!,
                                ),
                              )
                            : '未连接',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '在控制端设备上扫描并连接到此设备，即可开始远程控制',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else if (minutes > 0) {
      return '$minutes分钟$seconds秒';
    } else {
      return '$seconds秒';
    }
  }
}

