import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../models/device_info.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/animations.dart';
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
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(context),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在初始化设备信息...'),
              ],
            ),
          ),
        ),
      );
    }

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
                _buildDeviceInfoCard(context),
                const SizedBox(height: 32),
                _buildModeSelection(context, isVertical: true),
                const SizedBox(height: 24),
                _buildFooter(context),
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
                _buildDeviceInfoCard(context),
                const SizedBox(height: 40),
                _buildModeSelection(context, isVertical: false),
                const SizedBox(height: 32),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 桌面端布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // 左侧设备信息
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeviceInfoCard(context),
                const SizedBox(height: 24),
                _buildFooter(context),
              ],
            ),
          ),
        ),
        // 右侧模式选择
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(context, showAppBar: false),
                const SizedBox(height: 40),
                _buildModeSelection(context, isVertical: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context, {bool showAppBar = true}) {
    if (!showAppBar) {
      return Column(
        children: [
          Text(
            'Universal Remote Control',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '选择工作模式',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Universal Remote Control',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '跨平台远程控制',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          padding: ResponsiveHelper.responsive(
            context,
            mobile: const EdgeInsets.all(24),
            tablet: const EdgeInsets.all(32),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDeviceIcon(_localDevice!.type),
                  size: ResponsiveHelper.getIconSize(context),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _localDevice!.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getDeviceTypeName(_localDevice!.type),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建模式选择
  Widget _buildModeSelection(BuildContext context, {required bool isVertical}) {
    if (isVertical) {
      // 竖屏下在可滚动的 Column 中，不使用 Expanded，避免无限高度约束问题
      return Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _buildEnhancedModeCard(
              context,
              icon: Icons.gamepad_outlined,
              title: '控制端模式',
              description: '使用此设备控制其他设备',
              gradient: [Colors.blue.shade400, Colors.blue.shade600],
              onTap: () => _enterControllerMode(context),
            ),
            const SizedBox(height: 20),
            _buildEnhancedModeCard(
              context,
              icon: Icons.desktop_windows_outlined,
              title: '被控端模式',
              description: '允许其他设备控制此设备',
              gradient: [Colors.green.shade400, Colors.green.shade600],
              onTap: () => _enterControlledMode(context),
            ),
          ],
        ),
      );
    }

    // 横向布局时使用 Expanded 平分宽度
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedModeCard(
              context,
              icon: Icons.gamepad_outlined,
              title: '控制端模式',
              description: '使用此设备控制其他设备',
              gradient: [Colors.blue.shade400, Colors.blue.shade600],
              onTap: () => _enterControllerMode(context),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildEnhancedModeCard(
              context,
              icon: Icons.desktop_windows_outlined,
              title: '被控端模式',
              description: '允许其他设备控制此设备',
              gradient: [Colors.green.shade400, Colors.green.shade600],
              onTap: () => _enterControlledMode(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建增强的模式选择卡片
  Widget _buildEnhancedModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return AppAnimations.buildTapAnimation(
      onTap: onTap,
      child: Container(
        height: ResponsiveHelper.responsive(
          context,
          mobile: 160,
          tablet: 180,
          desktop: 200,
        ),
        child: Card(
          elevation: 6,
          shadowColor: gradient.first.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradient.first.withOpacity(0.1),
                    gradient.last.withOpacity(0.05),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gradient.first.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: ResponsiveHelper.responsive(
                        context,
                        mobile: 32,
                        tablet: 36,
                        desktop: 40,
                      ),
                      color: gradient.first,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gradient.first,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部信息
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '基于局域网的安全连接',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '支持 Windows • macOS • Linux • Android',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 进入控制端模式
  void _enterControllerMode(BuildContext context) {
    final updatedDevice = _localDevice!.copyWith(mode: DeviceMode.controller);
    
    Navigator.push(
      context,
      AppAnimations.createRoute(
        page: DeviceListPage(localDevice: updatedDevice),
        type: RouteTransitionType.slideAndFade,
        direction: SlideDirection.fromRight,
      ),
    );
  }

  /// 进入被控端模式
  void _enterControlledMode(BuildContext context) {
    final updatedDevice = _localDevice!.copyWith(mode: DeviceMode.controlled);
    
    Navigator.push(
      context,
      AppAnimations.createRoute(
        page: ControlledPage(localDevice: updatedDevice),
        type: RouteTransitionType.slideAndFade,
        direction: SlideDirection.fromLeft,
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
