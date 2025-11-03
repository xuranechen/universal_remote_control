import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:logger/logger.dart';
import '../../utils/qr_code_helper.dart';
import '../../models/device_info.dart';

/// 二维码扫描页面
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  static final Logger _logger = Logger();
  
  MobileScannerController? _controller;
  bool _isScanning = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 初始化扫描器
  void _initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
    
    setState(() {
      _hasPermission = true;
    });
  }

  /// 处理扫描结果
  void _handleScanResult(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;
    
    setState(() {
      _isScanning = false;
    });
    
    _processQRCode(qrData);
  }

  /// 处理二维码数据
  void _processQRCode(String qrData) {
    try {
      final connectionInfo = QRCodeHelper.parseQRData(qrData);
      
      if (connectionInfo == null) {
        _showError('无效的二维码格式');
        return;
      }
      
      if (!QRCodeHelper.isValidConnectionInfo(connectionInfo)) {
        _showError('连接信息无效或已过期');
        return;
      }
      
      _showConnectionDialog(connectionInfo);
    } catch (e) {
      _logger.e('处理二维码失败: $e');
      _showError('解析二维码失败');
    }
  }

  /// 显示连接确认对话框
  void _showConnectionDialog(QRConnectionInfo connectionInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认连接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('检测到设备：'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getDeviceIcon(connectionInfo.deviceType)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connectionInfo.deviceName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('IP: ${connectionInfo.ip}'),
                    Text('端口: ${connectionInfo.port}'),
                    Text('类型: ${_getDeviceTypeName(connectionInfo.deviceType)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('是否连接到此设备？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanning();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToDevice(connectionInfo);
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  /// 连接到设备
  void _connectToDevice(QRConnectionInfo connectionInfo) {
    final deviceInfo = connectionInfo.toDeviceInfo();
    Navigator.pop(context, deviceInfo);
  }

  /// 恢复扫描
  void _resumeScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _resumeScanning,
        ),
      ),
    );
    
    // 延迟恢复扫描
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _resumeScanning();
      }
    });
  }

  /// 切换闪光灯
  void _toggleFlashlight() {
    _controller?.toggleTorch();
  }

  /// 切换摄像头
  void _switchCamera() {
    _controller?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('扫描二维码'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('需要相机权限来扫描二维码'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFlashlight,
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 扫描器
          MobileScanner(
            controller: _controller,
            onDetect: _handleScanResult,
          ),
          
          // 扫描框覆盖层
          _buildScannerOverlay(),
          
          // 底部提示
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isScanning ? '将二维码对准扫描框' : '正在处理...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '扫描被控端设备生成的连接二维码',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建扫描框覆盖层
  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: Theme.of(context).colorScheme.primary,
          borderRadius: 16,
          borderLength: 40,
          borderWidth: 4,
          cutOutSize: 250,
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return Icons.phone_android;
      case DeviceType.ios:
        return Icons.phone_iphone;
      case DeviceType.windows:
        return Icons.computer;
      case DeviceType.macos:
        return Icons.laptop_mac;
      case DeviceType.linux:
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  String _getDeviceTypeName(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.windows:
        return 'Windows';
      case DeviceType.macos:
        return 'macOS';
      case DeviceType.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }
}

/// 自定义扫描框形状
class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path oval = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ));
    return Path.combine(PathOperation.difference, path, oval);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final centerX = rect.center.dx;
    final centerY = rect.center.dy;
    final cutOutRadius = cutOutSize / 2;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final overlayPaint = Paint()..color = overlayColor;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // 画覆盖层
    canvas.drawPath(getOuterPath(rect), overlayPaint);

    // 画四个角的边框
    // 左上角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset),
      borderPaint,
    );

    // 右上角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength),
      borderPaint,
    );

    // 右下角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderOffset),
      borderPaint,
    );

    // 左下角
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
