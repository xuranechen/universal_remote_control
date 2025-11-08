import 'dart:io';
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
    input.ref.type = INPUT_TYPE.INPUT_MOUSE;
    input.ref.mi.dx = dx;
    input.ref.mi.dy = dy;
    input.ref.mi.dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_MOVE;

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
        downFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTDOWN;
        upFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_LEFTUP;
        break;
      case 'right':
        downFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_RIGHTDOWN;
        upFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_RIGHTUP;
        break;
      case 'middle':
        downFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_MIDDLEDOWN;
        upFlag = MOUSE_EVENT_FLAGS.MOUSEEVENTF_MIDDLEUP;
        break;
      default:
        return;
    }

    final inputs = calloc<INPUT>(2);

    // 按下
    inputs[0].type = INPUT_TYPE.INPUT_MOUSE;
    inputs[0].mi.dwFlags = downFlag;

    // 释放
    inputs[1].type = INPUT_TYPE.INPUT_MOUSE;
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
      input.ref.type = INPUT_TYPE.INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_WHEEL;
      input.ref.mi.mouseData = dy * WHEEL_DELTA;

      SendInput(1, input, sizeOf<INPUT>());
      free(input);
    }

    if (dx != 0) {
      final input = calloc<INPUT>();
      input.ref.type = INPUT_TYPE.INPUT_MOUSE;
      input.ref.mi.dwFlags = MOUSE_EVENT_FLAGS.MOUSEEVENTF_HWHEEL;
      input.ref.mi.mouseData = dx * WHEEL_DELTA;

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
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = keyCode;
    input.ref.ki.dwFlags = down ? 0 : KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;

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
      'SPACE': VIRTUAL_KEY.VK_SPACE,
      'ENTER': VIRTUAL_KEY.VK_RETURN,
      'RETURN': VIRTUAL_KEY.VK_RETURN,
      'ESC': VIRTUAL_KEY.VK_ESCAPE,
      'ESCAPE': VIRTUAL_KEY.VK_ESCAPE,
      'TAB': VIRTUAL_KEY.VK_TAB,
      'BACKSPACE': VIRTUAL_KEY.VK_BACK,
      'DELETE': VIRTUAL_KEY.VK_DELETE,
      'INSERT': VIRTUAL_KEY.VK_INSERT,
      'HOME': VIRTUAL_KEY.VK_HOME,
      'END': VIRTUAL_KEY.VK_END,
      'PAGEUP': VIRTUAL_KEY.VK_PRIOR,
      'PAGEDOWN': VIRTUAL_KEY.VK_NEXT,
      'ARROWUP': VIRTUAL_KEY.VK_UP,
      'ARROWDOWN': VIRTUAL_KEY.VK_DOWN,
      'ARROWLEFT': VIRTUAL_KEY.VK_LEFT,
      'ARROWRIGHT': VIRTUAL_KEY.VK_RIGHT,
      'CONTROL': VIRTUAL_KEY.VK_CONTROL,
      'SHIFT': VIRTUAL_KEY.VK_SHIFT,
      'ALT': VIRTUAL_KEY.VK_MENU,
      'CAPSLOCK': VIRTUAL_KEY.VK_CAPITAL,
      'F1': VIRTUAL_KEY.VK_F1,
      'F2': VIRTUAL_KEY.VK_F2,
      'F3': VIRTUAL_KEY.VK_F3,
      'F4': VIRTUAL_KEY.VK_F4,
      'F5': VIRTUAL_KEY.VK_F5,
      'F6': VIRTUAL_KEY.VK_F6,
      'F7': VIRTUAL_KEY.VK_F7,
      'F8': VIRTUAL_KEY.VK_F8,
      'F9': VIRTUAL_KEY.VK_F9,
      'F10': VIRTUAL_KEY.VK_F10,
      'F11': VIRTUAL_KEY.VK_F11,
      'F12': VIRTUAL_KEY.VK_F12,
    };

    return keyMap[keyUpper] ?? VIRTUAL_KEY.VK_A;
  }
}
