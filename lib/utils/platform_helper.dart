import 'dart:io';
import '../models/device_info.dart';

/// 平台辅助工具
class PlatformHelper {
  /// 获取当前平台的设备类型
  static DeviceType getCurrentPlatformType() {
    if (Platform.isAndroid) {
      return DeviceType.android;
    } else if (Platform.isIOS) {
      return DeviceType.ios;
    } else if (Platform.isWindows) {
      return DeviceType.windows;
    } else if (Platform.isMacOS) {
      return DeviceType.macos;
    } else if (Platform.isLinux) {
      return DeviceType.linux;
    }
    return DeviceType.unknown;
  }

  /// 检查平台是否支持陀螺仪
  static bool supportsGyro() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 检查平台是否支持输入模拟
  static bool supportsInputSimulation() {
    // 所有平台都支持，但需要不同的实现
    return true;
  }

  /// 获取平台特定的原生库名称
  static String? getNativeLibraryName() {
    if (Platform.isWindows) {
      return 'input_simulator_windows.dll';
    } else if (Platform.isLinux) {
      return 'libinput_simulator_linux.so';
    } else if (Platform.isMacOS) {
      return 'libinput_simulator_macos.dylib';
    }
    return null; // Android使用不同的方式
  }

  /// 检查是否为移动平台
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 检查是否为桌面平台
  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}

