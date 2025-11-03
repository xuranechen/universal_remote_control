# 🚀 快速入门指南

欢迎使用 Universal Remote Control！这是一个跨平台的远程控制系统，支持任意设备作为控制端或被控端。

## 📦 项目已包含内容

✅ **完整的项目结构**
- Flutter跨平台UI框架
- Dart业务逻辑层
- C++原生输入模拟库（Windows/Linux/macOS）
- Kotlin Android输入模拟（AccessibilityService）

✅ **核心功能**
- 设备自动发现（UDP广播）
- WebSocket实时通信
- 陀螺仪飞鼠控制
- 虚拟触摸板
- 跨平台输入模拟

✅ **完整文档**
- 构建指南
- 架构文档
- API说明

## ⚡ 1分钟快速体验（一键打包）

### 🎯 最快方式 - 使用自动化脚本

**Windows:**
```bash
# 双击运行或命令行执行
scripts\build_all.bat
```

**Linux/macOS:**
```bash
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

**Android:**
```bash
# Windows
scripts\build_android.bat

# Linux/macOS
chmod +x scripts/build_android.sh
./scripts/build_android.sh
```

脚本会自动完成所有步骤，直接输出可运行的程序！

输出位置：
- Windows: `build\windows\runner\Release\`
- Linux: `build/linux/x64/release/bundle/`
- macOS: `build/macos/Build/Products/Release/`
- Android: `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚡ 5分钟手动体验（了解细节）

如果你想了解每一步做了什么：

### 步骤1：安装Flutter依赖

```bash
cd universal_remote_control
flutter pub get
```

### 步骤2：生成代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤3：编译原生库（根据你的平台）

**Windows:**
```bash
cd native/windows
mkdir build && cd build
cmake .. && cmake --build . --config Release
copy Release\input_simulator_windows.dll ..\..\..
```

**Linux:**
```bash
cd native/linux
mkdir build && cd build
cmake .. && make
cp libinput_simulator_linux.so ../../..
```

**macOS:**
```bash
cd native/macos
mkdir build && cd build
cmake .. && make
cp libinput_simulator_macos.dylib ../../..
```

**Android:**
Android使用Kotlin实现，按照 `native/android/README.md` 配置即可。

### 步骤4：运行项目

```bash
# 桌面平台
flutter run -d windows  # 或 linux / macos

# 移动平台
flutter run -d android  # 或 ios
```

## 💡 使用场景

### 场景1：手机控制PC

1. **PC端**：启动应用 → 选择"被控端模式"
2. **手机端**：启动应用 → 选择"控制端模式" → 扫描设备
3. **连接**：手机上选择PC → 开始控制！

### 场景2：平板控制Android手机

1. **Android手机**：
   - 启动应用 → 选择"被控端模式"
   - 开启无障碍服务权限（首次需要）
2. **平板**：启动应用 → 选择"控制端模式" → 连接
3. **控制**：使用触摸板或陀螺仪控制

### 场景3：笔记本控制台式机

同样适用于任何桌面平台组合！

## 🎮 控制方式

### 1. 虚拟触摸板模式
- 在触摸板区域滑动 = 移动鼠标
- 点击触摸板 = 鼠标左键点击
- 调节灵敏度滑块 = 自定义移动速度

### 2. 陀螺仪飞鼠模式（移动设备）
- 启用陀螺仪
- 移动设备 = 控制鼠标方向
- 点击屏幕 = 鼠标点击

## 📋 项目结构总览

```
universal_remote_control/
├── lib/                        # Flutter/Dart代码
│   ├── core/                   # 核心功能（协议、发现）
│   ├── models/                 # 数据模型
│   ├── services/               # 服务层（网络、输入）
│   ├── ui/                     # 用户界面
│   │   ├── pages/              # 页面
│   │   └── widgets/            # 组件
│   └── utils/                  # 工具类
├── native/                     # 原生代码
│   ├── windows/                # Windows C++
│   ├── linux/                  # Linux C++
│   ├── macos/                  # macOS C++
│   └── android/                # Android Kotlin
├── docs/                       # 文档
│   ├── BUILD_GUIDE.md          # 构建指南
│   └── ARCHITECTURE.md         # 架构说明
├── pubspec.yaml                # Flutter配置
└── README.md                   # 项目说明
```

## 🔧 配置选项

### 修改端口

在 `lib/core/device_discovery.dart`:
```dart
static const int discoveryPort = 9876;  // UDP广播端口
```

在 `lib/services/websocket_service.dart`:
```dart
static const int defaultPort = 9877;    // WebSocket端口
```

### 调整陀螺仪灵敏度

在 `lib/services/input_capture_service.dart`:
```dart
double gyroPitchSensitivity = 10.0;
double gyroYawSensitivity = 10.0;
double gyroDeadZone = 0.1;
```

## ⚠️ 常见问题

### Q: 设备扫描不到？
- 确保在同一局域网
- 检查防火墙设置
- 尝试手动输入IP

### Q: 连接失败？
- 确认被控端已启动
- 检查端口是否被占用
- 查看防火墙是否阻止

### Q: Android无法模拟输入？
- 必须开启无障碍服务权限
- 设置 → 无障碍 → Universal Remote Control → 启用

### Q: macOS权限问题？
- 系统偏好设置 → 安全性与隐私 → 辅助功能
- 添加应用到列表并授权

### Q: 陀螺仪不工作？
- 只有移动设备支持
- 必须在真机测试（模拟器不支持）

## 📚 更多文档

- **构建指南**: `docs/BUILD_GUIDE.md` - 详细的编译和打包说明
- **架构文档**: `docs/ARCHITECTURE.md` - 深入理解系统设计
- **Android集成**: `native/android/README.md` - Android特定配置
- **Windows开发**: `native/windows/README.md` - Windows原生库说明
- **Linux开发**: `native/linux/README.md` - Linux原生库说明
- **macOS开发**: `native/macos/README.md` - macOS原生库说明

## 🎯 下一步

现在你已经有了一个完整的项目！接下来可以：

1. ✨ **定制UI** - 修改主题、颜色、布局
2. 🚀 **添加功能** - 虚拟键盘、文件传输、剪贴板同步
3. 🔐 **增强安全** - 添加密码保护、加密通信
4. ⚡ **优化性能** - 使用UDP降低延迟、本地预测
5. 📱 **发布应用** - 打包发布到各个平台

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

---

**享受跨平台远程控制的乐趣！** 🎉

