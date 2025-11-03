#!/bin/bash

# ========================================
# Universal Remote Control - Android打包脚本
# ========================================

set -e

echo "========================================"
echo "Android APK 一键打包"
echo "========================================"
echo ""

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "[错误] 未找到Flutter，请先安装Flutter SDK"
    exit 1
fi

echo "[1/4] 清理旧的构建文件..."
rm -rf build/app
echo ""

echo "[2/4] 安装Flutter依赖..."
flutter pub get
echo ""

echo "[3/4] 生成代码文件..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

echo "[4/4] 编译Android APK..."
flutter build apk --release
echo ""

echo "========================================"
echo "打包完成！"
echo "========================================"
echo ""

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
echo "APK位置: $APK_PATH"
echo ""

# 获取APK文件大小
if [[ -f "$APK_PATH" ]]; then
    SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
    echo "APK大小: $SIZE"
    echo ""
fi

# 创建发布包
RELEASE_DIR="release_android_$(date +%Y%m%d)"
echo "正在创建发布包..."
mkdir -p $RELEASE_DIR
cp $APK_PATH $RELEASE_DIR/UniversalRemoteControl.apk
cp README.md $RELEASE_DIR/
cp QUICKSTART.md $RELEASE_DIR/

echo ""
echo "发布包已创建: $RELEASE_DIR"
echo ""
echo "可以通过以下方式安装APK:"
echo "  1. 将APK传输到Android设备并安装"
echo "  2. 使用adb安装: adb install $RELEASE_DIR/UniversalRemoteControl.apk"
echo ""

