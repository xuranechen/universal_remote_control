import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/input_capture_service.dart';
import '../../models/control_event.dart';
import '../../utils/animations.dart';

/// 虚拟键盘组件
class VirtualKeyboard extends StatefulWidget {
  const VirtualKeyboard({super.key});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _showSpecialKeys = false;
  bool _shiftPressed = false;
  bool _ctrlPressed = false;
  bool _altPressed = false;
  
  /// 基础键盘布局 - 字母数字行
  final List<List<String>> _qwertyRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  /// 特殊功能键
  final List<KeyboardKey> _specialKeys = [
    KeyboardKey(label: 'Tab', code: 'Tab', width: 1.5),
    KeyboardKey(label: 'Enter', code: 'Enter', width: 2.0),
    KeyboardKey(label: 'Space', code: 'Space', width: 4.0),
    KeyboardKey(label: 'Backspace', code: 'Backspace', width: 1.5),
    KeyboardKey(label: 'Delete', code: 'Delete', width: 1.5),
    KeyboardKey(label: 'Escape', code: 'Escape', width: 1.5),
    KeyboardKey(label: '↑', code: 'ArrowUp', width: 1.0),
    KeyboardKey(label: '↓', code: 'ArrowDown', width: 1.0),
    KeyboardKey(label: '←', code: 'ArrowLeft', width: 1.0),
    KeyboardKey(label: '→', code: 'ArrowRight', width: 1.0),
  ];

  /// 快捷键组合
  final List<ShortcutKey> _shortcuts = [
    ShortcutKey(label: 'Ctrl+C', description: '复制', keys: ['Control', 'c']),
    ShortcutKey(label: 'Ctrl+V', description: '粘贴', keys: ['Control', 'v']),
    ShortcutKey(label: 'Ctrl+A', description: '全选', keys: ['Control', 'a']),
    ShortcutKey(label: 'Ctrl+Z', description: '撤销', keys: ['Control', 'z']),
    ShortcutKey(label: 'Ctrl+Y', description: '重做', keys: ['Control', 'y']),
    ShortcutKey(label: 'Alt+Tab', description: '切换窗口', keys: ['Alt', 'Tab']),
    ShortcutKey(label: 'Ctrl+S', description: '保存', keys: ['Control', 's']),
    ShortcutKey(label: 'Ctrl+F', description: '查找', keys: ['Control', 'f']),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 键盘工具栏
          _buildKeyboardToolbar(),
          
          const SizedBox(height: 8),
          
          // 键盘主体
          if (!_showSpecialKeys) ...[
            _buildQwertyKeyboard(),
          ] else ...[
            _buildSpecialKeyboard(),
          ],
          
          const SizedBox(height: 8),
          
          // 快捷键区域
          _buildShortcutsSection(),
        ],
      ),
    );
  }

  /// 构建键盘工具栏
  Widget _buildKeyboardToolbar() {
    return Row(
      children: [
        // 切换键盘类型
        AppAnimations.buildTapAnimation(
          onTap: () {
            setState(() {
              _showSpecialKeys = !_showSpecialKeys;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showSpecialKeys 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _showSpecialKeys ? '字母' : '功能',
              style: TextStyle(
                color: _showSpecialKeys 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // 修饰键状态
        _buildModifierKey('Shift', _shiftPressed, (pressed) {
          setState(() {
            _shiftPressed = pressed;
          });
        }),
        
        const SizedBox(width: 4),
        
        _buildModifierKey('Ctrl', _ctrlPressed, (pressed) {
          setState(() {
            _ctrlPressed = pressed;
          });
        }),
        
        const SizedBox(width: 4),
        
        _buildModifierKey('Alt', _altPressed, (pressed) {
          setState(() {
            _altPressed = pressed;
          });
        }),
        
        const Spacer(),
        
        // 关闭按钮
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_hide),
          tooltip: '隐藏键盘',
        ),
      ],
    );
  }

  /// 构建修饰键
  Widget _buildModifierKey(String label, bool pressed, Function(bool) onToggle) {
    return AppAnimations.buildTapAnimation(
      onTap: () => onToggle(!pressed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: pressed 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: pressed 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: pressed 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建QWERTY键盘
  Widget _buildQwertyKeyboard() {
    return Column(
      children: [
        // 数字行
        _buildKeyRow(_qwertyRows[0], isNumberRow: true),
        const SizedBox(height: 4),
        
        // 字母行
        for (int i = 1; i < _qwertyRows.length; i++) ...[
          _buildKeyRow(_qwertyRows[i]),
          const SizedBox(height: 4),
        ],
        
        // 底部功能行
        _buildBottomRow(),
      ],
    );
  }

  /// 构建键盘行
  Widget _buildKeyRow(List<String> keys, {bool isNumberRow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Expanded(
          child: _buildKey(
            label: _shiftPressed ? _getShiftChar(key) : key,
            code: key,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
        );
      }).toList(),
    );
  }

  /// 构建底部功能行
  Widget _buildBottomRow() {
    return Row(
      children: [
        // 空格键
        Expanded(
          flex: 6,
          child: _buildKey(
            label: 'Space',
            code: 'Space',
            height: 40,
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 退格键
        Expanded(
          flex: 2,
          child: _buildKey(
            label: '⌫',
            code: 'Backspace',
            height: 40,
          ),
        ),
        
        const SizedBox(width: 4),
        
        // 回车键
        Expanded(
          flex: 2,
          child: _buildKey(
            label: '↵',
            code: 'Enter',
            height: 40,
          ),
        ),
      ],
    );
  }

  /// 构建特殊键盘
  Widget _buildSpecialKeyboard() {
    return Column(
      children: [
        // 方向键
        _buildArrowKeys(),
        const SizedBox(height: 8),
        
        // 功能键网格
        _buildFunctionKeysGrid(),
      ],
    );
  }

  /// 构建方向键
  Widget _buildArrowKeys() {
    return Column(
      children: [
        // 上箭头
        _buildKey(label: '↑', code: 'ArrowUp', width: 50, height: 40),
        const SizedBox(height: 4),
        
        // 左右箭头
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey(label: '←', code: 'ArrowLeft', width: 50, height: 40),
            const SizedBox(width: 8),
            _buildKey(label: '→', code: 'ArrowRight', width: 50, height: 40),
          ],
        ),
        const SizedBox(height: 4),
        
        // 下箭头
        _buildKey(label: '↓', code: 'ArrowDown', width: 50, height: 40),
      ],
    );
  }

  /// 构建功能键网格
  Widget _buildFunctionKeysGrid() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildKey(label: 'Tab', code: 'Tab', width: 60),
        _buildKey(label: 'Esc', code: 'Escape', width: 60),
        _buildKey(label: 'Del', code: 'Delete', width: 60),
        _buildKey(label: 'Home', code: 'Home', width: 60),
        _buildKey(label: 'End', code: 'End', width: 60),
        _buildKey(label: 'PgUp', code: 'PageUp', width: 60),
        _buildKey(label: 'PgDn', code: 'PageDown', width: 60),
        _buildKey(label: 'Insert', code: 'Insert', width: 60),
      ],
    );
  }

  /// 构建快捷键区域
  Widget _buildShortcutsSection() {
    return ExpansionTile(
      title: Text(
        '常用快捷键',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: false,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shortcuts.map((shortcut) {
            return AppAnimations.buildTapAnimation(
              onTap: () => _sendShortcut(shortcut.keys),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shortcut.label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      shortcut.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建按键
  Widget _buildKey({
    required String label,
    required String code,
    double? width,
    double? height,
    EdgeInsets? margin,
  }) {
    return AppAnimations.buildTapAnimation(
      onTap: () => _sendKey(code),
      child: Container(
        width: width,
        height: height ?? 36,
        margin: margin ?? const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 发送按键事件
  void _sendKey(String key) {
    final inputCapture = context.read<InputCaptureService>();
    
    // 处理修饰键组合
    List<String> modifiers = [];
    if (_ctrlPressed) modifiers.add('Control');
    if (_shiftPressed) modifiers.add('Shift');
    if (_altPressed) modifiers.add('Alt');
    
    inputCapture.sendKeyPress(key, modifiers: modifiers);
    
    // 重置Shift状态（除非是粘性按键）
    if (_shiftPressed && key.length == 1) {
      setState(() {
        _shiftPressed = false;
      });
    }
  }

  /// 发送快捷键组合
  void _sendShortcut(List<String> keys) {
    final inputCapture = context.read<InputCaptureService>();
    
    if (keys.length >= 2) {
      List<String> modifiers = keys.sublist(0, keys.length - 1);
      String key = keys.last;
      inputCapture.sendKeyPress(key, modifiers: modifiers);
    }
  }

  /// 获取Shift字符
  String _getShiftChar(String char) {
    const shiftMap = {
      '1': '!', '2': '@', '3': '#', '4': '\$', '5': '%',
      '6': '^', '7': '&', '8': '*', '9': '(', '0': ')',
      '-': '_', '=': '+', '[': '{', ']': '}', '\\': '|',
      ';': ':', '\'': '"', ',': '<', '.': '>', '/': '?',
      '`': '~',
    };
    
    if (shiftMap.containsKey(char)) {
      return shiftMap[char]!;
    } else if (char.length == 1 && char.toLowerCase() != char.toUpperCase()) {
      return char.toUpperCase();
    }
    
    return char;
  }
}

/// 键盘按键数据类
class KeyboardKey {
  final String label;
  final String code;
  final double width;

  KeyboardKey({
    required this.label,
    required this.code,
    this.width = 1.0,
  });
}

/// 快捷键数据类
class ShortcutKey {
  final String label;
  final String description;
  final List<String> keys;

  ShortcutKey({
    required this.label,
    required this.description,
    required this.keys,
  });
}

/// 显示虚拟键盘的函数
void showVirtualKeyboard(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) => const VirtualKeyboard(),
    ),
  );
}
