# macOS 输入模拟库

## 环境要求

- macOS 10.12 或更高版本
- Xcode Command Line Tools
- CMake 3.15+

安装Command Line Tools：
```bash
xcode-select --install
```

## 编译说明

```bash
# 创建构建目录
mkdir build
cd build

# 配置和编译
cmake ..
make

# 编译后的库位于 build/lib/libinput_simulator_macos.dylib
```

## 权限设置

⚠️ **重要**: macOS对输入模拟有严格的权限要求。

### 授予辅助功能权限

1. 打开 **系统偏好设置** > **安全性与隐私** > **隐私** 选项卡
2. 选择左侧的 **辅助功能**
3. 点击左下角的锁图标解锁设置
4. 将您的应用程序添加到列表中，或者勾选终端/iTerm等应用

### 程序化检查权限

可以使用以下代码检查权限：

```cpp
#include <ApplicationServices/ApplicationServices.h>

bool checkAccessibilityPermission() {
    NSDictionary* options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    bool accessibilityEnabled = AXIsProcessTrustedWithOptions(
        (__bridge CFDictionaryRef)options
    );
    return accessibilityEnabled;
}
```

## 使用说明

编译完成后，将 `libinput_simulator_macos.dylib` 复制到Flutter项目的运行目录。

```bash
# 查看动态库依赖
otool -L libinput_simulator_macos.dylib

# 如果需要，可以更改库的搜索路径
install_name_tool -id @rpath/libinput_simulator_macos.dylib libinput_simulator_macos.dylib
```

## API说明

与Windows/Linux版本相同的API接口。

## 键码参考

macOS使用CGKeyCode：

常用键码：
```
A-Z:     0-25 (对应kVK_ANSI_A到kVK_ANSI_Z)
0-9:     29, 18-26 (数字键)
F1-F12:  122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111
Return:  36
Escape:  53
Space:   49
Tab:     48
Delete:  51
```

完整键码列表在 `/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h`

或者参考：https://eastmanreference.com/complete-list-of-applescript-key-codes

## 常见问题

### Q: 权限提示不出现？
A: 使用以下命令重置权限数据库：
```bash
tccutil reset Accessibility
```

### Q: 编译时找不到框架？
A: 确保Xcode Command Line Tools已正确安装：
```bash
xcode-select -p
```

### Q: 运行时提示库找不到？
A: 检查库的搜索路径，或设置环境变量：
```bash
export DYLD_LIBRARY_PATH=/path/to/lib:$DYLD_LIBRARY_PATH
```

