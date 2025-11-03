import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote_control/models/control_event.dart';

void main() {
  group('ControlEvent', () {
    test('创建鼠标移动事件', () {
      final event = ControlEvent.mouseMove(dx: 5.0, dy: -3.0);
      
      expect(event.type, EventType.event);
      expect(event.subtype, EventSubtype.mouseMove);
      expect(event.data['dx'], 5.0);
      expect(event.data['dy'], -3.0);
    });

    test('创建鼠标点击事件', () {
      final event = ControlEvent.mouseClick(
        button: MouseButton.left,
        state: KeyState.press,
      );
      
      expect(event.type, EventType.event);
      expect(event.subtype, EventSubtype.mouseClick);
      expect(event.data['button'], 'left');
      expect(event.data['state'], 'press');
    });

    test('创建键盘事件', () {
      final event = ControlEvent.keyboard(
        key: 'A',
        state: KeyState.press,
        ctrl: true,
      );
      
      expect(event.type, EventType.event);
      expect(event.subtype, EventSubtype.keyboard);
      expect(event.data['key'], 'A');
      expect(event.data['state'], 'press');
      expect(event.data['ctrl'], true);
    });

    test('创建陀螺仪事件', () {
      final event = ControlEvent.gyro(
        pitch: 1.2,
        yaw: 0.3,
        roll: 0.5,
      );
      
      expect(event.type, EventType.event);
      expect(event.subtype, EventSubtype.gyro);
      expect(event.data['pitch'], 1.2);
      expect(event.data['yaw'], 0.3);
      expect(event.data['roll'], 0.5);
    });

    test('JSON序列化和反序列化', () {
      final original = ControlEvent.mouseMove(dx: 10.0, dy: 20.0);
      final json = original.toJson();
      final restored = ControlEvent.fromJson(json);
      
      expect(restored.type, original.type);
      expect(restored.subtype, original.subtype);
      expect(restored.data['dx'], original.data['dx']);
      expect(restored.data['dy'], original.data['dy']);
    });
  });
}

