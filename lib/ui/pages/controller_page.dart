import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_info.dart';
import '../../models/connection_state.dart';
import '../../services/websocket_service.dart';
import '../../services/input_capture_service.dart';
import '../widgets/virtual_touchpad.dart';
import '../widgets/gyro_controller.dart';

/// 控制端页面
class ControllerPage extends StatefulWidget {
  final DeviceInfo localDevice;
  final DeviceInfo targetDevice;

  const ControllerPage({
    super.key,
    required this.localDevice,
    required this.targetDevice,
  });

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  ConnectionState _connectionState = ConnectionState.disconnected();
  bool _gyroEnabled = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  /// 连接到目标设备
  Future<void> _connectToDevice() async {
    try {
      final wsService = context.read<WebSocketService>();
      final inputCapture = context.read<InputCaptureService>();

      // 监听连接状态
      wsService.stateStream.listen((state) {
        setState(() {
          _connectionState = state;
        });
      });

      // 监听输入捕获事件并转发
      inputCapture.eventStream.listen((event) {
        wsService.sendEvent(event);
      });

      // 连接到目标设备
      await wsService.connectToServer(
        widget.targetDevice.ip,
        port: widget.targetDevice.port,
      );

      // 开始输入捕获
      inputCapture.startCapture(enableGyro: false); // 默认不启用陀螺仪
    } catch (e) {
      print('连接失败: $e');
      _showError('连接失败: $e');
    }
  }

  /// 断开连接
  Future<void> _disconnect() async {
    try {
      final wsService = context.read<WebSocketService>();
      final inputCapture = context.read<InputCaptureService>();

      inputCapture.stopCapture();
      await wsService.disconnect();
    } catch (e) {
      print('断开连接失败: $e');
    }
  }

  /// 切换陀螺仪
  void _toggleGyro() {
    setState(() {
      _gyroEnabled = !_gyroEnabled;
    });

    final inputCapture = context.read<InputCaptureService>();
    if (_gyroEnabled) {
      inputCapture.startCapture(enableGyro: true);
    } else {
      inputCapture.stopCapture();
      inputCapture.startCapture(enableGyro: false);
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
        title: Text('控制: ${widget.targetDevice.name}'),
        actions: [
          // 连接状态指示器
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: _buildConnectionIndicator(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          _buildStatusBar(),

          // 控制区域
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // 触摸板模式
                VirtualTouchpad(
                  onMove: (dx, dy) {
                    final inputCapture = context.read<InputCaptureService>();
                    inputCapture.sendMouseMove(dx, dy);
                  },
                  onTap: () {
                    final inputCapture = context.read<InputCaptureService>();
                    inputCapture.sendMouseClick();
                  },
                ),

                // 陀螺仪模式
                GyroController(
                  enabled: _gyroEnabled,
                  onToggle: _toggleGyro,
                ),
              ],
            ),
          ),

          // 底部工具栏
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  /// 构建连接状态指示器
  Widget _buildConnectionIndicator() {
    Color color;
    String text;

    switch (_connectionState.status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        text = '已连接';
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        text = '连接中';
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        text = '错误';
        break;
      default:
        color = Colors.grey;
        text = '未连接';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedTab == 0 
                  ? '触摸板模式 - 滑动移动鼠标，点击执行点击'
                  : _gyroEnabled 
                      ? '陀螺仪已启用 - 移动设备控制鼠标'
                      : '陀螺仪已禁用 - 点击按钮启用',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部工具栏
  Widget _buildBottomToolbar() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (index) {
        setState(() {
          _selectedTab = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.touch_app),
          label: '触摸板',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.screen_rotation),
          label: '陀螺仪',
        ),
      ],
    );
  }
}

