import 'package:json_annotation/json_annotation.dart';

part 'control_event.g.dart';

/// 控制事件类型
enum EventType {
  @JsonValue('event')
  event,
  @JsonValue('command')
  command,
}

/// 事件子类型
enum EventSubtype {
  @JsonValue('mouse_move')
  mouseMove,
  @JsonValue('mouse_click')
  mouseClick,
  @JsonValue('mouse_scroll')
  mouseScroll,
  @JsonValue('keyboard')
  keyboard,
  @JsonValue('touch')
  touch,
  @JsonValue('gyro')
  gyro,
  @JsonValue('command')
  command,
}

/// 鼠标按钮
enum MouseButton {
  @JsonValue('left')
  left,
  @JsonValue('right')
  right,
  @JsonValue('middle')
  middle,
}

/// 按键状态
enum KeyState {
  @JsonValue('down')
  down,
  @JsonValue('up')
  up,
  @JsonValue('press')
  press,
}

/// 控制事件基类
@JsonSerializable()
class ControlEvent {
  final EventType type;
  final EventSubtype subtype;
  final int timestamp;
  final Map<String, dynamic> data;

  ControlEvent({
    required this.type,
    required this.subtype,
    required this.timestamp,
    required this.data,
  });

  factory ControlEvent.fromJson(Map<String, dynamic> json) =>
      _$ControlEventFromJson(json);

  Map<String, dynamic> toJson() => _$ControlEventToJson(this);

  /// 创建鼠标移动事件
  factory ControlEvent.mouseMove({
    required double dx,
    required double dy,
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.mouseMove,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'dx': dx,
        'dy': dy,
      },
    );
  }

  /// 创建鼠标点击事件
  factory ControlEvent.mouseClick({
    required MouseButton button,
    required KeyState state,
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.mouseClick,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'button': button.name,
        'state': state.name,
      },
    );
  }

  /// 创建鼠标滚轮事件
  factory ControlEvent.mouseScroll({
    required double dx,
    required double dy,
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.mouseScroll,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'dx': dx,
        'dy': dy,
      },
    );
  }

  /// 创建键盘事件
  factory ControlEvent.keyboard({
    required String key,
    required KeyState state,
    bool? ctrl,
    bool? shift,
    bool? alt,
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.keyboard,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'key': key,
        'state': state.name,
        if (ctrl != null) 'ctrl': ctrl,
        if (shift != null) 'shift': shift,
        if (alt != null) 'alt': alt,
      },
    );
  }

  /// 创建触摸事件
  factory ControlEvent.touch({
    required double x,
    required double y,
    required String action, // down, move, up
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.touch,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'x': x,
        'y': y,
        'action': action,
      },
    );
  }

  /// 创建陀螺仪事件
  factory ControlEvent.gyro({
    required double pitch,
    required double yaw,
    required double roll,
  }) {
    return ControlEvent(
      type: EventType.event,
      subtype: EventSubtype.gyro,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'pitch': pitch,
        'yaw': yaw,
        'roll': roll,
      },
    );
  }

  /// 创建命令事件
  factory ControlEvent.command({
    required String cmd,
    Map<String, dynamic>? params,
  }) {
    return ControlEvent(
      type: EventType.command,
      subtype: EventSubtype.command,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'cmd': cmd,
        if (params != null) 'params': params,
      },
    );
  }
}

