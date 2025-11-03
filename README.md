![Build Status](https://github.com/xuranechen/universal_remote_control/actions/workflows/build.yml/badge.svg)
![Release](https://github.com/xuranechen/universal_remote_control/actions/workflows/release.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-lightgrey.svg)

一个由AI实现的跨平台的通用远程控制系统，让任意设备都能成为控制端或被控端。

📚 **[查看所有文档](DOCS.md)** | 🚀 **[快速开始](QUICKSTART.md)** | 📝 **[更新日志](CHANGELOG.md)**

## 🌟 核心特性

- ✅ **真正跨平台**: Android / iOS / Windows / macOS / Linux 全支持
- 🔄 **双向控制**: 任意设备都可以作为控制端或被控端
- 🎯 **多种输入方式**:
  - 🎮 陀螺仪飞鼠控制
  - 📱 触摸屏模拟触摸板
  - ⌨️ 完整虚拟键盘（支持快捷键）
  - 🖱️ 精确鼠标操作
- 🌐 **智能设备发现**: UDP广播 + QR码扫描连接
- 🎨 **现代化UI**: 响应式设计，适配所有屏幕尺寸
- ✨ **流畅动画**: 页面过渡和交互反馈动画
- ⚡ **高性能优化**: 事件节流、批处理、缓存系统
- 🔒 **安全加密**: 支持密码配对和加密通信
- 📱 **完美适配**: 移动端、平板、桌面三种布局模式

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│              Universal Remote Control                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌───────────────┐                  ┌───────────────┐     │
│   │  控制端模式    │  ◄────────────►  │   被控端模式   │     │
│   └───────┬───────┘                  └───────┬───────┘     │
│           │                                  │             │
│           └──────────────┬───────────────────┘             │
│                          │                                 │
│           ┌──────────────▼──────────────┐                  │
│           │      统一通信协议层          │                  │
│           │    (WebSocket + JSON)       │                  │
│           └──────────────┬──────────────┘                  │
│                          │                                 │
│            ┌─────────────┼─────────────┐                   │
│            │             │             │                   │
│   ┌────────▼────────┐   │   ┌─────────▼────────┐          │
│   │   输入捕获层     │   │   │   输入模拟层     │          │
│   ├─────────────────┤   │   ├─────────────────┤          │
│   │ • 陀螺仪         │   │   │ • 键鼠模拟      │          │
│   │ • 触摸           │   │   │ • 触摸模拟      │          │
│   │ • 键鼠           │   │   │ • 命令执行      │          │
│   └─────────────────┘   │   └─────────────────┘          │
│                          │                                 │
│           ┌──────────────▼──────────────┐                  │
│           │      设备发现与配对         │                  │
│           │      (mDNS/UDP 广播)       │                  │
│           └─────────────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📦 模块说明

### Core 核心层
- `protocol.dart` - 统一通信协议
- `connection_manager.dart` - 连接管理
- `device_discovery.dart` - 设备发现（UDP广播）

### Services 服务层
- `websocket_service.dart` - WebSocket通信
- `input_capture_service.dart` - 输入捕获
- `input_simulator_service.dart` - 输入模拟

### Models 数据模型
- `device_info.dart` - 设备信息
- `control_event.dart` - 控制事件
- `connection_state.dart` - 连接状态

### UI 界面层
- `pages/` - 页面
  - `home_page.dart` - 主页（模式选择，响应式设计）
  - `controller_page.dart` - 控制端界面（三种控制模式）
  - `controlled_page.dart` - 被控端界面（状态显示+QR码）
  - `device_list_page.dart` - 设备列表（扫描+手动添加）
  - `qr_scanner_page.dart` - QR码扫描页面
- `widgets/` - 组件
  - `virtual_touchpad.dart` - 虚拟触摸板（支持右键+滚动）
  - `gyro_controller.dart` - 陀螺仪控制器
  - `virtual_keyboard.dart` - 完整虚拟键盘（QWERTY+快捷键）

### Utils 工具层
- `responsive_helper.dart` - 响应式布局工具
- `animations.dart` - 动画管理系统
- `performance_manager.dart` - 性能优化管理器
- `qr_code_helper.dart` - QR码编码解码工具

### Native 原生层
- `windows/` - Windows输入模拟（C++）
- `linux/` - Linux输入模拟（C++）
- `macos/` - macOS输入模拟（C++）
- `android/` - Android输入模拟（Kotlin）

## 🚀 快速开始

### 🎯 一键打包（推荐）

**最简单的方式 - 使用自动化脚本：**

#### Windows
```bash
# 双击运行或在命令行执行
scripts\build_all.bat
```

#### Linux/macOS
```bash
# 添加执行权限并运行
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

#### Android
```bash
# Windows
scripts\build_android.bat

# Linux/macOS
chmod +x scripts/build_android.sh
./scripts/build_android.sh
```

**脚本会自动完成：**
- ✅ 清理旧文件
- ✅ 安装依赖
- ✅ 生成代码
- ✅ 编译原生库
- ✅ 编译Flutter应用
- ✅ 创建发布包

详细说明见：`scripts/README.md`

---

### 📖 手动编译（进阶）

如果你想了解每一步的细节或需要自定义编译选项：

#### 环境要求

- Flutter SDK >= 3.0.0
- 对于C++编译:
  - Windows: Visual Studio 2019+ with C++ tools
  - Linux: GCC/Clang
  - macOS: Xcode Command Line Tools

#### 安装依赖

```bash
cd universal_remote_control
flutter pub get
flutter pub run build_runner build
```

#### 编译原生库

**Windows:**
```bash
cd native/windows
mkdir build && cd build
cmake ..
cmake --build . --config Release
copy bin\Release\input_simulator_windows.dll ..\..\..
```

**Linux:**
```bash
cd native/linux
mkdir build && cd build
cmake ..
make
cp lib/libinput_simulator_linux.so ../../..
```

**macOS:**
```bash
cd native/macos
mkdir build && cd build
cmake ..
make
cp lib/libinput_simulator_macos.dylib ../../..
```

#### 运行项目

```bash
# 运行在桌面
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d macos    # macOS

# 运行在移动端
flutter run -d android  # Android
flutter run -d ios      # iOS
```

## 🎨 应用图标配置

项目已配置自动图标生成系统，支持所有平台。

### 快速设置图标

1. **准备图标**：1024x1024px PNG文件
2. **放入文件夹**：`assets/icon/app_icon.png`
3. **运行脚本**：
   ```bash
   # Windows
   scripts\generate_icons.bat
   
   # Linux/macOS
   ./scripts/generate_icons.sh
   ```

**快速生成图标**：访问 [AppIcon.co](https://www.appicon.co/) 使用"Text to Icon"功能，输入🎮或URC，选择蓝色背景即可。

详细说明见：`assets/icon/README.md`

## 📱 Android 特殊配置

### 权限配置

在 `android/app/src/main/AndroidManifest.xml` 中需要添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 无障碍服务（用于输入模拟）

如果作为被控端，需要开启无障碍服务权限。

## 🎯 使用说明

### 作为控制端

1. 启动应用，选择"控制端模式"
2. 发现设备：
   - 📡 自动扫描局域网内的被控设备
   - 📱 扫描QR码快速连接
   - ➕ 手动添加设备IP
3. 选择要控制的设备并连接
4. 选择控制模式：
   - 🎮 **陀螺仪模式**：移动设备控制鼠标指针
   - 📱 **触摸板模式**：触摸屏模拟触摸板（支持右键、滚动）
   - ⌨️ **键盘模式**：完整虚拟键盘（支持快捷键组合）

### 作为被控端

1. 启动应用，选择"被控端模式"
2. 设备信息展示：
   - 📶 实时连接状态显示
   - 📊 网络统计信息
   - 📱 生成QR码供控制端扫描
3. 等待控制端连接
4. （Android）首次使用需要授予无障碍权限

## 🔧 通信协议

### 事件格式

```json
{
  "type": "event",
  "subtype": "mouse_move",
  "timestamp": 1234567890,
  "data": {
    "dx": 5,
    "dy": -3
  }
}
```

### 支持的事件类型

- `mouse_move` - 鼠标移动
- `mouse_click` - 鼠标点击
- `mouse_scroll` - 鼠标滚轮
- `keyboard` - 键盘输入
- `touch` - 触摸事件
- `gyro` - 陀螺仪数据
- `command` - 系统命令

## 🤖 GitHub Actions 自动化

项目集成了完整的CI/CD自动化流程：

### 自动构建（每次提交）
- ✅ 并行构建4个平台
- ✅ 自动运行测试
- ✅ 代码质量检查
- ✅ 构建产物自动上传

### 自动发布（推送标签）
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# 自动触发：
# - 构建所有平台
# - 创建GitHub Release
# - 上传所有安装包
```

详细说明：[.github/workflows/README.md](.github/workflows/README.md)

## 🛠️ 开发路线图

### ✅ 已完成功能

- [x] **基础架构**
  - [x] 基础项目结构
  - [x] 核心通信协议
  - [x] 设备发现功能
  - [x] 一键打包脚本
  - [x] GitHub Actions CI/CD

- [x] **跨平台输入模拟**
  - [x] Windows输入模拟（C++ Win32 API）
  - [x] Linux输入模拟（C++ XTest）
  - [x] macOS输入模拟（C++ Core Graphics）
  - [x] Android输入模拟（AccessibilityService）

- [x] **控制功能**
  - [x] 陀螺仪飞鼠功能
  - [x] 虚拟触摸板（支持右键+滚动）
  - [x] ⌨️ **完整虚拟键盘**（QWERTY+快捷键）

- [x] **用户界面**
  - [x] 🎨 **响应式UI设计**（移动端/平板/桌面）
  - [x] ✨ **流畅动画系统**（页面过渡+交互反馈）
  - [x] 📱 **QR码扫描连接**
  - [x] 🎯 **三种控制模式切换**

- [x] **性能优化**
  - [x] ⚡ **性能管理系统**（节流、防抖、批处理）
  - [x] 🧠 **智能缓存机制**（LRU缓存）
  - [x] 📊 **性能监控工具**

### 🚧 开发中

- [ ] 安全加密
- [ ] 多设备管理
- [ ] 云端中继支持
- [ ] 语音控制
- [ ] 手势识别

## 📄 许可证

MIT License

## 👨‍💻 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

如有问题请提交 Issue。

