import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/device_info.dart';
import '../../core/device_discovery.dart';
import 'controller_page.dart';

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
      MaterialPageRoute(
        builder: (context) => ControllerPage(
          localDevice: widget.localDevice,
          targetDevice: device,
        ),
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
      appBar: AppBar(
        title: const Text('选择设备'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _manualAddDevice,
            tooltip: '手动添加',
          ),
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? _stopScanning : _startScanning,
            tooltip: _isScanning ? '停止扫描' : '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 扫描状态指示器
          if (_isScanning)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '正在扫描局域网设备...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

          // 设备列表
          Expanded(
            child: _devices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return _buildDeviceCard(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _isScanning ? '正在搜索设备...' : '未发现设备',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '确保设备在同一局域网内\n并已启动被控端模式',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('重新扫描'),
            ),
        ],
      ),
    );
  }

  /// 构建设备卡片
  Widget _buildDeviceCard(DeviceInfo device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _getDeviceIcon(device.type),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(device.name),
        subtitle: Text('${device.ip} • ${_getDeviceTypeName(device.type)}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _connectToDevice(device),
      ),
    );
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

