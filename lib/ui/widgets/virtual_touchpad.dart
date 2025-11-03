import 'package:flutter/material.dart';

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
                
                widget.onMove(dx, dy);
                _lastPosition = details.localPosition;
              }
            },
            onPanEnd: (details) {
              _lastPosition = null;
            },
            onTap: widget.onTap,
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
          child: Row(
            children: [
              Expanded(
                child: _buildButton(
                  context,
                  icon: Icons.mouse,
                  label: '左键',
                  onTap: widget.onTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  context,
                  icon: Icons.radio_button_unchecked,
                  label: '右键',
                  onTap: () {
                    // TODO: 实现右键点击
                  },
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
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

