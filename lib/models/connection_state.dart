/// 连接状态
enum RemoteConnectionStatus {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接
  error, // 错误
}

/// 连接状态信息
class RemoteConnectionState {
  final RemoteConnectionStatus status;
  final String? message;
  final DateTime? connectedAt;
  final String? connectedDeviceId;

  RemoteConnectionState({
    required this.status,
    this.message,
    this.connectedAt,
    this.connectedDeviceId,
  });

  factory RemoteConnectionState.disconnected() {
    return RemoteConnectionState(
      status: RemoteConnectionStatus.disconnected,
    );
  }

  factory RemoteConnectionState.connecting() {
    return RemoteConnectionState(
      status: RemoteConnectionStatus.connecting,
      message: '正在连接...',
    );
  }

  factory RemoteConnectionState.connected(String deviceId) {
    return RemoteConnectionState(
      status: RemoteConnectionStatus.connected,
      message: '已连接',
      connectedAt: DateTime.now(),
      connectedDeviceId: deviceId,
    );
  }

  factory RemoteConnectionState.error(String errorMessage) {
    return RemoteConnectionState(
      status: RemoteConnectionStatus.error,
      message: errorMessage,
    );
  }

  bool get isConnected => status == RemoteConnectionStatus.connected;
  bool get isConnecting => status == RemoteConnectionStatus.connecting;
  bool get isDisconnected => status == RemoteConnectionStatus.disconnected;
  bool get hasError => status == RemoteConnectionStatus.error;

  RemoteConnectionState copyWith({
    RemoteConnectionStatus? status,
    String? message,
    DateTime? connectedAt,
    String? connectedDeviceId,
  }) {
    return RemoteConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
      connectedAt: connectedAt ?? this.connectedAt,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
    );
  }

  @override
  String toString() {
    return 'RemoteConnectionState(status: ${status.name}, message: $message)';
  }
}

