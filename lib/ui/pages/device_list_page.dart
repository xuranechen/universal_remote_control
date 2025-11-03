import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_info.dart';
import '../../core/device_discovery.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/animations.dart';
import 'controller_page.dart';
import 'qr_scanner_page.dart';

/// 设备列表页面 - 扫描并连接到被控设备
class DeviceListPage extends StatefulWidget {
  final DeviceInfo localDevice;

  const DeviceListPage({
    super.key,
    required this.localDevice,
  });

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  bool _isScanning = false;
  List<DeviceInfo> _devices = [];

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    _stopScanning();
    super.dispose();
  }

  /// 开始扫描设备
  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final discovery = context.read<DeviceDiscovery>();
      
      // 监听发现的设备
      discovery.devicesStream.listen((devices) {
        setState(() {
          // 只显示被控端设备
          _devices = devices
              .where((device) => device.mode == DeviceMode.controlled)
              .toList();
        });
      });

      // 启动设备发现
      await discovery.start(widget.localDevice);
    } catch (e) {
      print('启动设备扫描失败: $e');
      _showError('启动扫描失败: $e');
    }
  }

  /// 停止扫描设备
  void _stopScanning() {
    try {
      final discovery = context.read<DeviceDiscovery>();
      discovery.stop();
    } catch (e) {
      print('停止扫描失败: $e');
    }
    
    setState(() {
      _isScanning = false;
    });
  }

  /// 连接到设备
  void _connectToDevice(DeviceInfo device) {
    Navigator.push(
      context,
      AppAnimations.createRoute(
        page: ControllerPage(
          localDevice: widget.localDevice,
          targetDevice: device,
        ),
        type: RouteTransitionType.slideAndFade,
        direction: SlideDirection.fromRight,
      ),
    );
  }

  /// 手动添加设备
  void _manualAddDevice() {
    showDialog(
      context: context,
      builder: (context) => _ManualAddDeviceDialog(
        onAdd: (device) {
          final discovery = context.read<DeviceDiscovery>();
          discovery.addDevice(device);
        },
      ),
    );
  }

  /// 扫码连接设备
  void _scanQRCode() async {
    try {
      final result = await Navigator.push<DeviceInfo>(
        context,
        AppAnimations.createRoute(
          page: const QRScannerPage(),
          type: RouteTransitionType.slideAndFade,
          direction: SlideDirection.fromBottom,
        ),
      );
      
      if (result != null) {
        // 添加扫描到的设备到发现列表
        final discovery = context.read<DeviceDiscovery>();
        discovery.addDevice(result);
        
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加设备: ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 自动连接到扫描的设备
        _connectToDevice(result);
      }
    } catch (e) {
      print('扫码失败: $e');
      _showError('扫码失败: $e');
    }
  }

  /// 显示错误
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
          child: Column(
            children: [
              _buildHeader(context),
              if (_isScanning) _buildScanningIndicator(context),
              Expanded(
                child: MaxWidthContainer(
                  child: _devices.isEmpty
                      ? _buildEmptyState(context)
                      : _buildDeviceGrid(context),
                ),
              ),
            ],
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

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          Row(
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
                      '发现设备',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '选择要连接的被控端设备',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatsRow(context),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: _scanQRCode,
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: '扫码连接',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _manualAddDevice,
          icon: const Icon(Icons.add),
          tooltip: '手动添加',
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isScanning ? _stopScanning : _startScanning,
          icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
          tooltip: _isScanning ? '停止扫描' : '刷新',
        ),
      ],
    );
  }

  /// 构建统计行
  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.devices,
            label: '已发现',
            value: '${_devices.length}',
          ),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          _buildStatItem(
            context,
            icon: _isScanning ? Icons.search : Icons.check_circle,
            label: _isScanning ? '搜索中' : '已完成',
            value: _isScanning ? '...' : '✓',
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建扫描指示器
  Widget _buildScanningIndicator(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '正在搜索局域网内的被控端设备...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备网格
  Widget _buildDeviceGrid(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumns(context);
    
    if (ResponsiveHelper.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) => AppAnimations.buildListItemAnimation(
          index: index,
          child: _buildEnhancedDeviceCard(_devices[index]),
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: ResponsiveHelper.getCardSpacing(context),
        mainAxisSpacing: ResponsiveHelper.getCardSpacing(context),
        childAspectRatio: 1.2,
      ),
      itemCount: _devices.length,
      itemBuilder: (context, index) => AppAnimations.buildListItemAnimation(
        index: index,
        child: _buildEnhancedDeviceCard(_devices[index]),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 60,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isScanning ? '正在搜索设备...' : '未发现设备',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '确保设备在同一局域网内并已启动被控端模式',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            if (!_isScanning) _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  /// 构建快速操作按钮
  Widget _buildQuickActions(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType) {
        final isVertical = screenType == ScreenType.mobile;
        
        final children = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('重新扫描'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            width: isVertical ? 0 : 12,
            height: isVertical ? 12 : 0,
          ),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('扫码连接'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ];

        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: isVertical
              ? Column(children: children)
              : Row(children: children),
        );
      },
    );
  }

  /// 构建增强的设备卡片
  Widget _buildEnhancedDeviceCard(DeviceInfo device) {
    return AppAnimations.buildTapAnimation(
      onTap: () => _connectToDevice(device),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _connectToDevice(device),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Row(
              children: [
                // 设备图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getDeviceColor(device.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getDeviceIcon(device.type),
                    color: _getDeviceColor(device.type),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // 设备信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.computer,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDeviceTypeName(device.type),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.wifi,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.ip,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 连接按钮
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取设备颜色
  Color _getDeviceColor(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return Colors.green;
      case DeviceType.ios:
        return Colors.blue;
      case DeviceType.windows:
        return Colors.blue.shade700;
      case DeviceType.macos:
        return Colors.grey.shade700;
      case DeviceType.linux:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return Icons.phone_android;
      case DeviceType.ios:
        return Icons.phone_iphone;
      case DeviceType.windows:
        return Icons.computer;
      case DeviceType.macos:
        return Icons.laptop_mac;
      case DeviceType.linux:
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  String _getDeviceTypeName(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.windows:
        return 'Windows';
      case DeviceType.macos:
        return 'macOS';
      case DeviceType.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }
}

/// 手动添加设备对话框
class _ManualAddDeviceDialog extends StatefulWidget {
  final Function(DeviceInfo) onAdd;

  const _ManualAddDeviceDialog({required this.onAdd});

  @override
  State<_ManualAddDeviceDialog> createState() => _ManualAddDeviceDialogState();
}

class _ManualAddDeviceDialogState extends State<_ManualAddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9877');

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final device = DeviceInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: DeviceType.unknown,
        mode: DeviceMode.controlled,
        ip: _ipController.text,
        port: int.parse(_portController.text),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      widget.onAdd(device);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动添加设备'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '设备名称',
                hintText: '例如: 我的电脑',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入设备名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP地址',
                hintText: '例如: 192.168.1.100',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入IP地址';
                }
                // 简单的IP格式验证
                final parts = value.split('.');
                if (parts.length != 4) {
                  return 'IP地址格式不正确';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: '端口号',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入端口号';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return '端口号必须在1-65535之间';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('添加'),
        ),
      ],
    );
  }
}

