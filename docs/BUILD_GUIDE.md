# 构建指南

## 📋 目录

1. [环境准备](#环境准备)
2. [依赖安装](#依赖安装)
3. [编译原生库](#编译原生库)
4. [运行项目](#运行项目)
5. [打包发布](#打包发布)
6. [常见问题](#常见问题)

---

## 环境准备

### 通用要求
- **Flutter SDK** >= 3.0.0
- **Dart SDK** >= 3.0.0

### 平台特定要求

#### Windows
- Visual Studio 2019 或更高版本（包含C++工具）
- CMake 3.15+
- Windows SDK

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    libx11-dev \
    libxtst-dev \
    libxext-dev \
    clang \
    ninja-build \
    pkg-config

# Fedora/RHEL
sudo dnf install -y \
    gcc-c++ \
    cmake \
    libX11-devel \
    libXtst-devel \
    libXext-devel \
    clang \
    ninja-build
```

#### macOS
```bash
# 安装Command Line Tools
xcode-select --install

# 安装CMake（使用Homebrew）
brew install cmake
```

#### Android
- Android Studio
- Android SDK (API Level 24+)
- NDK（如果需要）

---

## 依赖安装

### 1. 克隆项目
```bash
git clone <your-repo>
cd universal_remote_control
```

### 2. 添加桌面平台支持（重要！）

项目需要Flutter的桌面平台支持。首次构建前，必须运行以下命令：

```bash
# 添加Windows平台支持
flutter create --platforms=windows .

# 添加Linux平台支持
flutter create --platforms=linux .

# 添加macOS平台支持
flutter create --platforms=macos .
```

> **注意**: 这一步会创建平台特定的目录（`windows/`, `linux/`, `macos/`），这些目录包含Flutter桌面应用的启动器和配置文件。`native/` 目录中的原生库是单独的。

### 3. 安装Flutter依赖
```bash
flutter pub get
```

### 4. 生成代码（JSON序列化）
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 编译原生库

### Windows

```bash
cd native/windows
mkdir build && cd build
cmake ..
cmake --build . --config Release

# 复制DLL到Flutter项目根目录
copy bin\Release\input_simulator_windows.dll ..\..\..
```

### Linux

```bash
cd native/linux
mkdir build && cd build
cmake ..
make

# 复制.so到Flutter项目根目录
cp lib/libinput_simulator_linux.so ../../..
```

### macOS

```bash
cd native/macos
mkdir build && cd build
cmake ..
make

# 复制.dylib到Flutter项目根目录
cp lib/libinput_simulator_macos.dylib ../../..
```

### Android

Android部分使用Kotlin实现，不需要单独编译。

但需要进行以下配置：

1. **复制文件到Android项目**

```bash
# 复制Kotlin文件
cp native/android/*.kt android/app/src/main/kotlin/com/example/universal_remote_control/

# 复制XML配置
mkdir -p android/app/src/main/res/xml
cp native/android/accessibility_service_config.xml android/app/src/main/res/xml/
```

2. **修改AndroidManifest.xml**

参考 `native/android/AndroidManifest_snippet.xml` 的内容。

3. **添加字符串资源**

在 `android/app/src/main/res/values/strings.xml` 中添加：

```xml
<string name="accessibility_service_description">
    允许远程控制应用模拟触摸和点击操作。启用后，其他设备可以远程控制此设备。
</string>
```

---

## 运行项目

### 桌面平台

```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

### 移动平台

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

### 检查可用设备
```bash
flutter devices
```

---

## 打包发布

### Windows

```bash
flutter build windows --release
```

输出目录：`build/windows/runner/Release/`

包含：
- `universal_remote_control.exe`
- `input_simulator_windows.dll`
- 其他依赖DLL

### Linux

```bash
flutter build linux --release
```

输出目录：`build/linux/x64/release/bundle/`

### macOS

```bash
flutter build macos --release
```

输出目录：`build/macos/Build/Products/Release/`

### Android APK

```bash
flutter build apk --release
```

输出：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle（用于Google Play）

```bash
flutter build appbundle --release
```

输出：`build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

需要配置签名和证书。

---

## 常见问题

### Q1: "No Windows desktop project configured" 错误？

**错误信息**:
```
No Windows desktop project configured. See https://docs.flutter.dev/desktop#add-desktop-support-to-an-existing-flutter-app to learn about adding Windows support to a project.
```

**原因**: 项目缺少Flutter标准的Windows桌面支持配置。

**解决方案**:
```bash
# 添加Windows平台支持
flutter create --platforms=windows .

# 然后重新构建
flutter build windows --release
```

这个命令会创建 `windows/` 目录，包含必要的Flutter Windows应用框架文件。

> **提示**: 对于Linux和macOS平台，使用相应的 `--platforms=linux` 或 `--platforms=macos` 参数。

### Q2: 编译原生库时找不到头文件？

**Windows**: 确保安装了Windows SDK和C++工具。

**Linux**: 安装开发包：
```bash
sudo apt-get install libx11-dev libxtst-dev
```

**macOS**: 安装Command Line Tools：
```bash
xcode-select --install
```

### Q3: Flutter找不到原生库？

确保原生库文件在正确的位置：
- Windows: `input_simulator_windows.dll` 在项目根目录或system32
- Linux: `libinput_simulator_linux.so` 在项目根目录或 `/usr/local/lib`
- macOS: `libinput_simulator_macos.dylib` 在项目根目录

或者设置环境变量：
```bash
# Linux
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/lib

# macOS
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/path/to/lib
```

### Q4: Android无障碍服务无法启用？

1. 检查 `AndroidManifest.xml` 是否正确配置
2. 检查 `accessibility_service_config.xml` 是否在正确位置
3. 确认包名是否匹配
4. 重新安装应用

### Q5: 权限问题？

**Linux**: 某些发行版需要将用户添加到input组：
```bash
sudo usermod -a -G input $USER
```

**macOS**: 需要在系统偏好设置中授予辅助功能权限。

**Android**: 需要手动开启无障碍服务权限。

### Q6: 陀螺仪不工作？

1. 检查设备是否支持陀螺仪
2. 检查权限是否授予
3. 在真机上测试（模拟器可能不支持）

### Q7: 网络连接失败？

1. 确保设备在同一局域网
2. 检查防火墙设置
3. 确认端口9876和9877未被占用
4. 尝试手动输入IP地址

---

## 开发建议

### 代码生成

修改模型类后，重新生成代码：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 热重载

在开发过程中使用热重载：
```bash
flutter run
# 按 r 进行热重载
# 按 R 进行热重启
```

### 调试

启用详细日志：
```dart
// 在main.dart中
Logger.level = Level.debug;
```

查看原生日志：
```bash
# Android
adb logcat

# 过滤特定标签
adb logcat -s RemoteControlA11yService InputSimulatorPlugin
```

---

## 性能优化

1. **使用Release模式构建**
   ```bash
   flutter build <platform> --release
   ```

2. **优化陀螺仪采样率**
   在 `input_capture_service.dart` 中调整采样频率

3. **网络优化**
   使用UDP代替WebSocket以降低延迟（需要实现）

---

## 更多资源

- [Flutter官方文档](https://flutter.dev/docs)
- [FFI文档](https://dart.dev/guides/libraries/c-interop)
- [Android AccessibilityService](https://developer.android.com/reference/android/accessibilityservice/AccessibilityService)

