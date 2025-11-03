import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/control_event.dart';
import '../models/device_info.dart';

/// 通信协议处理器
class Protocol {
  static final Logger _logger = Logger();

  /// 编码控制事件为JSON字符串
  static String encodeEvent(ControlEvent event) {
    try {
      final json = event.toJson();
      return jsonEncode(json);
    } catch (e) {
      _logger.e('编码事件失败: $e');
      rethrow;
    }
  }

  /// 解码JSON字符串为控制事件
  static ControlEvent decodeEvent(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return ControlEvent.fromJson(json);
    } catch (e) {
      _logger.e('解码事件失败: $e');
      rethrow;
    }
  }

  /// 编码设备信息
  static String encodeDeviceInfo(DeviceInfo deviceInfo) {
    try {
      final json = deviceInfo.toJson();
      return jsonEncode(json);
    } catch (e) {
      _logger.e('编码设备信息失败: $e');
      rethrow;
    }
  }

  /// 解码设备信息
  static DeviceInfo decodeDeviceInfo(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return DeviceInfo.fromJson(json);
    } catch (e) {
      _logger.e('解码设备信息失败: $e');
      rethrow;
    }
  }

  /// 创建握手消息
  static String createHandshake(DeviceInfo localDevice) {
    final message = {
      'type': 'handshake',
      'device': localDevice.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(message);
  }

  /// 解析握手消息
  static DeviceInfo? parseHandshake(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (json['type'] == 'handshake') {
        return DeviceInfo.fromJson(json['device'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('解析握手消息失败: $e');
      return null;
    }
  }

  /// 创建心跳消息
  static String createHeartbeat() {
    final message = {
      'type': 'heartbeat',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(message);
  }

  /// 判断是否为心跳消息
  static bool isHeartbeat(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return json['type'] == 'heartbeat';
    } catch (e) {
      return false;
    }
  }

  /// 创建确认消息
  static String createAck(String messageId) {
    final message = {
      'type': 'ack',
      'messageId': messageId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(message);
  }

  /// 创建错误消息
  static String createError(String errorMessage) {
    final message = {
      'type': 'error',
      'message': errorMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(message);
  }
}

