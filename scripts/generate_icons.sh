#!/bin/bash

# Universal Remote Control - 图标生成脚本 (Linux/macOS)
# 自动生成所有平台的应用图标

echo "========================================"
echo " Universal Remote Control"
echo " 图标生成工具"
echo "========================================"
echo ""

# 检查是否存在图标文件
if [ ! -f "assets/icon/app_icon.png" ]; then
    echo "[错误] 未找到图标文件！"
    echo ""
    echo "请先准备图标文件："
    echo "  - assets/icon/app_icon.png (1024x1024px)"
    echo "  - assets/icon/app_icon_foreground.png (可选，Android自适应图标)"
    echo ""
    echo "快速生成图标的方法："
    echo "1. 访问 https://www.appicon.co/"
    echo "2. 使用'Text to Icon'功能，输入 URC 或表情符号"
    echo "3. 选择蓝色背景 #2196F3"
    echo "4. 下载1024x1024版本并保存到 assets/icon/"
    echo ""
    echo "详细说明请查看："
    echo "  - assets/icon/README.md"
    echo ""
    exit 1
fi

echo "[1/4] 检查Flutter环境..."
if ! command -v flutter &> /dev/null; then
    echo "[错误] Flutter未安装或未添加到PATH"
    exit 1
fi
echo "[✓] Flutter环境正常"
echo ""

echo "[2/4] 安装依赖包..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "[错误] 依赖安装失败"
    exit 1
fi
echo "[✓] 依赖安装完成"
echo ""

echo "[3/4] 生成应用图标..."
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo "[错误] 图标生成失败"
    exit 1
fi
echo "[✓] 图标生成完成"
echo ""

echo "[4/4] 验证生成结果..."
echo ""
echo "生成的图标位置："
echo "  Android: android/app/src/main/res/mipmap-*/"
echo "  iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "  Windows: windows/runner/resources/"
echo "  Linux: linux/"
echo "  macOS: macos/Runner/Assets.xcassets/AppIcon.appiconset/"
echo ""

echo "========================================"
echo " 图标生成成功！✓"
echo "========================================"
echo ""
echo "下一步："
echo "1. 清理构建缓存：flutter clean"
echo "2. 重新构建应用：flutter build apk (或其他平台)"
echo "3. 安装应用查看新图标"
echo ""
echo "如需修改图标，请："
echo "1. 替换 assets/icon/ 下的图标文件"
echo "2. 重新运行本脚本"
echo ""

