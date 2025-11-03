import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/device_info.dart';
import '../../models/connection_state.dart' as remote;
import '../../services/websocket_service.dart';
import '../../services/input_simulator_service.dart';
import '../../core/device_discovery.dart';
import '../../utils/qr_code_helper.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/animations.dart';
import '../../utils/platform_helper.dart';

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
  String? _qrData;

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
      _localIp = await PlatformHelper.getLocalIP();
      setState(() {});
      _generateQRCode();

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
      wsService.eventStream.listen((event) async {
        setState(() {
          _eventCount++;
        });
        // 执行输入模拟
        await simulator.handleEvent(event);
      });

      await wsService.startServer(port: widget.localDevice.port);

      setState(() {
        _isServerRunning = true;
      });

      // 启动设备发现广播（使本设备可被发现）
      final discovery = context.read<DeviceDiscovery>();
      await discovery.start(widget.localDevice);

      // 服务器启动后，状态会更新，二维码已在获取IP后生成
    } catch (e) {
      print('初始化服务器失败: $e');
      _showError('初始化失败: $e');
    }
  }

  /// 停止服务器
  Future<void> _stopServer() async {
    try {
      // 停止设备发现广播
      try {
        final discovery = context.read<DeviceDiscovery>();
        discovery.stop();
      } catch (_) {}

      final wsService = context.read<WebSocketService>();
      await wsService.disconnect();
      setState(() {
        _isServerRunning = false;
      });
    } catch (e) {
      print('停止服务器失败: $e');
    }
  }

  /// 生成二维码数据
  void _generateQRCode() {
    try {
      if (_localIp != null && _localIp!.isNotEmpty) {
        final deviceWithIP = widget.localDevice.copyWith(
          ip: _localIp!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        
        _qrData = QRCodeHelper.generateQRData(deviceWithIP);
        setState(() {});
      }
    } catch (e) {
      print('生成二维码失败: $e');
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
      body: Container(
        decoration: _buildGradientBackground(context),
        child: SafeArea(
          child: MaxWidthContainer(
            child: ResponsiveBuilder(
              builder: (context, screenType) {
                switch (screenType) {
                  case ScreenType.mobile:
                    return _buildMobileLayout(context);
                  case ScreenType.tablet:
                    return _buildTabletLayout(context);
                  case ScreenType.desktop:
                    return _buildDesktopLayout(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 构建渐变背景
  BoxDecoration _buildGradientBackground(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
          Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          Theme.of(context).colorScheme.surface,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// 移动端布局
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 20),
                _buildConnectionInfo(context),
                const SizedBox(height: 20),
                if (_qrData != null) ...[
                  _buildQRCodeCard(context),
                  const SizedBox(height: 20),
                ],
                _buildStatsCard(context),
                const SizedBox(height: 20),
                _buildTipsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 平板布局
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildStatusCard(context),
                          const SizedBox(height: 20),
                          _buildConnectionInfo(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          if (_qrData != null) ...[
                            _buildQRCodeCard(context),
                            const SizedBox(height: 20),
                          ],
                          _buildStatsCard(context),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTipsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
        child: Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧状态和连接信息
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildStatusCard(context),
                      const SizedBox(height: 24),
                      _buildConnectionInfo(context),
                      const SizedBox(height: 24),
                      _buildStatsCard(context),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // 右侧二维码和提示
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (_qrData != null) ...[
                        _buildQRCodeCard(context),
                        const SizedBox(height: 24),
                      ],
                      _buildTipsCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '被控端模式',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '等待控制端连接',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          _buildConnectionStatusBadge(context),
        ],
      ),
    );
  }

  /// 构建连接状态徽章
  Widget _buildConnectionStatusBadge(BuildContext context) {
    final isConnected = _connectionState.isConnected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? '已连接' : '等待连接',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard(BuildContext context) {
    final isConnected = _connectionState.isConnected;
    
    return Card(
      elevation: 6,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isConnected
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
          child: Column(
            children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withOpacity(0.2)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.link : Icons.wifi_tethering,
                size: 40,
                color: isConnected
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isConnected ? '设备已连接' : '等待连接',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.green : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isConnected
                  ? '控制端正在控制此设备'
                  : '启动服务成功，等待控制端连接',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建连接信息卡片
  Widget _buildConnectionInfo(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '连接信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('设备名称', widget.localDevice.name, Icons.devices),
            _buildInfoRow('IP地址', _localIp ?? '获取中...', Icons.wifi),
            _buildInfoRow('端口', widget.localDevice.port.toString(), Icons.router),
            _buildInfoRow(
              '服务状态',
              _isServerRunning ? '运行中' : '已停止',
              _isServerRunning ? Icons.check_circle : Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建二维码卡片
  Widget _buildQRCodeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '扫码连接',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PulseAnimation(
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: ResponsiveHelper.responsive(
                    context,
                    mobile: 160,
                    tablet: 180,
                    desktop: 200,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '使用控制端扫描此二维码快速连接',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '统计信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: '处理事件',
                    value: _eventCount.toString(),
                    icon: Icons.touch_app,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: '连接时长',
                    value: _connectionState.connectedAt != null
                        ? _formatDuration(
                            DateTime.now().difference(_connectionState.connectedAt!),
                          )
                        : '未连接',
                    icon: Icons.timer,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建提示卡片
  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '使用提示',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在控制端设备上扫描二维码或手动连接此设备，即可开始远程控制',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
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

