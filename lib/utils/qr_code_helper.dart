import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/device_info.dart';

/// 二维码连接信息
class QRConnectionInfo {
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;
  final String ip;
  final int port;
  final String protocol;
  final int timestamp;

  QRConnectionInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.ip,
    required this.port,
    this.protocol = 'ws',
    required this.timestamp,
  });

  factory QRConnectionInfo.fromDeviceInfo(DeviceInfo deviceInfo) {
    return QRConnectionInfo(
      deviceId: deviceInfo.id,
      deviceName: deviceInfo.name,
      deviceType: deviceInfo.type,
      ip: deviceInfo.ip,
      port: deviceInfo.port,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  DeviceInfo toDeviceInfo() {
    return DeviceInfo(
      id: deviceId,
      name: deviceName,
      type: deviceType,
      mode: DeviceMode.controlled,
      ip: ip,
      port: port,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType.name,
      'ip': ip,
      'port': port,
      'protocol': protocol,
      'timestamp': timestamp,
    };
  }

  factory QRConnectionInfo.fromJson(Map<String, dynamic> json) {
    return QRConnectionInfo(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      deviceType: DeviceType.values.firstWhere(
        (e) => e.name == json['deviceType'],
        orElse: () => DeviceType.unknown,
      ),
      ip: json['ip'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String? ?? 'ws',
      timestamp: json['timestamp'] as int,
    );
  }
}

/// 二维码工具类
class QRCodeHelper {
  static final Logger _logger = Logger();

  /// 生成连接二维码数据
  static String generateQRData(DeviceInfo deviceInfo) {
    try {
      final connectionInfo = QRConnectionInfo.fromDeviceInfo(deviceInfo);
      final jsonData = connectionInfo.toJson();
      
      // 添加版本标识和类型标识
      final qrData = {
        'type': 'universal_remote_control',
        'version': '1.0',
        'data': jsonData,
      };
      
      final qrString = jsonEncode(qrData);
      _logger.d('生成二维码数据: $qrString');
      return qrString;
    } catch (e) {
      _logger.e('生成二维码数据失败: $e');
      rethrow;
    }
  }

  /// 解析二维码数据
  static QRConnectionInfo? parseQRData(String qrData) {
    try {
      final jsonData = jsonDecode(qrData) as Map<String, dynamic>;
      
      // 验证格式
      if (jsonData['type'] != 'universal_remote_control') {
        _logger.w('不是有效的远程控制二维码');
        return null;
      }
      
      final version = jsonData['version'] as String?;
      if (version != '1.0') {
        _logger.w('不支持的二维码版本: $version');
        return null;
      }
      
      final data = jsonData['data'] as Map<String, dynamic>;
      final connectionInfo = QRConnectionInfo.fromJson(data);
      
      _logger.i('解析二维码成功: ${connectionInfo.deviceName} (${connectionInfo.ip}:${connectionInfo.port})');
      return connectionInfo;
    } catch (e) {
      _logger.e('解析二维码数据失败: $e');
      return null;
    }
  }

  /// 验证连接信息是否有效
  static bool isValidConnectionInfo(QRConnectionInfo info) {
    // 检查IP地址格式
    if (!_isValidIP(info.ip)) {
      _logger.w('无效的IP地址: ${info.ip}');
      return false;
    }
    
    // 检查端口范围
    if (info.port < 1 || info.port > 65535) {
      _logger.w('无效的端口: ${info.port}');
      return false;
    }
    
    // 检查时间戳（不能太旧，避免重放攻击）
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - info.timestamp;
    if (age > 24 * 60 * 60 * 1000) { // 24小时
      _logger.w('二维码已过期');
      return false;
    }
    
    return true;
  }

  /// 验证IP地址格式
  static bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    
    return true;
  }

  /// 生成用于显示的连接信息摘要
  static String getConnectionSummary(QRConnectionInfo info) {
    return '${info.deviceName}\n${info.ip}:${info.port}\n${_getDeviceTypeName(info.deviceType)}';
  }

  static String _getDeviceTypeName(DeviceType type) {
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
