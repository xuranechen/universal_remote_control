/// 连接状态
enum ConnectionStatus {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接
  error, // 错误
}

/// 连接状态信息
class ConnectionState {
  final ConnectionStatus status;
  final String? message;
  final DateTime? connectedAt;
  final String? connectedDeviceId;

  ConnectionState({
    required this.status,
    this.message,
    this.connectedAt,
    this.connectedDeviceId,
  });

  factory ConnectionState.disconnected() {
    return ConnectionState(
      status: ConnectionStatus.disconnected,
    );
  }

  factory ConnectionState.connecting() {
    return ConnectionState(
      status: ConnectionStatus.connecting,
      message: '正在连接...',
    );
  }

  factory ConnectionState.connected(String deviceId) {
    return ConnectionState(
      status: ConnectionStatus.connected,
      message: '已连接',
      connectedAt: DateTime.now(),
      connectedDeviceId: deviceId,
    );
  }

  factory ConnectionState.error(String errorMessage) {
    return ConnectionState(
      status: ConnectionStatus.error,
      message: errorMessage,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get hasError => status == ConnectionStatus.error;

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? message,
    DateTime? connectedAt,
    String? connectedDeviceId,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
      connectedAt: connectedAt ?? this.connectedAt,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
    );
  }

  @override
  String toString() {
    return 'ConnectionState(status: ${status.name}, message: $message)';
  }
}

