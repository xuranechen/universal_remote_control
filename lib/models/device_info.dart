import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

/// 设备类型
enum DeviceType {
  @JsonValue('android')
  android,
  @JsonValue('ios')
  ios,
  @JsonValue('windows')
  windows,
  @JsonValue('macos')
  macos,
  @JsonValue('linux')
  linux,
  @JsonValue('unknown')
  unknown,
}

/// 设备模式
enum DeviceMode {
  @JsonValue('controller')
  controller, // 控制端
  @JsonValue('controlled')
  controlled, // 被控端
  @JsonValue('idle')
  idle, // 空闲
}

/// 设备信息
@JsonSerializable()
class DeviceInfo {
  final String id; // 唯一标识
  final String name; // 设备名称
  final DeviceType type; // 设备类型
  final DeviceMode mode; // 当前模式
  final String ip; // IP地址
  final int port; // 端口号
  final String? description; // 描述
  final int timestamp; // 时间戳

  DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.mode,
    required this.ip,
    required this.port,
    this.description,
    required this.timestamp,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  /// 创建副本
  DeviceInfo copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceMode? mode,
    String? ip,
    int? port,
    String? description,
    int? timestamp,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(name: $name, type: ${type.name}, mode: ${mode.name}, ip: $ip:$port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 设备能力
@JsonSerializable()
class DeviceCapabilities {
  final bool supportGyro; // 支持陀螺仪
  final bool supportTouch; // 支持触摸
  final bool supportKeyboard; // 支持键盘
  final bool supportMouse; // 支持鼠标
  final bool canSimulateInput; // 能模拟输入
  final bool canCaptureScreen; // 能捕获屏幕

  DeviceCapabilities({
    required this.supportGyro,
    required this.supportTouch,
    required this.supportKeyboard,
    required this.supportMouse,
    required this.canSimulateInput,
    required this.canCaptureScreen,
  });

  factory DeviceCapabilities.fromJson(Map<String, dynamic> json) =>
      _$DeviceCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceCapabilitiesToJson(this);
}

