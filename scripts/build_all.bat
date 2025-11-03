@echo off
REM ========================================
REM Universal Remote Control - Windows一键打包脚本
REM ========================================

echo ========================================
echo Universal Remote Control 一键打包
echo ========================================
echo.

REM 检查Flutter是否安装
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到Flutter，请先安装Flutter SDK
    pause
    exit /b 1
)

REM 检查CMake是否安装
where cmake >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到CMake，请先安装CMake
    pause
    exit /b 1
)

echo [1/5] 清理旧的构建文件...
if exist build rmdir /s /q build
if exist native\windows\build rmdir /s /q native\windows\build
echo.

echo [2/5] 安装Flutter依赖...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter依赖安装失败
    pause
    exit /b 1
)
echo.

echo [3/5] 生成代码文件...
call flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 代码生成失败
    pause
    exit /b 1
)
echo.

echo [4/5] 编译Windows原生库...
cd native\windows
mkdir build
cd build
cmake .. -A x64
if %ERRORLEVEL% NEQ 0 (
    echo [错误] CMake配置失败
    cd ..\..\..
    pause
    exit /b 1
)

cmake --build . --config Release
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 原生库编译失败
    cd ..\..\..
    pause
    exit /b 1
)

REM 复制DLL到项目根目录
copy Release\input_simulator_windows.dll ..\..\..
cd ..\..\..
echo.

echo [5/5] 编译Flutter应用...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [错误] Flutter应用编译失败
    pause
    exit /b 1
)
echo.

echo ========================================
echo 打包完成！
echo ========================================
echo.
echo 输出位置: build\windows\runner\Release\
echo.
echo 包含文件:
dir /b build\windows\runner\Release\
echo.
echo 可以直接运行: build\windows\runner\Release\universal_remote_control.exe
echo.

REM 创建发布包
echo 正在创建发布包...
set RELEASE_DIR=release_windows_%date:~0,4%%date:~5,2%%date:~8,2%
mkdir %RELEASE_DIR%
xcopy /E /I /Y build\windows\runner\Release\* %RELEASE_DIR%\
copy README.md %RELEASE_DIR%\
copy QUICKSTART.md %RELEASE_DIR%\

echo.
echo 发布包已创建: %RELEASE_DIR%
echo 可以将此文件夹压缩后分发

pause

