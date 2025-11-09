import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/input_capture_service.dart';

/// 陀螺仪控制器组件
class GyroController extends StatefulWidget {
  final bool enabled;
  final VoidCallback onToggle;

  const GyroController({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  @override
  State<GyroController> createState() => _GyroControllerState();
}

class _GyroControllerState extends State<GyroController>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  double _pitchSensitivity = 30.0;
  double _yawSensitivity = 30.0;
  double _deadZone = 0.05;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enabled) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(GyroController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _updateSensitivity() {
    final inputCapture = context.read<InputCaptureService>();
    inputCapture.setGyroSensitivity(
      pitch: _pitchSensitivity,
      yaw: _yawSensitivity,
      deadZone: _deadZone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 陀螺仪状态显示
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.enabled 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.enabled ? _scaleAnimation.value : 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.enabled 
                              ? Icons.screen_rotation_outlined
                              : Icons.screen_lock_rotation_outlined,
                          size: 80,
                          color: widget.enabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.enabled ? '陀螺仪已启用' : '陀螺仪已禁用',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: widget.enabled
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.enabled 
                              ? '移动设备以控制鼠标指针'
                              : '点击按钮启用陀螺仪控制',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // 陀螺仪设置
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 灵敏度设置
                _buildSensitivitySlider(
                  '俯仰灵敏度',
                  _pitchSensitivity,
                  Icons.height,
                  (value) {
                    setState(() {
                      _pitchSensitivity = value;
                    });
                    _updateSensitivity();
                  },
                ),
                const SizedBox(height: 8),
                _buildSensitivitySlider(
                  '偏航灵敏度',
                  _yawSensitivity,
                  Icons.swap_horiz,
                  (value) {
                    setState(() {
                      _yawSensitivity = value;
                    });
                    _updateSensitivity();
                  },
                ),
                const SizedBox(height: 8),
                _buildSensitivitySlider(
                  '死区',
                  _deadZone,
                  Icons.center_focus_weak,
                  (value) {
                    setState(() {
                      _deadZone = value;
                    });
                    _updateSensitivity();
                  },
                  min: 0.05,
                  max: 0.5,
                ),
              ],
            ),
          ),
        ),
        
        // 控制按钮
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onToggle,
                  icon: Icon(
                    widget.enabled 
                        ? Icons.stop 
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    widget.enabled ? '停止陀螺仪' : '启用陀螺仪',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: widget.enabled
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: widget.enabled
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _resetToDefaults,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSensitivitySlider(
    String label,
    double value,
    IconData icon,
    ValueChanged<double> onChanged, {
    double min = 1.0,
    double max = 20.0,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    value.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) * 10).round(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _resetToDefaults() {
    setState(() {
      _pitchSensitivity = 30.0;
      _yawSensitivity = 30.0;
      _deadZone = 0.05;
    });
    _updateSensitivity();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已重置为默认设置'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
