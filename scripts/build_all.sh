#!/bin/bash

# ========================================
# Universal Remote Control - Linux/macOS一键打包脚本
# ========================================

set -e  # 遇到错误立即退出

echo "========================================"
echo "Universal Remote Control 一键打包"
echo "========================================"
echo ""

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    LIB_NAME="libinput_simulator_linux.so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    LIB_NAME="libinput_simulator_macos.dylib"
else
    echo "[错误] 不支持的操作系统: $OSTYPE"
    exit 1
fi

echo "检测到平台: $PLATFORM"
echo ""

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "[错误] 未找到Flutter，请先安装Flutter SDK"
    exit 1
fi

# 检查CMake是否安装
if ! command -v cmake &> /dev/null; then
    echo "[错误] 未找到CMake，请先安装CMake"
    exit 1
fi

# Linux特定依赖检查
if [[ "$PLATFORM" == "linux" ]]; then
    echo "检查Linux依赖..."
    if ! dpkg -l | grep -q libx11-dev; then
        echo "[警告] 未检测到libx11-dev，可能需要安装："
        echo "  sudo apt-get install libx11-dev libxtst-dev libxext-dev"
    fi
fi

echo "[1/6] 检查并添加${PLATFORM}桌面支持..."
if [ ! -d "$PLATFORM" ]; then
    echo "未找到${PLATFORM}目录，正在添加${PLATFORM}桌面支持..."
    flutter create --platforms=$PLATFORM .
    if [ $? -ne 0 ]; then
        echo "[错误] 添加${PLATFORM}桌面支持失败"
        exit 1
    fi
    echo "${PLATFORM}桌面支持已添加"
else
    echo "${PLATFORM}桌面支持已存在"
fi
echo ""

echo "[2/6] 清理旧的构建文件..."
rm -rf build
rm -rf native/$PLATFORM/build
echo ""

echo "[3/6] 安装Flutter依赖..."
flutter pub get
echo ""

echo "[4/6] 生成代码文件..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

echo "[5/6] 编译${PLATFORM}原生库..."
cd native/$PLATFORM
mkdir -p build
cd build
cmake ..
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# 复制库文件到项目根目录
cp lib/$LIB_NAME ../../..
cd ../../..
echo ""

echo "[6/6] 编译Flutter应用..."
flutter build $PLATFORM --release
echo ""

echo "========================================"
echo "打包完成！"
echo "========================================"
echo ""

if [[ "$PLATFORM" == "linux" ]]; then
    OUTPUT_DIR="build/linux/x64/release/bundle"
    echo "输出位置: $OUTPUT_DIR"
    echo ""
    echo "包含文件:"
    ls -lh $OUTPUT_DIR
    echo ""
    
    # 创建发布包
    RELEASE_DIR="release_linux_$(date +%Y%m%d)"
    echo "正在创建发布包..."
    mkdir -p $RELEASE_DIR
    cp -r $OUTPUT_DIR/* $RELEASE_DIR/
    cp README.md $RELEASE_DIR/
    cp QUICKSTART.md $RELEASE_DIR/
    
    # 创建启动脚本
    cat > $RELEASE_DIR/run.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
./universal_remote_control
EOF
    chmod +x $RELEASE_DIR/run.sh
    
    echo ""
    echo "发布包已创建: $RELEASE_DIR"
    echo "运行: cd $RELEASE_DIR && ./run.sh"
    
elif [[ "$PLATFORM" == "macos" ]]; then
    OUTPUT_DIR="build/macos/Build/Products/Release"
    echo "输出位置: $OUTPUT_DIR"
    echo ""
    echo "包含文件:"
    ls -lh $OUTPUT_DIR
    echo ""
    
    # 创建发布包
    RELEASE_DIR="release_macos_$(date +%Y%m%d)"
    echo "正在创建发布包..."
    mkdir -p $RELEASE_DIR
    cp -r $OUTPUT_DIR/universal_remote_control.app $RELEASE_DIR/
    cp README.md $RELEASE_DIR/
    cp QUICKSTART.md $RELEASE_DIR/
    
    echo ""
    echo "发布包已创建: $RELEASE_DIR"
    echo "运行: open $RELEASE_DIR/universal_remote_control.app"
fi

echo ""
echo "可以将 $RELEASE_DIR 文件夹压缩后分发"

