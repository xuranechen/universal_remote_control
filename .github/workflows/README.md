# 🤖 GitHub Actions 自动化工作流

本目录包含了Universal Remote Control项目的CI/CD自动化工作流配置。

## 📋 工作流列表

### 1. build.yml - 持续集成构建
**触发条件：**
- 推送到 `main` 或 `develop` 分支
- 创建Pull Request到 `main` 分支
- 手动触发

**功能：**
- ✅ 并行构建4个平台（Windows, Linux, macOS, Android）
- ✅ 自动编译原生库
- ✅ 运行代码生成
- ✅ 上传构建产物（保留7天）
- ✅ 生成构建摘要

**构建产物：**
- `windows-build` - Windows可执行程序
- `linux-build` - Linux可执行程序
- `macos-build` - macOS应用包
- `android-apk` - Android APK
- `android-bundle` - Android App Bundle

### 2. release.yml - 自动发布
**触发条件：**
- 推送标签（如 `v1.0.0`）
- 手动触发（可指定版本号）

**功能：**
- ✅ 自动创建GitHub Release
- ✅ 构建所有平台的发布版本
- ✅ 自动压缩打包
- ✅ 上传到Release页面
- ✅ 生成Release说明

**发布文件：**
- `universal_remote_control_windows_v*.zip`
- `universal_remote_control_linux_v*.tar.gz`
- `universal_remote_control_macos_v*.zip`
- `universal_remote_control_v*.apk`

### 3. test.yml - 自动化测试
**触发条件：**
- 推送到 `main` 或 `develop` 分支
- 创建Pull Request

**功能：**
- ✅ 运行Dart单元测试
- ✅ 代码覆盖率分析
- ✅ 静态代码分析
- ✅ 代码格式检查
- ✅ 依赖版本检查

## 🚀 使用方法

### 方式1：自动触发（推荐）

#### 开发过程中
```bash
# 推送代码到main或develop分支，自动触发构建
git push origin main
```

#### 发布新版本
```bash
# 创建并推送版本标签
git tag v1.0.0
git push origin v1.0.0

# 自动触发发布流程，创建Release并上传所有平台的包
```

### 方式2：手动触发

1. 打开GitHub仓库
2. 进入 **Actions** 标签页
3. 选择要运行的工作流
4. 点击 **Run workflow** 按钮
5. （可选）输入参数（如版本号）
6. 点击 **Run workflow** 确认

## 📥 下载构建产物

### 开发构建（build.yml）
1. 进入 **Actions** 标签页
2. 选择一个成功的工作流运行
3. 滚动到底部 **Artifacts** 部分
4. 下载对应平台的构建产物

### 正式发布（release.yml）
1. 进入 **Releases** 标签页
2. 选择对应版本
3. 在 **Assets** 部分下载对应平台的包

## ⚙️ 配置说明

### Flutter版本
所有工作流使用Flutter 3.16.0稳定版。如需修改：

```yaml
- name: 设置Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'  # 修改这里
    channel: 'stable'
```

### 构建产物保留时间
默认保留7天，可修改：

```yaml
- name: 上传构建产物
  uses: actions/upload-artifact@v3
  with:
    name: windows-build
    path: release_windows/
    retention-days: 30  # 修改为30天
```

### 添加签名配置

对于Android，可以添加签名：

```yaml
# 在仓库设置中添加secrets
- name: 解码密钥库
  run: |
    echo "${{ secrets.KEYSTORE }}" | base64 --decode > android/app/key.jks
    
- name: 创建key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=key.jks" >> android/key.properties
```

## 🔐 Secrets配置

某些功能需要配置GitHub Secrets：

### 必需的Secrets
- `GITHUB_TOKEN` - 自动提供，无需配置

### 可选的Secrets（用于Android签名）
- `KEYSTORE` - Base64编码的密钥库文件
- `KEYSTORE_PASSWORD` - 密钥库密码
- `KEY_PASSWORD` - 密钥密码
- `KEY_ALIAS` - 密钥别名

**配置方法：**
1. 进入仓库 **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret**
3. 添加名称和值
4. 保存

## 📊 工作流状态徽章

在README中添加状态徽章：

```markdown
![Build](https://github.com/your-username/universal_remote_control/workflows/Build%20All%20Platforms/badge.svg)
![Tests](https://github.com/your-username/universal_remote_control/workflows/Tests/badge.svg)
```

## 🔧 故障排查

### 构建失败？

1. **检查日志**
   - 进入失败的工作流运行
   - 展开失败的步骤查看详细日志

2. **常见问题**
   
   **Flutter依赖问题：**
   ```bash
   # 本地测试
   flutter pub get
   flutter pub run build_runner build
   ```
   
   **原生库编译失败：**
   ```bash
   # 检查CMake配置
   cd native/windows  # 或 linux/macos
   cmake . -B build
   ```
   
   **代码分析错误：**
   ```bash
   # 本地运行分析
   flutter analyze
   flutter format .
   ```

3. **清理缓存**
   - 手动运行工作流时选择 "Re-run all jobs"
   - 或在工作流中添加清理步骤

### Android构建超时？

增加超时时间：

```yaml
jobs:
  build-android:
    runs-on: ubuntu-latest
    timeout-minutes: 60  # 默认60分钟
```

## 📈 性能优化

### 1. 使用缓存
```yaml
- name: 缓存Flutter依赖
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build
    key: ${{ runner.os }}-flutter-${{ hashFiles('**/pubspec.lock') }}
```

### 2. 并行构建
默认已启用4个平台并行构建，最大化构建速度。

### 3. 增量构建
```yaml
# 保留build目录加速增量构建
- uses: actions/cache@v3
  with:
    path: build
    key: ${{ runner.os }}-build-${{ github.sha }}
    restore-keys: ${{ runner.os }}-build-
```

## 📝 自定义工作流

### 添加新平台

复制现有平台的job并修改：

```yaml
build-ios:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter build ios --release --no-codesign
```

### 添加通知

集成Slack、Discord等：

```yaml
- name: 发送通知
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "构建完成！"
      }
```

## 🆘 获取帮助

- 📖 [GitHub Actions文档](https://docs.github.com/en/actions)
- 📖 [Flutter CI/CD指南](https://flutter.dev/docs/deployment/cd)
- 🐛 [提交Issue](https://github.com/your-username/universal_remote_control/issues)

---

**让GitHub为你自动构建和发布！** 🚀

