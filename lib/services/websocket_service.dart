import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:logger/logger.dart';
import '../models/control_event.dart';
import '../models/connection_state.dart' as remote;
import '../core/protocol.dart';

/// WebSocket 通信服务
class WebSocketService {
  static final Logger _logger = Logger();
  static const int defaultPort = 9877;
  
  WebSocketChannel? _channel;
  HttpServer? _server;
  WebSocket? _clientSocket;
  
  final StreamController<ControlEvent> _eventController =
      StreamController<ControlEvent>.broadcast();
  final StreamController<remote.RemoteConnectionState> _stateController =
      StreamController<remote.RemoteConnectionState>.broadcast();
  
  Timer? _heartbeatTimer;
  remote.RemoteConnectionState _currentState = remote.RemoteConnectionState.disconnected();

  /// 接收到的事件流
  Stream<ControlEvent> get eventStream => _eventController.stream;

  /// 连接状态流
  Stream<remote.RemoteConnectionState> get stateStream => _stateController.stream;

  /// 当前连接状态
  remote.RemoteConnectionState get currentState => _currentState;

  /// 作为服务器启动（被控端）
  Future<void> startServer({int port = defaultPort}) async {
    try {
      _updateState(remote.RemoteConnectionState.connecting());
      
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _logger.i('WebSocket服务器已启动，端口: $port');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          _clientSocket = await WebSocketTransformer.upgrade(request);
          _logger.i('客户端已连接');
          
          _updateState(remote.RemoteConnectionState.connected('client'));
          _setupHeartbeat();
          
          _clientSocket!.listen(
            _handleMessage,
            onError: (error) {
              _logger.e('WebSocket错误: $error');
              _updateState(remote.RemoteConnectionState.error(error.toString()));
            },
            onDone: () {
              _logger.i('客户端已断开');
              _updateState(remote.RemoteConnectionState.disconnected());
              _cleanup();
            },
          );
        }
      });
    } catch (e) {
      _logger.e('启动WebSocket服务器失败: $e');
      _updateState(remote.RemoteConnectionState.error(e.toString()));
      rethrow;
    }
  }

  /// 作为客户端连接（控制端）
  Future<void> connectToServer(String host, {int port = defaultPort}) async {
    try {
      _updateState(remote.RemoteConnectionState.connecting());
      
      final uri = Uri.parse('ws://$host:$port');
      _channel = IOWebSocketChannel.connect(uri);
      
      _logger.i('正在连接到 $uri');

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.e('WebSocket错误: $error');
          _updateState(remote.RemoteConnectionState.error(error.toString()));
        },
        onDone: () {
          _logger.i('已断开连接');
          _updateState(remote.RemoteConnectionState.disconnected());
          _cleanup();
        },
      );

      _updateState(remote.RemoteConnectionState.connected(host));
      _setupHeartbeat();
      
      _logger.i('已连接到服务器');
    } catch (e) {
      _logger.e('连接服务器失败: $e');
      _updateState(remote.RemoteConnectionState.error(e.toString()));
      rethrow;
    }
  }

  /// 发送控制事件
  void sendEvent(ControlEvent event) {
    if (!_currentState.isConnected) {
      _logger.w('未连接，无法发送事件');
      return;
    }

    try {
      final message = Protocol.encodeEvent(event);
      
      if (_channel != null) {
        _channel!.sink.add(message);
      } else if (_clientSocket != null) {
        _clientSocket!.add(message);
      }
      
      _logger.d('发送事件: ${event.subtype.name}');
    } catch (e) {
      _logger.e('发送事件失败: $e');
    }
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic data) {
    try {
      final message = data.toString();

      // 检查是否为心跳消息
      if (Protocol.isHeartbeat(message)) {
        _logger.d('收到心跳');
        return;
      }

      // 解析控制事件
      final event = Protocol.decodeEvent(message);
      _eventController.add(event);
      
      _logger.d('收到事件: ${event.subtype.name}');
    } catch (e) {
      _logger.w('处理消息失败: $e');
    }
  }

  /// 设置心跳
  void _setupHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendHeartbeat(),
    );
  }

  /// 发送心跳
  void _sendHeartbeat() {
    if (!_currentState.isConnected) return;

    try {
      final heartbeat = Protocol.createHeartbeat();
      
      if (_channel != null) {
        _channel!.sink.add(heartbeat);
      } else if (_clientSocket != null) {
        _clientSocket!.add(heartbeat);
      }
      
      _logger.d('发送心跳');
    } catch (e) {
      _logger.w('发送心跳失败: $e');
    }
  }

  /// 更新连接状态
  void _updateState(remote.RemoteConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// 清理资源
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 断开连接
  Future<void> disconnect() async {
    _logger.i('正在断开连接');
    
    _cleanup();
    
    await _channel?.sink.close();
    await _clientSocket?.close();
    await _server?.close();
    
    _channel = null;
    _clientSocket = null;
    _server = null;
    
    _updateState(remote.RemoteConnectionState.disconnected());
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}

