import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_control/models/device_info.dart';

void main() {
  group('DeviceInfo', () {
    test('创建设备信息', () {
      final device = DeviceInfo(
        id: 'test-id',
        name: 'Test Device',
        type: DeviceType.windows,
        mode: DeviceMode.controller,
        ip: '192.168.1.100',
        port: 9877,
        description: 'Test description',
        timestamp: 1234567890,
      );
      
      expect(device.id, 'test-id');
      expect(device.name, 'Test Device');
      expect(device.type, DeviceType.windows);
      expect(device.mode, DeviceMode.controller);
      expect(device.ip, '192.168.1.100');
      expect(device.port, 9877);
    });

    test('copyWith方法', () {
      final original = DeviceInfo(
        id: 'test-id',
        name: 'Original',
        type: DeviceType.windows,
        mode: DeviceMode.controller,
        ip: '192.168.1.100',
        port: 9877,
        timestamp: 1234567890,
      );
      
      final updated = original.copyWith(name: 'Updated');
      
      expect(updated.name, 'Updated');
      expect(updated.id, original.id);
      expect(updated.type, original.type);
    });

    test('相等性检查', () {
      final device1 = DeviceInfo(
        id: 'same-id',
        name: 'Device 1',
        type: DeviceType.windows,
        mode: DeviceMode.controller,
        ip: '192.168.1.1',
        port: 9877,
        timestamp: 1234567890,
      );
      
      final device2 = DeviceInfo(
        id: 'same-id',
        name: 'Device 2',
        type: DeviceType.linux,
        mode: DeviceMode.controlled,
        ip: '192.168.1.2',
        port: 8888,
        timestamp: 9876543210,
      );
      
      expect(device1 == device2, true); // 相同ID即相等
    });

    test('JSON序列化和反序列化', () {
      final original = DeviceInfo(
        id: 'test-id',
        name: 'Test Device',
        type: DeviceType.android,
        mode: DeviceMode.controlled,
        ip: '192.168.1.100',
        port: 9877,
        timestamp: 1234567890,
      );
      
      final json = original.toJson();
      final restored = DeviceInfo.fromJson(json);
      
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.mode, original.mode);
    });
  });

  group('DeviceCapabilities', () {
    test('创建设备能力', () {
      final capabilities = DeviceCapabilities(
        supportGyro: true,
        supportTouch: true,
        supportKeyboard: false,
        supportMouse: false,
        canSimulateInput: true,
        canCaptureScreen: false,
      );
      
      expect(capabilities.supportGyro, true);
      expect(capabilities.supportTouch, true);
      expect(capabilities.canSimulateInput, true);
    });
  });
}

