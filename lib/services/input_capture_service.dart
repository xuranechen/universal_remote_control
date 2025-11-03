import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:logger/logger.dart';
import '../models/control_event.dart';

/// 输入捕获服务
class InputCaptureService {
  static final Logger _logger = Logger();
  
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  
  final StreamController<ControlEvent> _eventController =
      StreamController<ControlEvent>.broadcast();

  /// 捕获的事件流
  Stream<ControlEvent> get eventStream => _eventController.stream;

  bool _isCapturing = false;
  bool _gyroEnabled = false;

  // 陀螺仪灵敏度配置
  double gyroPitchSensitivity = 10.0;
  double gyroYawSensitivity = 10.0;
  double gyroDeadZone = 0.1; // 死区，避免抖动

  /// 开始捕获输入
  void startCapture({bool enableGyro = true}) {
    if (_isCapturing) {
      _logger.w('输入捕获已在运行');
      return;
    }

    _isCapturing = true;
    _gyroEnabled = enableGyro;

    if (enableGyro) {
      _startGyroCapture();
    }

    _logger.i('输入捕获已启动');
  }

  /// 停止捕获输入
  void stopCapture() {
    if (!_isCapturing) return;

    _gyroSubscription?.cancel();
    _accelSubscription?.cancel();
    
    _gyroSubscription = null;
    _accelSubscription = null;
    
    _isCapturing = false;
    _logger.i('输入捕获已停止');
  }

  /// 开始陀螺仪捕获
  void _startGyroCapture() {
    _gyroSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        _handleGyroEvent(event);
      },
      onError: (error) {
        _logger.e('陀螺仪错误: $error');
      },
    );

    _logger.i('陀螺仪捕获已启动');
  }

  /// 处理陀螺仪事件
  void _handleGyroEvent(GyroscopeEvent event) {
    // event.x: 绕X轴旋转（pitch，俯仰）
    // event.y: 绕Y轴旋转（yaw，偏航）
    // event.z: 绕Z轴旋转（roll，翻滚）

    double pitch = event.x;
    double yaw = event.y;
    double roll = event.z;

    // 应用死区
    if (pitch.abs() < gyroDeadZone) pitch = 0;
    if (yaw.abs() < gyroDeadZone) yaw = 0;

    // 如果有移动，转换为鼠标移动事件
    if (pitch != 0 || yaw != 0) {
      double dx = yaw * gyroYawSensitivity;
      double dy = pitch * gyroPitchSensitivity;

      final controlEvent = ControlEvent.mouseMove(dx: dx, dy: dy);
      _eventController.add(controlEvent);
    }
  }

  /// 手动发送鼠标移动事件
  void sendMouseMove(double dx, double dy) {
    final event = ControlEvent.mouseMove(dx: dx, dy: dy);
    _eventController.add(event);
  }

  /// 手动发送鼠标点击事件
  void sendMouseClick({
    MouseButton button = MouseButton.left,
    KeyState state = KeyState.press,
  }) {
    final event = ControlEvent.mouseClick(button: button, state: state);
    _eventController.add(event);
  }

  /// 手动发送鼠标滚轮事件
  void sendMouseScroll(double dx, double dy) {
    final event = ControlEvent.mouseScroll(dx: dx, dy: dy);
    _eventController.add(event);
  }

  /// 手动发送键盘事件
  void sendKeyboard({
    required String key,
    KeyState state = KeyState.press,
    bool ctrl = false,
    bool shift = false,
    bool alt = false,
  }) {
    final event = ControlEvent.keyboard(
      key: key,
      state: state,
      ctrl: ctrl,
      shift: shift,
      alt: alt,
    );
    _eventController.add(event);
  }

  /// 手动发送触摸事件
  void sendTouch({
    required double x,
    required double y,
    required String action,
  }) {
    final event = ControlEvent.touch(x: x, y: y, action: action);
    _eventController.add(event);
  }

  /// 设置陀螺仪灵敏度
  void setGyroSensitivity({
    double? pitch,
    double? yaw,
    double? deadZone,
  }) {
    if (pitch != null) gyroPitchSensitivity = pitch;
    if (yaw != null) gyroYawSensitivity = yaw;
    if (deadZone != null) gyroDeadZone = deadZone;
    
    _logger.i('陀螺仪灵敏度已更新: pitch=$gyroPitchSensitivity, yaw=$gyroYawSensitivity');
  }

  /// 释放资源
  void dispose() {
    stopCapture();
    _eventController.close();
  }
}

