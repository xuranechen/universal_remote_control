import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/control_event.dart';

/// 平台特定的输入模拟服务
class PlatformInputService {
  static final Logger _logger = Logger();
  static const MethodChannel _channel = MethodChannel('com.example.universal_remote_control/input');
  
  bool _isInitialized = false;

  /// 初始化平台输入服务
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('平台输入服务已初始化');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Android平台初始化
        final result = await _channel.invokeMethod('initialize');
        _logger.i('Android输入服务初始化结果: $result');
      } else if (Platform.isIOS) {
        // iOS平台暂不支持输入模拟
        _logger.w('iOS平台暂不支持输入模拟');
        throw UnsupportedError('iOS平台暂不支持输入模拟');
      }
      
      _isInitialized = true;
      _logger.i('平台输入服务已初始化: ${Platform.operatingSystem}');
    } catch (e) {
      _logger.e('初始化平台输入服务失败: $e');
      rethrow;
    }
  }

  /// 处理控制事件
  Future<void> handleEvent(ControlEvent event) async {
    if (!_isInitialized) {
      _logger.w('平台输入服务未初始化');
      return;
    }

    try {
      if (Platform.isAndroid) {
        await _handleAndroidEvent(event);
      } else {
        _logger.w('当前平台不支持输入模拟: ${Platform.operatingSystem}');
      }
    } catch (e) {
      _logger.e('处理控制事件失败: $e');
    }
  }

  /// 处理Android平台事件
  Future<void> _handleAndroidEvent(ControlEvent event) async {
    try {
      switch (event.subtype) {
        case EventSubtype.mouseMove:
          await _channel.invokeMethod('mouseMove', {
            'dx': event.data['dx'],
            'dy': event.data['dy'],
          });
          break;
          
        case EventSubtype.mouseClick:
          await _channel.invokeMethod('mouseClick', {
            'button': event.data['button'],
            'state': event.data['state'],
          });
          break;
          
        case EventSubtype.mouseScroll:
          await _channel.invokeMethod('mouseScroll', {
            'dx': event.data['dx'],
            'dy': event.data['dy'],
          });
          break;
          
        case EventSubtype.keyboard:
          await _channel.invokeMethod('keyboard', {
            'key': event.data['key'],
            'state': event.data['state'],
            'ctrl': event.data['ctrl'] ?? false,
            'shift': event.data['shift'] ?? false,
            'alt': event.data['alt'] ?? false,
          });
          break;
          
        case EventSubtype.touch:
          await _channel.invokeMethod('touch', {
            'x': event.data['x'],
            'y': event.data['y'],
            'action': event.data['action'],
          });
          break;
          
        case EventSubtype.text:
          await _channel.invokeMethod('text', {
            'text': event.data['text'],
          });
          break;
          
        default:
          _logger.w('未处理的Android事件类型: ${event.subtype.name}');
      }
      
      _logger.d('Android事件处理成功: ${event.subtype.name}');
    } catch (e) {
      _logger.e('Android事件处理失败: $e');
      rethrow;
    }
  }

  /// 检查辅助功能服务状态
  Future<bool> checkAccessibilityService() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod('checkAccessibilityService');
      return result as bool? ?? false;
    } catch (e) {
      _logger.e('检查辅助功能服务失败: $e');
      return false;
    }
  }

  /// 请求开启辅助功能服务
  Future<void> requestAccessibilityService() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('requestAccessibilityService');
    } catch (e) {
      _logger.e('请求辅助功能服务失败: $e');
      rethrow;
    }
  }

  /// 获取屏幕尺寸
  Future<Map<String, int>?> getScreenSize() async {
    try {
      final result = await _channel.invokeMethod('getScreenSize');
      if (result != null) {
        return Map<String, int>.from(result);
      }
      return null;
    } catch (e) {
      _logger.e('获取屏幕尺寸失败: $e');
      return null;
    }
  }

  /// 释放资源
  void dispose() {
    _isInitialized = false;
  }
}
