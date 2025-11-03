# 🤖 GitHub Actions 完整使用指南

本指南详细介绍如何使用GitHub Actions自动构建和发布Universal Remote Control项目。

## 📋 目录

1. [快速开始](#快速开始)
2. [工作流说明](#工作流说明)
3. [自动构建](#自动构建)
4. [自动发布](#自动发布)
5. [配置说明](#配置说明)
6. [故障排查](#故障排查)

---

## 🚀 快速开始

### 第一步：推送代码到GitHub

```bash
# 初始化Git仓库
cd universal_remote_control
git init

# 添加远程仓库
git remote add origin https://github.com/your-username/universal_remote_control.git

# 添加所有文件
git add .
git commit -m "Initial commit"

# 推送到GitHub
git push -u origin main
```

### 第二步：启用GitHub Actions

1. 打开GitHub仓库页面
2. 进入 **Actions** 标签页
3. 如果看到提示，点击 **Enable Actions**
4. 工作流会自动开始运行！

### 第三步：查看构建结果

1. 在 **Actions** 标签页查看运行状态
2. 点击工作流运行查看详细日志
3. 构建完成后在 **Artifacts** 部分下载

---

## 📚 工作流说明

### 1. Build All Platforms (build.yml)

**自动触发条件：**
- ✅ 推送到 `main` 或 `develop` 分支
- ✅ 创建Pull Request到 `main` 分支
- ✅ 手动触发

**构建内容：**
```yaml
jobs:
  - build-windows    # Windows x64
  - build-linux      # Linux x64
  - build-macos      # macOS Universal
  - build-android    # Android APK + AAB
  - build-summary    # 汇总
```

**构建产物：**
- Windows: `windows-build` (7天保留)
- Linux: `linux-build` (7天保留)
- macOS: `macos-build` (7天保留)
- Android APK: `android-apk` (7天保留)
- Android AAB: `android-bundle` (7天保留)

**下载方法：**
1. 进入Actions → 选择工作流运行
2. 滚动到底部 Artifacts 部分
3. 点击下载对应平台的包

### 2. Release Build (release.yml)

**触发方式：**

**方式A：推送版本标签（推荐）**
```bash
# 创建标签
git tag v1.0.0

# 推送标签（触发发布）
git push origin v1.0.0
```

**方式B：手动触发**
1. 进入 Actions → Release Build
2. 点击 "Run workflow"
3. 输入版本号（如 1.0.0）
4. 点击 "Run workflow"

**自动执行：**
1. ✅ 创建GitHub Release
2. ✅ 构建所有平台（Windows, Linux, macOS, Android）
3. ✅ 压缩打包
4. ✅ 上传到Release页面
5. ✅ 生成发布说明

**发布文件命名：**
- `universal_remote_control_windows_v1.0.0.zip`
- `universal_remote_control_linux_v1.0.0.tar.gz`
- `universal_remote_control_macos_v1.0.0.zip`
- `universal_remote_control_v1.0.0.apk`

### 3. Tests (test.yml)

**自动触发条件：**
- ✅ 推送代码
- ✅ 创建Pull Request

**测试内容：**
- 🧪 Dart单元测试
- 📊 代码覆盖率分析
- 🔍 静态代码分析
- 📝 代码格式检查
- 📦 依赖版本检查

---

## 🔄 自动构建详解

### 日常开发流程

```bash
# 1. 开发功能
git checkout -b feature/new-feature
# ... 编写代码 ...

# 2. 提交更改
git add .
git commit -m "Add new feature"

# 3. 推送到GitHub
git push origin feature/new-feature

# 4. 创建Pull Request
# 在GitHub上创建PR → 自动触发构建和测试

# 5. 合并到main
# 合并PR → 再次触发构建
```

### 查看构建状态

**在GitHub网页：**
1. 进入 **Actions** 标签页
2. 查看正在运行或已完成的工作流
3. 点击查看详细日志

**在Pull Request：**
- PR页面会显示检查状态
- 点击 "Details" 查看详细日志
- 所有检查通过才能合并

**在README徽章：**
- 实时显示最新构建状态
- 点击徽章跳转到Actions页面

### 并行构建优化

所有平台并行构建，总耗时约等于最慢平台的构建时间：

```
开始时间: 0:00
├─ Windows 构建  [████████████] 完成 (8分钟)
├─ Linux 构建    [████████████] 完成 (6分钟)
├─ macOS 构建    [████████████] 完成 (10分钟) ← 最慢
└─ Android 构建  [████████████] 完成 (7分钟)

总耗时: ~10分钟（而不是30分钟）
```

---

## 📦 自动发布详解

### 发布新版本完整流程

```bash
# 1. 确保代码已同步
git checkout main
git pull origin main

# 2. 更新版本号
# 编辑 pubspec.yaml
version: 1.0.0+1  # 改为 1.1.0+2

# 3. 提交版本更新
git add pubspec.yaml
git commit -m "Bump version to 1.1.0"
git push origin main

# 4. 创建并推送标签
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0

# 5. 等待自动构建（约10-15分钟）
# 进入GitHub → Releases 查看发布
```

### Release页面内容

自动生成的Release包含：

**📦 下载文件：**
- Windows压缩包 (ZIP)
- Linux压缩包 (tar.gz)
- macOS压缩包 (ZIP)
- Android安装包 (APK)

**📝 发布说明：**
- 版本号
- 下载链接
- 新特性说明
- 使用指南链接
- 系统要求

**示例：**
```markdown
## 🎉 Universal Remote Control v1.1.0

### 📦 下载
- **Windows**: universal_remote_control_windows_v1.1.0.zip
- **Linux**: universal_remote_control_linux_v1.1.0.tar.gz
- **macOS**: universal_remote_control_macos_v1.1.0.zip
- **Android APK**: universal_remote_control_v1.1.0.apk

### ✨ 新特性
- 添加虚拟键盘功能
- 优化陀螺仪响应速度
- 修复Linux平台bug

### 📖 使用说明
请查看快速入门指南...
```

### 版本号规范

推荐使用 [Semantic Versioning](https://semver.org/)：

```
v主版本.次版本.修订版本

v1.0.0  - 初始发布
v1.0.1  - 小bug修复
v1.1.0  - 添加新功能（向后兼容）
v2.0.0  - 重大更新（可能不兼容）
```

---

## ⚙️ 配置说明

### 修改Flutter版本

在所有工作流文件中找到并修改：

```yaml
- name: 设置Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'  # 修改版本
    channel: 'stable'           # 或 'beta', 'dev'
```

### 修改构建平台

**禁用某个平台：**

在 `build.yml` 中注释掉对应job：

```yaml
jobs:
  # build-windows: ...  # 注释掉
  build-linux: ...
  build-macos: ...
  build-android: ...
```

**添加iOS平台：**

```yaml
build-ios:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter build ios --release --no-codesign
```

### 配置Android签名

**1. 准备密钥库：**

```bash
# 生成密钥库
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Base64编码
base64 upload-keystore.jks > keystore.base64
```

**2. 添加GitHub Secrets：**

进入仓库 Settings → Secrets and variables → Actions：

- `KEYSTORE`: `keystore.base64` 的内容
- `KEYSTORE_PASSWORD`: 密钥库密码
- `KEY_PASSWORD`: 密钥密码
- `KEY_ALIAS`: 密钥别名 (upload)

**3. 修改工作流：**

在 `release.yml` 的 Android 构建步骤前添加：

```yaml
- name: 配置签名
  run: |
    echo "${{ secrets.KEYSTORE }}" | base64 --decode > android/app/upload-keystore.jks
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=upload-keystore.jks" >> android/key.properties
```

**4. 修改 `android/app/build.gradle`：**

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 启用缓存加速

在工作流中添加缓存步骤：

```yaml
- name: 缓存Pub依赖
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      ${{ runner.os == 'Windows' && '~\AppData\Local\Pub\Cache' || '~/.pub-cache' }}
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-

- name: 缓存CMake构建
  uses: actions/cache@v3
  with:
    path: native/*/build
    key: ${{ runner.os }}-cmake-${{ hashFiles('native/**/CMakeLists.txt') }}
```

---

## 🐛 故障排查

### 问题1：构建失败

**症状：** 工作流运行失败，显示红色❌

**解决步骤：**

1. **查看详细日志：**
   - 点击失败的工作流运行
   - 展开失败的步骤
   - 查看错误信息

2. **常见错误：**

   **Flutter pub get 失败：**
   ```
   错误：因为 xxx 依赖 yyy...
   解决：更新 pubspec.yaml 中的版本约束
   ```

   **CMake配置失败：**
   ```
   错误：CMake Error: Could not find CMAKE_CXX_COMPILER
   解决：检查 CMakeLists.txt 配置
   ```

   **代码分析错误：**
   ```
   错误：info • Unused import • lib/xxx.dart
   解决：运行 flutter analyze 本地检查
   ```

3. **本地复现：**
   ```bash
   # 本地运行相同命令
   flutter pub get
   flutter pub run build_runner build
   cd native/windows && cmake . && cd ../..
   flutter build windows
   ```

### 问题2：构建超时

**症状：** 构建运行时间过长，被强制终止

**解决方法：**

```yaml
jobs:
  build-windows:
    runs-on: windows-latest
    timeout-minutes: 90  # 增加超时时间（默认60分钟）
```

### 问题3：构建产物无法下载

**症状：** Artifacts部分是空的

**原因：** 构建路径不正确或文件不存在

**解决：** 检查上传路径

```yaml
- name: 上传构建产物
  uses: actions/upload-artifact@v3
  with:
    name: windows-build
    path: release_windows/  # 确保这个路径存在且有文件
```

### 问题4：Release创建失败

**症状：** 自动发布工作流失败

**常见原因：**
- 标签已存在
- 权限不足
- Release已存在

**解决：**

1. **删除已有标签和Release：**
   ```bash
   # 删除本地标签
   git tag -d v1.0.0
   
   # 删除远程标签
   git push origin :refs/tags/v1.0.0
   
   # 在GitHub上手动删除Release
   ```

2. **检查权限：**
   - 确保仓库允许Actions写入
   - Settings → Actions → General → Workflow permissions
   - 选择 "Read and write permissions"

### 问题5：Android构建失败

**症状：** Android步骤失败

**常见原因：**
- Gradle版本不兼容
- Java版本不匹配
- 签名配置错误

**解决：**

```yaml
- name: 设置Java
  uses: actions/setup-java@v3
  with:
    distribution: 'zulu'
    java-version: '17'  # 尝试不同版本：11, 17, 21
```

---

## 📈 性能优化技巧

### 1. 使用构建矩阵

同时构建多个配置：

```yaml
strategy:
  matrix:
    platform: [windows, linux, macos]
    flutter-version: ['3.16.0', '3.19.0']
```

### 2. 条件执行

只在特定情况下运行：

```yaml
- name: 构建Android
  if: contains(github.event.head_commit.message, '[android]')
  run: flutter build apk
```

### 3. 复用工作流

创建可复用的工作流：

```yaml
# .github/workflows/reusable-build.yml
on:
  workflow_call:
    inputs:
      platform:
        required: true
        type: string
```

---

## 📊 监控和通知

### 添加Slack通知

```yaml
- name: 发送Slack通知
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "构建${{ job.status }}: ${{ github.workflow }}"
      }
```

### 添加邮件通知

```yaml
- name: 发送邮件
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.MAIL_USERNAME }}
    password: ${{ secrets.MAIL_PASSWORD }}
    subject: 构建失败：${{ github.workflow }}
    to: your-email@example.com
    from: GitHub Actions
```

---

## 🎓 进阶技巧

### 自动更新版本号

```yaml
- name: 自动更新版本
  run: |
    # 读取当前版本
    VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2)
    # 增加版本号
    NEW_VERSION=$(echo $VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
    # 更新pubspec.yaml
    sed -i "s/version: $VERSION/version: $NEW_VERSION/" pubspec.yaml
```

### 自动生成Changelog

```yaml
- name: 生成Changelog
  uses: mikepenz/release-changelog-builder-action@v3
  with:
    configuration: ".github/changelog-config.json"
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Docker构建

```yaml
- name: 构建Docker镜像
  run: |
    docker build -t universal-remote-control:latest .
    docker push universal-remote-control:latest
```

---

## 📚 相关资源

- [GitHub Actions官方文档](https://docs.github.com/en/actions)
- [Flutter CI/CD最佳实践](https://flutter.dev/docs/deployment/cd)
- [Fastlane集成](https://docs.fastlane.tools/)
- [本项目工作流源码](.github/workflows/)

---

**享受全自动构建和发布的便利！** 🚀

