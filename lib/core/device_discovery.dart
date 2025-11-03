import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/device_info.dart';
import 'protocol.dart';

/// 设备发现服务（基于UDP广播）
class DeviceDiscovery {
  static final Logger _logger = Logger();
  static const int discoveryPort = 9876;
  static const String broadcastAddress = '255.255.255.255';
  
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  
  final Map<String, DeviceInfo> _discoveredDevices = {};
  final StreamController<List<DeviceInfo>> _devicesController =
      StreamController<List<DeviceInfo>>.broadcast();
  
  DeviceInfo? _localDevice;
  bool _isRunning = false;

  /// 发现的设备列表流
  Stream<List<DeviceInfo>> get devicesStream => _devicesController.stream;

  /// 当前发现的设备列表
  List<DeviceInfo> get devices => _discoveredDevices.values.toList();

  /// 开始设备发现
  Future<void> start(DeviceInfo localDevice) async {
    if (_isRunning) {
      _logger.w('设备发现已在运行');
      return;
    }

    _localDevice = localDevice;
    _isRunning = true;

    try {
      // 绑定UDP socket
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _socket!.broadcastEnabled = true;

      _logger.i('设备发现服务已启动，端口: $discoveryPort');

      // 监听接收到的广播
      _socket!.listen(_handleIncomingPacket);

      // 定期广播自己的信息
      _broadcastTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _broadcastDeviceInfo(),
      );

      // 定期清理过期设备
      _cleanupTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _cleanupExpiredDevices(),
      );

      // 立即广播一次
      _broadcastDeviceInfo();
    } catch (e) {
      _logger.e('启动设备发现失败: $e');
      _isRunning = false;
      rethrow;
    }
  }

  /// 停止设备发现
  void stop() {
    if (!_isRunning) return;

    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _discoveredDevices.clear();
    _isRunning = false;

    _logger.i('设备发现服务已停止');
  }

  /// 广播本地设备信息
  void _broadcastDeviceInfo() {
    if (_localDevice == null || _socket == null) return;

    try {
      final message = Protocol.encodeDeviceInfo(_localDevice!);
      final data = utf8.encode(message);
      
      _socket!.send(
        data,
        InternetAddress(broadcastAddress),
        discoveryPort,
      );

      _logger.d('广播设备信息: ${_localDevice!.name}');
    } catch (e) {
      _logger.e('广播设备信息失败: $e');
    }
  }

  /// 处理接收到的数据包
  void _handleIncomingPacket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final datagram = _socket!.receive();
    if (datagram == null) return;

    try {
      final message = utf8.decode(datagram.data);
      final deviceInfo = Protocol.decodeDeviceInfo(message);

      // 忽略自己的广播
      if (_localDevice != null && deviceInfo.id == _localDevice!.id) {
        return;
      }

      // 更新或添加设备
      final existingDevice = _discoveredDevices[deviceInfo.id];
      if (existingDevice == null) {
        _logger.i('发现新设备: ${deviceInfo.name} (${deviceInfo.ip})');
      }

      _discoveredDevices[deviceInfo.id] = deviceInfo.copyWith(
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // 通知监听者
      _devicesController.add(devices);
    } catch (e) {
      _logger.w('处理接收数据包失败: $e');
    }
  }

  /// 清理过期设备（超过30秒没有更新）
  void _cleanupExpiredDevices() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expireTime = 30000; // 30秒

    final expiredIds = _discoveredDevices.entries
        .where((entry) => now - entry.value.timestamp > expireTime)
        .map((entry) => entry.key)
        .toList();

    for (final id in expiredIds) {
      final device = _discoveredDevices.remove(id);
      _logger.i('移除过期设备: ${device?.name}');
    }

    if (expiredIds.isNotEmpty) {
      _devicesController.add(devices);
    }
  }

  /// 手动添加设备（用于手动输入IP的情况）
  void addDevice(DeviceInfo device) {
    _discoveredDevices[device.id] = device;
    _devicesController.add(devices);
    _logger.i('手动添加设备: ${device.name} (${device.ip})');
  }

  /// 移除设备
  void removeDevice(String deviceId) {
    if (_discoveredDevices.remove(deviceId) != null) {
      _devicesController.add(devices);
      _logger.i('移除设备: $deviceId');
    }
  }

  /// 清空设备列表
  void clearDevices() {
    _discoveredDevices.clear();
    _devicesController.add(devices);
  }

  /// 释放资源
  void dispose() {
    stop();
    _devicesController.close();
  }
}

