#!/bin/bash

# Linux/macOS原生库构建脚本

echo "正在构建原生输入模拟库..."

# 检查CMake
if ! command -v cmake &> /dev/null; then
    echo "错误: 未找到CMake，请先安装CMake"
    echo "Ubuntu/Debian: sudo apt install cmake"
    echo "CentOS/RHEL: sudo yum install cmake"
    echo "macOS: brew install cmake"
    exit 1
fi

# 检查编译器
if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
    echo "错误: 未找到C++编译器"
    echo "Ubuntu/Debian: sudo apt install build-essential"
    echo "CentOS/RHEL: sudo yum groupinstall 'Development Tools'"
    echo "macOS: xcode-select --install"
    exit 1
fi

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    LIB_EXT="so"
    LIB_PREFIX="lib"
    
    # 检查X11开发库
    if ! pkg-config --exists x11 xtst; then
        echo "错误: 未找到X11开发库"
        echo "Ubuntu/Debian: sudo apt install libx11-dev libxtst-dev"
        echo "CentOS/RHEL: sudo yum install libX11-devel libXtst-devel"
        exit 1
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    LIB_EXT="dylib"
    LIB_PREFIX="lib"
else
    echo "错误: 不支持的操作系统: $OSTYPE"
    exit 1
fi

echo "检测到平台: $PLATFORM"

# 创建构建目录
BUILD_DIR="build/$PLATFORM"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# CMake配置
echo "配置CMake项目..."
cmake "../../native/$PLATFORM" -DCMAKE_BUILD_TYPE=Release
if [ $? -ne 0 ]; then
    echo "CMake配置失败"
    exit 1
fi

# 构建项目
echo "构建项目..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
if [ $? -ne 0 ]; then
    echo "构建失败"
    exit 1
fi

# 查找生成的库文件
LIB_NAME="${LIB_PREFIX}input_simulator_${PLATFORM}.${LIB_EXT}"
if [ -f "$LIB_NAME" ]; then
    echo "复制库文件..."
    
    # 复制到Flutter项目目录
    if [[ "$PLATFORM" == "linux" ]]; then
        mkdir -p "../../linux"
        cp "$LIB_NAME" "../../linux/"
    elif [[ "$PLATFORM" == "macos" ]]; then
        mkdir -p "../../macos"
        cp "$LIB_NAME" "../../macos/"
    fi
    
    echo "构建成功！库文件已复制到Flutter项目。"
    echo "生成的库: $LIB_NAME"
else
    echo "警告: 未找到生成的库文件: $LIB_NAME"
    ls -la
fi

cd ../..
echo "完成！"
