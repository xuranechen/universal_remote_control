# 更新日志

## [未发布] - 2025-11-03

### 修复

#### 🔧 修复GitHub Actions Windows构建失败问题

**问题描述**:
- Windows构建失败，错误信息："No Windows desktop project configured"
- 缺少Flutter标准的桌面平台支持配置

**解决方案**:
- ✅ 在所有GitHub Actions工作流中添加平台支持初始化步骤
- ✅ 更新构建脚本（`build_all.bat` 和 `build_all.sh`），自动检查并添加桌面支持
- ✅ 更新BUILD_GUIDE.md文档，添加详细的平台支持配置说明

**影响的文件**:
- `.github/workflows/build.yml` - 新增完整的多平台构建工作流
- `.github/workflows/release.yml` - 新增自动发布工作流
- `.github/workflows/test.yml` - 新增测试工作流
- `scripts/build_all.bat` - 添加Windows桌面支持自动配置
- `scripts/build_all.sh` - 添加Linux/macOS桌面支持自动配置
- `docs/BUILD_GUIDE.md` - 添加常见问题Q1和详细说明

**关键修复点**:

在构建之前添加以下步骤：
```bash
# Windows
flutter create --platforms=windows .

# Linux
flutter create --platforms=linux .

# macOS
flutter create --platforms=macos .
```

这会创建必要的平台目录结构：
- `windows/` - Flutter Windows应用框架
- `linux/` - Flutter Linux应用框架
- `macos/` - Flutter macOS应用框架

**注意事项**:
- `native/` 目录中的原生C++库是独立的，不受影响
- 首次克隆项目后，必须先运行 `flutter create --platforms=<平台> .`
- GitHub Actions工作流会自动执行此步骤

### 新增

#### 📦 GitHub Actions 完整CI/CD配置

**构建工作流** (`build.yml`):
- ✅ 支持Windows、Linux、macOS、Android四个平台
- ✅ 自动并行构建所有平台
- ✅ 构建产物保留7天
- ✅ 触发条件：推送到main/develop分支、Pull Request、手动触发

**发布工作流** (`release.yml`):
- ✅ 自动创建GitHub Release
- ✅ 自动构建并上传所有平台的安装包
- ✅ 支持版本标签触发或手动触发
- ✅ 自动生成发布说明

**测试工作流** (`test.yml`):
- ✅ 自动运行单元测试
- ✅ 代码格式检查
- ✅ 静态代码分析
- ✅ 代码覆盖率报告（支持Codecov集成）
- ✅ 依赖安全检查

#### 📝 文档改进

**BUILD_GUIDE.md**:
- ✅ 添加"添加桌面平台支持"章节（重要！）
- ✅ 新增Q1：详细说明"No Windows desktop project configured"错误及解决方案
- ✅ 更新所有问题编号

**构建脚本改进**:
- ✅ 自动检测并添加缺失的平台支持
- ✅ 更清晰的步骤提示（1/6到6/6）
- ✅ 更好的错误处理

### 使用说明

#### 本地开发

首次克隆项目后：
```bash
cd universal_remote_control

# 添加所需平台支持
flutter create --platforms=windows,linux,macos .

# 然后正常构建
./scripts/build_all.bat  # Windows
./scripts/build_all.sh   # Linux/macOS
```

#### GitHub Actions

只需推送代码到GitHub，工作流会自动：
1. 检测并添加平台支持
2. 编译原生库
3. 构建Flutter应用
4. 上传构建产物

发布新版本：
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions会自动创建Release并上传所有平台的安装包
```

### 技术细节

**Windows构建步骤**:
1. 检查并添加Windows桌面支持（`flutter create --platforms=windows .`）
2. 获取Flutter依赖（`flutter pub get`）
3. 运行代码生成（`build_runner`）
4. 编译Windows原生库（CMake + Visual Studio）
5. 复制DLL到项目根目录
6. 构建Flutter Windows应用（`flutter build windows --release`）

**Linux构建步骤**:
1. 安装系统依赖（GTK3、CMake等）
2. 检查并添加Linux桌面支持（`flutter create --platforms=linux .`）
3. 获取Flutter依赖
4. 运行代码生成
5. 编译Linux原生库（CMake + Make）
6. 复制.so到项目根目录
7. 构建Flutter Linux应用（`flutter build linux --release`）

**macOS构建步骤**:
1. 检查并添加macOS桌面支持（`flutter create --platforms=macos .`）
2. 获取Flutter依赖
3. 运行代码生成
4. 编译macOS原生库（CMake + Make）
5. 复制.dylib到项目根目录
6. 构建Flutter macOS应用（`flutter build macos --release`）

**Android构建步骤**:
1. 设置Java环境（Java 17）
2. 获取Flutter依赖
3. 运行代码生成
4. 构建APK和AAB（`flutter build apk/appbundle --release`）

### 相关链接

- [构建指南](docs/BUILD_GUIDE.md)
- [GitHub Actions指南](docs/GITHUB_ACTIONS_GUIDE.md)
- [快速入门](QUICKSTART.md)
- [Flutter桌面支持官方文档](https://docs.flutter.dev/desktop)

---

## [1.0.0] - 待发布

### 初始版本

- 🎮 跨平台远程控制（Windows/Linux/macOS/Android）
- 📱 虚拟触摸板
- 🎯 陀螺仪控制
- ⌨️ 键盘和鼠标模拟
- 🌐 基于WebSocket的实时通信
- 🔍 自动设备发现

