import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:win32/win32.dart';
import '../models/control_event.dart';

/// Windows输入模拟服务（使用win32包直接调用Windows API）
class WindowsInputService {
  static final Logger _logger = Logger();

  /// 处理控制事件
  Future<void> handleEvent(ControlEvent event) async {
    try {
      switch (event.subtype) {
        case EventSubtype.mouseMove:
          _handleMouseMove(event);
          break;
        case EventSubtype.mouseClick:
          _handleMouseClick(event);
          break;
        case EventSubtype.mouseScroll:
          _handleMouseScroll(event);
          break;
        case EventSubtype.keyboard:
          _handleKeyboard(event);
          break;
        default:
          _logger.w('未处理的事件类型: ${event.subtype.name}');
      }
    } catch (e) {
      _logger.e('处理Windows输入事件失败: $e');
    }
  }

  /// 处理鼠标移动
  void _handleMouseMove(ControlEvent event) {
    final dx = (event.data['dx'] as num).toInt();
    final dy = (event.data['dy'] as num).toInt();

    final input = calloc<INPUT>();
    input.ref.type = INPUT_MOUSE;
    input.ref.mi.dx = dx;
    input.ref.mi.dy = dy;
    input.ref.mi.dwFlags = MOUSEEVENTF_MOVE;

    SendInput(1, input, sizeOf<INPUT>());
    free(input);

    _logger.d('鼠标移动: dx=$dx, dy=$dy');
  }

  /// 处理鼠标点击
  void _handleMouseClick(ControlEvent event) {
    final buttonName = event.data['button'] as String;
    int downFlag, upFlag;

    switch (buttonName) {
      case 'left':
        downFlag = MOUSEEVENTF_LEFTDOWN;
        upFlag = MOUSEEVENTF_LEFTUP;
        break;
      case 'right':
        downFlag = MOUSEEVENTF_RIGHTDOWN;
        upFlag = MOUSEEVENTF_RIGHTUP;
        break;
      case 'middle':
        downFlag = MOUSEEVENTF_MIDDLEDOWN;
        upFlag = MOUSEEVENTF_MIDDLEUP;
        break;
      default:
        return;
    }

    final inputs = calloc<INPUT>(2);

    // 按下
    inputs[0].type = INPUT_MOUSE;
    inputs[0].mi.dwFlags = downFlag;

    // 释放
    inputs[1].type = INPUT_MOUSE;
    inputs[1].mi.dwFlags = upFlag;

    SendInput(2, inputs, sizeOf<INPUT>());
    free(inputs);

    _logger.d('鼠标点击: button=$buttonName');
  }

  /// 处理鼠标滚轮
  void _handleMouseScroll(ControlEvent event) {
    final dx = (event.data['dx'] as num).toInt();
    final dy = (event.data['dy'] as num).toInt();

    if (dy != 0) {
      final input = calloc<INPUT>();
      input.ref.type = INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSEEVENTF_WHEEL;
      input.ref.mi.mouseData = (dy * 120).toInt();

      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    }

    if (dx != 0) {
      final input = calloc<INPUT>();
      input.ref.type = INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSEEVENTF_HWHEEL;
      input.ref.mi.mouseData = (dx * 120).toInt();

      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    }

    _logger.d('鼠标滚轮: dx=$dx, dy=$dy');
  }

  /// 处理键盘输入
  void _handleKeyboard(ControlEvent event) {
    final key = event.data['key'] as String;
    final modifiers = event.data['modifiers'] as List<dynamic>?;

    // 按下修饰键
    if (modifiers != null) {
      for (final mod in modifiers) {
        _pressKey(_getVirtualKeyCode(mod.toString()), down: true);
      }
    }

    // 按下主键
    final keyCode = _getVirtualKeyCode(key);
    _pressKey(keyCode, down: true);
    _pressKey(keyCode, down: false);

    // 释放修饰键
    if (modifiers != null) {
      for (final mod in modifiers.reversed) {
        _pressKey(_getVirtualKeyCode(mod.toString()), down: false);
      }
    }

    _logger.d('键盘输入: key=$key');
  }

  /// 按键操作
  void _pressKey(int keyCode, {required bool down}) {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_KEYBOARD;
    input.ref.ki.wVk = keyCode;
    input.ref.ki.dwFlags = down ? 0 : KEYEVENTF_KEYUP;

    SendInput(1, input, sizeOf<INPUT>());
    free(input);
  }

  /// 获取虚拟键码
  int _getVirtualKeyCode(String key) {
    final keyUpper = key.toUpperCase();

    // 字母键
    if (keyUpper.length == 1 && keyUpper.codeUnitAt(0) >= 65 && keyUpper.codeUnitAt(0) <= 90) {
      return keyUpper.codeUnitAt(0);
    }

    // 数字键
    if (keyUpper.length == 1 && keyUpper.codeUnitAt(0) >= 48 && keyUpper.codeUnitAt(0) <= 57) {
      return keyUpper.codeUnitAt(0);
    }

    // 特殊键映射
    const keyMap = {
      'SPACE': 0x20,
      'ENTER': 0x0D,
      'RETURN': 0x0D,
      'ESC': 0x1B,
      'ESCAPE': 0x1B,
      'TAB': 0x09,
      'BACKSPACE': 0x08,
      'DELETE': 0x2E,
      'INSERT': 0x2D,
      'HOME': 0x24,
      'END': 0x23,
      'PAGEUP': 0x21,
      'PAGEDOWN': 0x22,
      'ARROWUP': 0x26,
      'ARROWDOWN': 0x28,
      'ARROWLEFT': 0x25,
      'ARROWRIGHT': 0x27,
      'CONTROL': 0x11,
      'SHIFT': 0x10,
      'ALT': 0x12,
      'CAPSLOCK': 0x14,
      'F1': 0x70,
      'F2': 0x71,
      'F3': 0x72,
      'F4': 0x73,
      'F5': 0x74,
      'F6': 0x75,
      'F7': 0x76,
      'F8': 0x77,
      'F9': 0x78,
      'F10': 0x79,
      'F11': 0x7A,
      'F12': 0x7B,
    };

    return keyMap[keyUpper] ?? 0x41; // 默认返回'A'
  }
}
