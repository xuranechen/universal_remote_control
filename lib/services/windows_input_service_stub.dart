import 'package:logger/logger.dart';
import '../models/control_event.dart';

/// Windows输入服务的存根实现（用于非Windows平台）
class WindowsInputService {
  static final Logger _logger = Logger();

  Future<void> handleEvent(ControlEvent event) async {
    _logger.w('WindowsInputService仅在Windows平台可用');
  }
}
