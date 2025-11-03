@echo off
REM Windows原生库构建脚本

echo 正在构建Windows原生输入模拟库...

REM 检查CMake是否存在
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到CMake，请先安装CMake
    echo 下载地址: https://cmake.org/download/
    pause
    exit /b 1
)

REM 检查Visual Studio Build Tools
where cl >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到Visual Studio编译器
    echo 请安装Visual Studio或Visual Studio Build Tools
    echo 或运行Developer Command Prompt
    pause
    exit /b 1
)

REM 创建构建目录
if not exist "build\windows" mkdir build\windows
cd build\windows

REM CMake配置
echo 配置CMake项目...
cmake ..\..\native\windows -G "Visual Studio 16 2019" -A x64
if %errorlevel% neq 0 (
    echo CMake配置失败
    pause
    exit /b 1
)

REM 构建项目
echo 构建项目...
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo 构建失败
    pause
    exit /b 1
)

REM 复制DLL到Flutter项目
if exist "Release\input_simulator_windows.dll" (
    echo 复制DLL文件...
    copy "Release\input_simulator_windows.dll" "..\..\windows\runner\" >nul
    copy "Release\input_simulator_windows.dll" "..\..\build\windows\runner\Release\" >nul 2>&1
    copy "Release\input_simulator_windows.dll" "..\..\build\windows\runner\Debug\" >nul 2>&1
    echo 构建成功！DLL已复制到Flutter项目。
) else (
    echo 警告: 未找到生成的DLL文件
)

cd ..\..
pause
