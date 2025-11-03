import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_info.dart';
import '../../models/connection_state.dart' as remote;
import '../../services/websocket_service.dart';
import '../../services/input_capture_service.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/virtual_touchpad.dart';
import '../widgets/gyro_controller.dart';
import '../widgets/virtual_keyboard.dart';

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
  remote.RemoteConnectionState _connectionState = remote.RemoteConnectionState.disconnected();
  bool _gyroEnabled = false;
  int _selectedTab = 0; // 0: 触摸板, 1: 陀螺仪, 2: 键盘

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

  /// 连接到设备
  void _connectToDevice() async {
    try {
      setState(() {
        _connectionState = remote.ConnectionState(
          status: remote.RemoteConnectionStatus.connecting,
          errorMessage: null,
        );
      });

      final websocket = context.read<WebSocketService>();
      await websocket.connectToDevice(widget.targetDevice.ip, widget.targetDevice.port);
    } catch (e) {
      setState(() {
        _connectionState = remote.ConnectionState(
          status: remote.RemoteConnectionStatus.error,
          errorMessage: e.toString(),
        );
      });
    }
  }

  /// 断开连接
  void _disconnect() {
    final websocket = context.read<WebSocketService>();
    websocket.stopClient();
    Navigator.pop(context);
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
        _buildConnectionStatus(context),
        Expanded(
          child: _buildControlArea(context),
        ),
        _buildEnhancedBottomNav(context),
      ],
    );
  }

  /// 平板布局
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildConnectionStatus(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildControlArea(context),
          ),
        ),
        _buildEnhancedBottomNav(context),
      ],
    );
  }

  /// 桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // 左侧控制面板
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(context, compact: true),
              const SizedBox(height: 24),
              _buildConnectionCard(context),
              const SizedBox(height: 24),
              _buildControlModeSelector(context),
              const Spacer(),
              _buildQuickActions(context),
            ],
          ),
        ),
        // 右侧控制区域
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            child: _buildControlArea(context),
          ),
        ),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context, {bool compact = false}) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? '控制中' : '正在控制设备',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.targetDevice.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    Color color;
    String text;
    IconData icon;

    switch (_connectionState.status) {
      case remote.RemoteConnectionStatus.connected:
        color = Colors.green;
        text = '已连接';
        icon = Icons.link;
        break;
      case remote.RemoteConnectionStatus.connecting:
        color = Colors.orange;
        text = '连接中';
        icon = Icons.sync;
        break;
      case remote.RemoteConnectionStatus.error:
        color = Colors.red;
        text = '错误';
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        text = '未连接';
        icon = Icons.link_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
            color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建连接状态卡片（桌面端用）
  Widget _buildConnectionCard(BuildContext context) {
    final isConnected = _connectionState.isConnected;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '目标设备',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('设备名称', widget.targetDevice.name, Icons.devices),
            _buildInfoRow('IP地址', widget.targetDevice.ip, Icons.wifi),
            _buildInfoRow('端口', widget.targetDevice.port.toString(), Icons.router),
            _buildInfoRow(
              '连接状态',
              isConnected ? '已连接' : '未连接',
              isConnected ? Icons.check_circle : Icons.cancel,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建连接状态条
  Widget _buildConnectionStatus(BuildContext context) {
    if (!_connectionState.isConnected) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '设备未连接，某些功能可能无法使用',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedTab == 0 
                  ? '触摸板模式：滑动移动鼠标，点击执行操作'
                  : _selectedTab == 1
                      ? _gyroEnabled 
                          ? '陀螺仪模式：移动设备控制鼠标指针'
                          : '陀螺仪模式：点击按钮启用陀螺仪控制'
                      : '键盘模式：点击按钮打开虚拟键盘进行文本输入',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建控制区域
  Widget _buildControlArea(BuildContext context) {
    return IndexedStack(
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

        // 键盘模式
        _buildKeyboardMode(context),
      ],
    );
  }

  /// 构建键盘模式
  Widget _buildKeyboardMode(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '虚拟键盘模式',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮打开虚拟键盘',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppAnimations.buildTapAnimation(
            onTap: () => showVirtualKeyboard(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '打开键盘',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建增强的底部导航栏
  Widget _buildEnhancedBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (index) {
        setState(() {
          _selectedTab = index;
        });
      },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.touch_app),
              activeIcon: Icon(Icons.touch_app),
          label: '触摸板',
        ),
        BottomNavigationBarItem(
              icon: Icon(Icons.screen_rotation_outlined),
              activeIcon: Icon(Icons.screen_rotation),
          label: '陀螺仪',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.keyboard_outlined),
              activeIcon: Icon(Icons.keyboard),
              label: '键盘',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制模式选择器（桌面端用）
  Widget _buildControlModeSelector(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '控制模式',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildModeOption(
              context,
              index: 0,
              icon: Icons.touch_app,
              title: '触摸板',
              description: '滑动控制鼠标',
            ),
            const SizedBox(height: 8),
            _buildModeOption(
              context,
              index: 1,
              icon: Icons.screen_rotation,
              title: '陀螺仪',
              description: '移动设备控制',
            ),
            const SizedBox(height: 8),
            _buildModeOption(
              context,
              index: 2,
              icon: Icons.keyboard,
              title: '键盘',
              description: '虚拟键盘输入',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建模式选项
  Widget _buildModeOption(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedTab == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建快速操作（桌面端用）
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connectionState.isConnected ? null : () => _connectToDevice(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新连接'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _disconnect(),
            icon: const Icon(Icons.close),
            label: const Text('断开连接'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

