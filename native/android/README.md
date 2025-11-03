# Android 输入模拟实现

## 概述

Android平台使用 **AccessibilityService（无障碍服务）** 来实现输入模拟，无需root权限。

## 集成步骤

### 1. 复制文件

将以下文件复制到Flutter项目的Android部分：

```
android/app/src/main/kotlin/com/example/universal_remote_control/
├── RemoteControlAccessibilityService.kt
├── InputSimulatorPlugin.kt
└── TouchPoint.kt (包含在RemoteControlAccessibilityService.kt中)

android/app/src/main/res/xml/
└── accessibility_service_config.xml
```

### 2. 修改 AndroidManifest.xml

在 `android/app/src/main/AndroidManifest.xml` 中添加权限和服务声明。

参考 `AndroidManifest_snippet.xml` 文件的内容。

### 3. 添加字符串资源

在 `android/app/src/main/res/values/strings.xml` 中添加：

```xml
<string name="accessibility_service_description">
    允许远程控制应用模拟触摸和点击操作。启用后，其他设备可以远程控制此设备。
</string>
```

### 4. 注册插件

在 `android/app/src/main/kotlin/com/example/universal_remote_control/MainActivity.kt` 中：

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册输入模拟插件
        flutterEngine.plugins.add(InputSimulatorPlugin())
    }
}
```

### 5. Dart端调用

在Dart代码中通过Platform Channel调用：

```dart
import 'package:flutter/services.dart';

class AndroidInputSimulator {
  static const platform = MethodChannel(
    'com.example.universal_remote_control/input_simulator'
  );

  // 检查服务是否启用
  static Future<bool> isServiceEnabled() async {
    return await platform.invokeMethod('isServiceEnabled');
  }

  // 打开无障碍设置
  static Future<void> openAccessibilitySettings() async {
    await platform.invokeMethod('openAccessibilitySettings');
  }

  // 执行点击
  static Future<bool> performClick(double x, double y) async {
    return await platform.invokeMethod('performClick', {
      'x': x,
      'y': y,
      'duration': 100,
    });
  }

  // 执行滑动
  static Future<bool> performSwipe(
    double x1, double y1,
    double x2, double y2,
  ) async {
    return await platform.invokeMethod('performSwipe', {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'duration': 300,
    });
  }

  // 模拟鼠标移动
  static Future<bool> simulateMouseMove(double dx, double dy) async {
    return await platform.invokeMethod('simulateMouseMove', {
      'dx': dx,
      'dy': dy,
    });
  }

  // 执行返回
  static Future<bool> performBack() async {
    return await platform.invokeMethod('performBack');
  }

  // 执行Home
  static Future<bool> performHome() async {
    return await platform.invokeMethod('performHome');
  }
}
```

## 使用流程

1. **首次使用**：引导用户开启无障碍服务
   ```dart
   if (!await AndroidInputSimulator.isServiceEnabled()) {
     // 显示引导界面
     await AndroidInputSimulator.openAccessibilitySettings();
   }
   ```

2. **执行操作**：服务启用后即可使用
   ```dart
   // 点击屏幕中心
   await AndroidInputSimulator.performClick(
     screenWidth / 2,
     screenHeight / 2,
   );
   ```

## 功能列表

### 支持的操作

- ✅ 点击（Click）
- ✅ 长按（Long Press）
- ✅ 滑动（Swipe）
- ✅ 多点触控（Multi-touch）
- ✅ 全局操作（返回、Home、最近任务等）
- ⚠️ 鼠标移动（模拟实现，需要自定义光标UI）
- ❌ 键盘输入（AccessibilityService无法直接模拟）

### 限制

1. **键盘输入**：无法通过AccessibilityService模拟键盘输入
   - 解决方案：使用ADB命令（需要调试模式）或IME（输入法）方案

2. **某些系统界面**：系统设置、锁屏等界面可能无法操作

3. **游戏检测**：部分游戏可能检测并阻止AccessibilityService

## 权限说明

用户需要手动在以下位置启用无障碍服务：

```
设置 > 无障碍 > 已安装的服务 > Universal Remote Control
```

应用会自动检测服务状态并引导用户开启。

## 调试

查看日志：
```bash
adb logcat -s RemoteControlA11yService InputSimulatorPlugin
```

检查服务状态：
```bash
adb shell settings get secure enabled_accessibility_services
```

## 注意事项

⚠️ **隐私和安全**
- 无障碍服务具有高级权限
- 务必向用户清楚说明用途
- 遵守Google Play政策
- 不要滥用权限

⚠️ **电池优化**
- 可能需要禁用电池优化以保持服务运行
- 在设置中引导用户操作

## 常见问题

**Q: 服务启用后不工作？**
A: 检查服务是否真的在运行，重启应用或重启设备

**Q: 能模拟键盘输入吗？**
A: 不能直接模拟，需要使用其他方案（ADB或IME）

**Q: 支持Android版本？**
A: API 24 (Android 7.0) 及以上

