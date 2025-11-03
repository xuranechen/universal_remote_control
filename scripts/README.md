# 📦 一键打包脚本说明

本目录包含了各平台的一键打包脚本，让你轻松编译和打包应用。

## 🚀 快速使用

### Windows 平台

双击运行或在命令行执行：
```bash
scripts\build_all.bat
```

### Linux/macOS 平台

添加执行权限并运行：
```bash
chmod +x scripts/build_all.sh
./scripts/build_all.sh
```

### Android 平台

**Windows:**
```bash
scripts\build_android.bat
```

**Linux/macOS:**
```bash
chmod +x scripts/build_android.sh
./scripts/build_android.sh
```

## 📋 脚本功能

### build_all.bat / build_all.sh
**全自动桌面平台打包**

自动完成以下步骤：
1. ✅ 清理旧的构建文件
2. ✅ 安装Flutter依赖
3. ✅ 生成代码文件（JSON序列化）
4. ✅ 编译原生C++库
5. ✅ 编译Flutter应用
6. ✅ 创建发布包（带日期）
7. ✅ 复制必要文档

**输出位置:**
- Windows: `build\windows\runner\Release\`
- Linux: `build/linux/x64/release/bundle/`
- macOS: `build/macos/Build/Products/Release/`

**发布包位置:**
- Windows: `release_windows_YYYYMMDD\`
- Linux: `release_linux_YYYYMMDD/`
- macOS: `release_macos_YYYYMMDD/`

### build_android.bat / build_android.sh
**Android APK打包**

自动完成以下步骤：
1. ✅ 清理旧的构建文件
2. ✅ 安装Flutter依赖
3. ✅ 生成代码文件
4. ✅ 编译Android Release APK
5. ✅ 创建发布包
6. ✅ 显示安装说明

**输出位置:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`

**发布包位置:**
- `release_android_YYYYMMDD/UniversalRemoteControl.apk`

## 🔧 环境要求

### 所有平台
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Windows
- Visual Studio 2019+ (含C++工具)
- CMake 3.15+

### Linux
```bash
sudo apt-get install -y \
    build-essential \
    cmake \
    libx11-dev \
    libxtst-dev \
    libxext-dev
```

### macOS
```bash
xcode-select --install
brew install cmake
```

### Android
- Android Studio
- Android SDK (API Level 24+)

## 📝 脚本特点

### ✨ 优点
- 🎯 **一键完成** - 无需手动执行多个命令
- 🔍 **自动检查** - 检测必需工具是否安装
- 🧹 **自动清理** - 清理旧的构建文件
- 📦 **自动打包** - 创建带日期的发布包
- 📄 **包含文档** - 自动复制README到发布包
- ⚠️ **错误处理** - 遇到错误立即停止并提示

### 🎨 输出信息
- 清晰的步骤提示
- 进度显示（[1/5], [2/5] ...）
- 成功/失败状态
- 输出位置提示
- 文件大小信息

## 🛠️ 自定义

### 修改输出目录

编辑脚本，找到 `RELEASE_DIR` 变量：

```bash
# Windows (build_all.bat)
set RELEASE_DIR=your_custom_name

# Linux/macOS (build_all.sh)
RELEASE_DIR="your_custom_name"
```

### 修改编译选项

在Flutter编译命令中添加参数：

```bash
# 例如：分离调试信息
flutter build windows --release --split-debug-info=symbols

# 例如：混淆Dart代码
flutter build apk --release --obfuscate --split-debug-info=symbols
```

### 添加额外的后处理

在脚本末尾添加自定义命令：

```bash
# 例如：自动压缩发布包
# Windows
powershell Compress-Archive -Path %RELEASE_DIR% -DestinationPath %RELEASE_DIR%.zip

# Linux/macOS
tar -czf $RELEASE_DIR.tar.gz $RELEASE_DIR
```

## ❓ 常见问题

### Q: 脚本执行失败？

**A:** 检查以下几点：
1. 确认Flutter已正确安装：`flutter doctor`
2. 确认CMake已安装：`cmake --version`
3. 检查网络连接（下载依赖需要）
4. 查看错误信息的具体提示

### Q: Linux脚本没有执行权限？

**A:** 添加执行权限：
```bash
chmod +x scripts/*.sh
```

### Q: Windows脚本被安全软件阻止？

**A:** 
1. 将项目目录添加到安全软件白名单
2. 或者右键脚本 → 属性 → 解除锁定

### Q: 编译时间很长？

**A:** 这是正常的，首次编译需要：
- 下载依赖包
- 编译原生库
- 编译Flutter代码

后续编译会快很多（增量编译）。

### Q: 想要更详细的输出？

**A:** 在脚本中添加 `-v` 参数：
```bash
flutter build windows --release -v
```

## 🎯 进阶用法

### 持续集成（CI）

这些脚本可以直接用于CI/CD流程：

**GitHub Actions 示例:**
```yaml
- name: Build Windows
  run: |
    cd scripts
    .\build_all.bat
```

**GitLab CI 示例:**
```yaml
build_linux:
  script:
    - chmod +x scripts/build_all.sh
    - ./scripts/build_all.sh
```

### 批量打包所有平台

创建一个总控脚本：

**Linux/macOS (build_all_platforms.sh):**
```bash
#!/bin/bash
./scripts/build_all.sh       # 本平台
./scripts/build_android.sh   # Android
```

## 📊 性能提示

### 加速编译

1. **使用更多CPU核心:**
   ```bash
   # 在CMake编译时
   make -j8  # 使用8核心
   ```

2. **关闭不必要的程序**
   - 编译时占用大量内存
   - 关闭浏览器等大型程序

3. **使用SSD**
   - 项目放在SSD上编译更快

### 减小包体积

```bash
# Flutter编译时分离调试信息
flutter build windows --release --split-debug-info=symbols

# 分析包大小
flutter build apk --analyze-size
```

## 🔐 签名配置

### Android签名

1. 创建密钥库：
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. 配置 `android/key.properties`

3. 脚本会自动使用签名

详细说明见：`docs/BUILD_GUIDE.md`

## 📞 获取帮助

如果遇到问题：
1. 查看 `docs/BUILD_GUIDE.md`
2. 检查脚本输出的错误信息
3. 运行 `flutter doctor` 检查环境

---

**享受一键打包的便利！** 🚀

