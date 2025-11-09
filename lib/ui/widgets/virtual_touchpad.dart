import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/input_capture_service.dart';
import '../../models/control_event.dart';

/// 虚拟触摸板组件
class VirtualTouchpad extends StatefulWidget {
  final Function(double dx, double dy) onMove;
  final VoidCallback onTap;
  final Function(double dx, double dy)? onScroll;

  const VirtualTouchpad({
    super.key,
    required this.onMove,
    required this.onTap,
    this.onScroll,
  });

  @override
  State<VirtualTouchpad> createState() => _VirtualTouchpadState();
}

class _VirtualTouchpadState extends State<VirtualTouchpad> {
  Offset? _lastPosition;
  double _sensitivity = 1.0;
  bool _isScrollMode = false;
  bool _isTwoFingerMode = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  DateTime? _lastClickTime;
  static const _clickDebounceMs = 300;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 触摸板区域
        Expanded(
          child: GestureDetector(
            onPanStart: (details) {
              _lastPosition = details.localPosition;
            },
            onPanUpdate: (details) {
              if (_lastPosition != null) {
                final dx = (details.localPosition.dx - _lastPosition!.dx) * _sensitivity;
                final dy = (details.localPosition.dy - _lastPosition!.dy) * _sensitivity;
                
                if (_isScrollMode) {
                  // 滚轮模式
                  _sendScrollEvent(dx, dy);
                } else {
                  // 鼠标移动模式
                  widget.onMove(dx, dy);
                }
                _lastPosition = details.localPosition;
              }
            },
            onPanEnd: (details) {
              _lastPosition = null;
            },
            onTap: () => _handleTap(MouseButton.left),
            onSecondaryTap: () => _handleTap(MouseButton.right),
            onLongPress: () => _handleTap(MouseButton.right),
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '触摸板',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '滑动移动 • 点击执行点击',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 灵敏度调节
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.speed, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '灵敏度',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: _sensitivity,
                      min: 0.5,
                      max: 3.0,
                      divisions: 10,
                      label: _sensitivity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _sensitivity = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 按钮区域
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      context,
                      icon: Icons.mouse,
                      label: '左键',
                      onTap: () => _handleTap(MouseButton.left),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      context,
                      icon: Icons.radio_button_unchecked,
                      label: '右键',
                      onTap: () => _handleTap(MouseButton.right),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      context,
                      icon: Icons.mouse,
                      label: '滚轮',
                      onTap: _toggleScrollMode,
                      isActive: _isScrollMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showTextInput,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('文本输入'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: isActive 
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: isActive 
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  // 处理点击事件
  void _handleTap(MouseButton button) {
    final now = DateTime.now();
    if (_lastClickTime != null && 
        now.difference(_lastClickTime!).inMilliseconds < _clickDebounceMs) {
      return;
    }
    _lastClickTime = now;
    
    final inputCapture = context.read<InputCaptureService>();
    inputCapture.sendMouseClick(button: button, state: KeyState.press);
  }
  
  // 切换滚轮模式
  void _toggleScrollMode() {
    setState(() {
      _isScrollMode = !_isScrollMode;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isScrollMode ? '滚轮模式已启用' : '滚轮模式已关闭'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  // 发送滚轮事件
  void _sendScrollEvent(double dx, double dy) {
    if (widget.onScroll != null) {
      widget.onScroll!(dx, dy);
    } else {
      final inputCapture = context.read<InputCaptureService>();
      inputCapture.sendMouseScroll(dx, dy);
    }
  }
  
  // 显示文本输入对话框
  void _showTextInput() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文本输入'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '输入要发送的文本',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text;
              if (text.isNotEmpty) {
                _sendText(text);
                Navigator.pop(context);
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
  
  // 发送文本
  void _sendText(String text) {
    final inputCapture = context.read<InputCaptureService>();
    for (int i = 0; i < text.length; i++) {
      inputCapture.sendKeyPress(text[i]);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已发送文本: ${text.length} 个字符'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
