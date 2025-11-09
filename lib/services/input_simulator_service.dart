import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/control_event.dart';
import 'platform_input_service.dart';
// 条件导入：只在Windows平台导入win32实现
import 'windows_input_service_stub.dart'
    if (dart.library.io) 'windows_input_service.dart';

/// 输入模拟服务（调用原生库）
class InputSimulatorService {
  static final Logger _logger = Logger();
  
  ffi.DynamicLibrary? _nativeLib;
  PlatformInputService? _platformService;
  WindowsInputService? _windowsService;
  bool _isInitialized = false;

  // FFI 函数指针（稍后绑定）
  late final void Function(int dx, int dy) _nativeMouseMove;
  late final void Function(int button) _nativeMouseClick;
  late final void Function(int dx, int dy) _nativeMouseScroll;
  late final void Function(int keyCode) _nativeKeyPress;

  /// 初始化原生库
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('输入模拟服务已初始化');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台使用Platform Channel
        _platformService = PlatformInputService();
        await _platformService!.initialize();
        _logger.i('移动平台输入服务已初始化');
      } else if (Platform.isWindows) {
        // Windows使用win32包直接调用API
        _windowsService = WindowsInputService();
        _logger.i('Windows输入服务已初始化（使用win32包）');
      } else {
        // 其他桌面平台加载动态库
        await _initializeDesktopLibrary();
      }
      
      _isInitialized = true;
      _logger.i('输入模拟服务已初始化: ${Platform.operatingSystem}');
    } catch (e) {
      _logger.e('初始化输入模拟服务失败: $e');
      _logger.w('将使用降级方案');
    }
  }

  /// 初始化桌面平台动态库
  Future<void> _initializeDesktopLibrary() async {
    try {
      if (Platform.isWindows) {
        // 尝试在多个可能的位置加载 DLL
        final candidates = <String>[
          'input_simulator_windows.dll',
          // 项目源代码目录（调试运行时）
          '${Directory.current.path}\\windows\\runner\\input_simulator_windows.dll',
          // Flutter Windows Debug/Release 产物目录
          '${Directory.current.path}\\build\\windows\\runner\\Debug\\input_simulator_windows.dll',
          '${Directory.current.path}\\build\\windows\\runner\\Release\\input_simulator_windows.dll',
        ];
        ffi.DynamicLibrary? loaded;
        for (final path in candidates) {
          try {
            if (File(path).existsSync() || path == 'input_simulator_windows.dll') {
              loaded = ffi.DynamicLibrary.open(path);
              _logger.i('已加载Windows动态库: $path');
              break;
            }
          } catch (_) {
            // 继续尝试下一个路径
          }
        }
        _nativeLib = loaded ?? ffi.DynamicLibrary.open('input_simulator_windows.dll');
      } else if (Platform.isLinux) {
        _nativeLib = ffi.DynamicLibrary.open('libinput_simulator_linux.so');
      } else if (Platform.isMacOS) {
        _nativeLib = ffi.DynamicLibrary.open('libinput_simulator_macos.dylib');
      } else {
        throw UnsupportedError('不支持的桌面平台: ${Platform.operatingSystem}');
      }

      // 绑定原生函数
      _bindNativeFunctions();
      _logger.i('桌面平台动态库已加载');
    } catch (e) {
      _logger.e('加载桌面平台动态库失败: $e');
      _logger.w('动态库不存在，将使用模拟模式');
      // 设置为已初始化但不实际执行操作
    }
  }

  /// 绑定原生函数
  void _bindNativeFunctions() {
    if (_nativeLib == null) return;

    try {
      // 鼠标移动: void mouse_move(int dx, int dy)
      _nativeMouseMove = _nativeLib!
          .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32, ffi.Int32)>>(
              'mouse_move')
          .asFunction();

      // 鼠标点击: void mouse_click(int button)
      _nativeMouseClick = _nativeLib!
          .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>(
              'mouse_click')
          .asFunction();

      // 鼠标滚轮: void mouse_scroll(int dx, int dy)
      _nativeMouseScroll = _nativeLib!
          .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32, ffi.Int32)>>(
              'mouse_scroll')
          .asFunction();

      // 键盘按键: void key_press(int keycode)
      _nativeKeyPress = _nativeLib!
          .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int32)>>(
              'key_press')
          .asFunction();

      _logger.i('原生函数绑定成功');
    } catch (e) {
      _logger.e('绑定原生函数失败: $e');
      rethrow;
    }
  }

  /// 处理控制事件
  Future<void> handleEvent(ControlEvent event) async {
    if (!_isInitialized) {
      _logger.w('输入模拟服务未初始化');
      return;
    }

    try {
      if (_platformService != null) {
        // 使用平台特定服务（Android/iOS）
        await _platformService!.handleEvent(event);
      } else if (_windowsService != null) {
        // 使用Windows服务
        await _windowsService!.handleEvent(event);
      } else {
        // 使用原生库（其他桌面平台）
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
          case EventSubtype.touch:
            _handleTouch(event);
            break;
          case EventSubtype.text:
            await _handleText(event);
            break;
          default:
            _logger.w('未处理的事件类型: ${event.subtype.name}');
        }
      }
    } catch (e) {
      _logger.e('处理控制事件失败: $e');
    }
  }

  /// 处理鼠标移动
  void _handleMouseMove(ControlEvent event) {
    final dx = (event.data['dx'] as num).toInt();
    final dy = (event.data['dy'] as num).toInt();

    if (_nativeLib != null) {
      _nativeMouseMove(dx, dy);
      _logger.d('鼠标移动: dx=$dx, dy=$dy');
    } else {
      _logger.d('鼠标移动模拟: dx=$dx, dy=$dy');
    }
  }

  /// 处理鼠标点击
  void _handleMouseClick(ControlEvent event) {
    final buttonName = event.data['button'] as String;
    int button = 0; // 0=left, 1=right, 2=middle

    switch (buttonName) {
      case 'left':
        button = 0;
        break;
      case 'right':
        button = 1;
        break;
      case 'middle':
        button = 2;
        break;
    }

    if (_nativeLib != null) {
      _nativeMouseClick(button);
      _logger.d('鼠标点击: button=$buttonName');
    } else {
      _logger.d('鼠标点击模拟: button=$buttonName');
    }
  }

  /// 处理鼠标滚轮
  void _handleMouseScroll(ControlEvent event) {
    final dx = (event.data['dx'] as num).toInt();
    final dy = (event.data['dy'] as num).toInt();

    if (_nativeLib != null) {
      _nativeMouseScroll(dx, dy);
      _logger.d('鼠标滚轮: dx=$dx, dy=$dy');
    } else {
      _logger.d('鼠标滚轮模拟: dx=$dx, dy=$dy');
    }
  }

  /// 处理键盘输入
  void _handleKeyboard(ControlEvent event) {
    final key = event.data['key'] as String;
    final keyCode = _convertKeyToCode(key);

    if (_nativeLib != null) {
      _nativeKeyPress(keyCode);
      _logger.d('键盘输入: key=$key');
    } else {
      _logger.d('键盘输入模拟: key=$key');
    }
  }

  /// 处理触摸事件
  void _handleTouch(ControlEvent event) {
    final x = (event.data['x'] as num).toInt();
    final y = (event.data['y'] as num).toInt();
    final action = event.data['action'] as String;
    
    // 在桌面平台上，触摸转换为鼠标操作
    _logger.d('触摸事件（转为鼠标操作）: x=$x, y=$y, action=$action');
    
    // TODO: 实现绝对位置的鼠标移动
    // 这需要原生库支持绝对坐标的鼠标移动
  }

  /// 处理文本输入（使用剪贴板粘贴）
  /// 注意：这个方法只用于非Windows和非移动平台
  /// Windows平台由WindowsInputService处理，移动平台由PlatformInputService处理
  Future<void> _handleText(ControlEvent event) async {
    final text = event.data['text'] as String;
    
    try {
      // 将文本复制到剪贴板
      await Clipboard.setData(ClipboardData(text: text));
      
      // 等待一小段时间确保剪贴板已更新
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 发送 Ctrl+V 粘贴
      // 对于Linux/macOS等平台，需要发送 Ctrl+V 组合键
      // 这里使用键盘事件模拟 Ctrl+V
      _logger.d('文本粘贴: length=${text.length} (需要平台特定实现)');
      // TODO: 实现Linux/macOS平台的Ctrl+V发送
    } catch (e) {
      _logger.e('文本粘贴失败: $e');
    }
  }

  /// 将键名转换为键码（简化版）
  int _convertKeyToCode(String key) {
    // 这是简化的映射，实际需要完整的键盘映射表
    const keyMap = {
      'A': 0x41, 'B': 0x42, 'C': 0x43, 'D': 0x44, 'E': 0x45,
      'F': 0x46, 'G': 0x47, 'H': 0x48, 'I': 0x49, 'J': 0x4A,
      'K': 0x4B, 'L': 0x4C, 'M': 0x4D, 'N': 0x4E, 'O': 0x4F,
      'P': 0x50, 'Q': 0x51, 'R': 0x52, 'S': 0x53, 'T': 0x54,
      'U': 0x55, 'V': 0x56, 'W': 0x57, 'X': 0x58, 'Y': 0x59,
      'Z': 0x5A,
      '0': 0x30, '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34,
      '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
      'SPACE': 0x20,
      'ENTER': 0x0D,
      'ESC': 0x1B,
    };

    return keyMap[key.toUpperCase()] ?? 0x41; // 默认返回'A'
  }

  /// 释放资源
  void dispose() {
    _platformService?.dispose();
    _platformService = null;
    _nativeLib = null;
    _isInitialized = false;
  }
}
