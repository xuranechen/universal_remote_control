import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'ui/pages/home_page.dart';
import 'services/websocket_service.dart';
import 'services/input_capture_service.dart';
import 'services/input_simulator_service.dart';
import 'core/device_discovery.dart';

void main() {
  // 初始化日志
  Logger.level = Level.debug;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // WebSocket服务
        Provider<WebSocketService>(
          create: (_) => WebSocketService(),
          dispose: (_, service) => service.dispose(),
        ),
        
        // 输入捕获服务
        Provider<InputCaptureService>(
          create: (_) => InputCaptureService(),
          dispose: (_, service) => service.dispose(),
        ),
        
        // 输入模拟服务
        Provider<InputSimulatorService>(
          create: (_) => InputSimulatorService(),
          dispose: (_, service) => service.dispose(),
        ),
        
        // 设备发现服务
        Provider<DeviceDiscovery>(
          create: (_) => DeviceDiscovery(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Universal Remote Control',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

