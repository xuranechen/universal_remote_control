# Windows 输入模拟库

## 编译说明

### 环境要求
- Visual Studio 2019 或更高版本
- CMake 3.15+
- Windows SDK

### 编译步骤

```bash
# 创建构建目录
mkdir build
cd build

# 生成Visual Studio项目
cmake ..

# 编译
cmake --build . --config Release

# 编译后的DLL位于 build/bin/Release/input_simulator_windows.dll
```

### 手动使用Visual Studio编译

1. 打开 `input_simulator.cpp`
2. 创建新的DLL项目
3. 添加源文件
4. 项目设置：
   - 配置类型：动态库(.dll)
   - 链接器 -> 输入 -> 附加依赖项：添加 `user32.lib`
5. 编译

## 使用说明

编译完成后，将 `input_simulator_windows.dll` 复制到Flutter项目的运行目录，或者系统PATH路径下。

## API说明

### mouse_move(int dx, int dy)
相对移动鼠标

### mouse_click(int button)
点击鼠标按钮
- button: 0=左键, 1=右键, 2=中键

### mouse_scroll(int dx, int dy)
滚动鼠标滚轮
- dx: 水平滚动量
- dy: 垂直滚动量（正值向上，负值向下）

### key_press(int keycode)
按下并释放按键

### key_down(int keycode)
按下按键

### key_up(int keycode)
释放按键

## 虚拟键码参考

常用键码（Windows Virtual-Key Codes）:
- A-Z: 0x41-0x5A
- 0-9: 0x30-0x39
- F1-F12: 0x70-0x7B
- Enter: 0x0D
- Escape: 0x1B
- Space: 0x20
- Shift: 0x10
- Ctrl: 0x11
- Alt: 0x12

完整列表参考: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes

