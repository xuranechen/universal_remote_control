@echo off
REM ========================================
REM Universal Remote Control - Android打包脚本
REM ========================================

echo ========================================
echo Android APK 一键打包
echo ========================================
echo.

REM 检查Flutter是否安装
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到Flutter，请先安装Flutter SDK
    pause
    exit /b 1
)

echo [1/4] 清理旧的构建文件...
if exist build\app rmdir /s /q build\app
echo.

echo [2/4] 安装Flutter依赖...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter依赖安装失败
    pause
    exit /b 1
)
echo.

echo [3/4] 生成代码文件...
call flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 代码生成失败
    pause
    exit /b 1
)
echo.

echo [4/4] 编译Android APK...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [错误] APK编译失败
    pause
    exit /b 1
)
echo.

echo ========================================
echo 打包完成！
echo ========================================
echo.
echo APK位置: build\app\outputs\flutter-apk\app-release.apk
echo.

REM 获取APK文件大小
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do set size=%%~zA
set /a sizeMB=%size% / 1048576
echo APK大小: %sizeMB% MB
echo.

REM 创建发布包
set RELEASE_DIR=release_android_%date:~0,4%%date:~5,2%%date:~8,2%
mkdir %RELEASE_DIR%
copy build\app\outputs\flutter-apk\app-release.apk %RELEASE_DIR%\UniversalRemoteControl.apk
copy README.md %RELEASE_DIR%\
copy QUICKSTART.md %RELEASE_DIR%\

echo 发布包已创建: %RELEASE_DIR%
echo.
echo 可以通过以下方式安装APK:
echo   1. 将APK传输到Android设备并安装
echo   2. 使用adb安装: adb install %RELEASE_DIR%\UniversalRemoteControl.apk
echo.

pause

