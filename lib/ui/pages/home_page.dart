import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../models/device_info.dart';
import '../../core/device_discovery.dart';
import 'controller_page.dart';
import 'controlled_page.dart';
import 'device_list_page.dart';

/// 主页 - 模式选择
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeviceInfo? _localDevice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocalDevice();
  }

  /// 初始化本地设备信息
  Future<void> _initializeLocalDevice() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceName = 'Unknown Device';
      DeviceType deviceType = DeviceType.unknown;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceType = DeviceType.android;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = '${iosInfo.name}';
        deviceType = DeviceType.ios;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceName = windowsInfo.computerName;
        deviceType = DeviceType.windows;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceName = macInfo.computerName;
        deviceType = DeviceType.macos;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceName = linuxInfo.name;
        deviceType = DeviceType.linux;
      }

      _localDevice = DeviceInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: deviceName,
        type: deviceType,
        mode: DeviceMode.idle,
        ip: '0.0.0.0', // 将在启动服务时获取实际IP
        port: 9877,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('初始化设备信息失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _localDevice == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Remote Control'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 设备信息卡片
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        _getDeviceIcon(_localDevice!.type),
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _localDevice!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDeviceTypeName(_localDevice!.type),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 模式选择标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '选择模式',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 模式选择按钮
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildModeCard(
                          context,
                          icon: Icons.gamepad_outlined,
                          title: '控制端模式',
                          description: '使用此设备控制其他设备',
                          color: Colors.blue,
                          onTap: () => _enterControllerMode(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildModeCard(
                          context,
                          icon: Icons.desktop_windows_outlined,
                          title: '被控端模式',
                          description: '允许其他设备控制此设备',
                          color: Colors.green,
                          onTap: () => _enterControlledMode(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 底部信息
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '基于局域网的跨平台远程控制',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建模式选择卡片
  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 进入控制端模式
  void _enterControllerMode(BuildContext context) {
    final updatedDevice = _localDevice!.copyWith(mode: DeviceMode.controller);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceListPage(localDevice: updatedDevice),
      ),
    );
  }

  /// 进入被控端模式
  void _enterControlledMode(BuildContext context) {
    final updatedDevice = _localDevice!.copyWith(mode: DeviceMode.controlled);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlledPage(localDevice: updatedDevice),
      ),
    );
  }

  /// 获取设备图标
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

  /// 获取设备类型名称
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

