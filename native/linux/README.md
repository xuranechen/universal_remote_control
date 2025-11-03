# Linux 输入模拟库

## 环境要求

### 依赖包
```bash
# Ubuntu/Debian
sudo apt-get install -y \
    build-essential \
    cmake \
    libx11-dev \
    libxtst-dev \
    libxext-dev

# Fedora/RHEL
sudo dnf install -y \
    gcc-c++ \
    cmake \
    libX11-devel \
    libXtst-devel \
    libXext-devel

# Arch Linux
sudo pacman -S \
    base-devel \
    cmake \
    libx11 \
    libxtst \
    libxext
```

## 编译说明

```bash
# 创建构建目录
mkdir build
cd build

# 配置和编译
cmake ..
make

# 编译后的库位于 build/lib/libinput_simulator_linux.so
```

## 使用说明

编译完成后，将 `libinput_simulator_linux.so` 复制到Flutter项目的运行目录，或者添加到系统库路径：

```bash
# 临时添加到库路径
export LD_LIBRARY_PATH=/path/to/lib:$LD_LIBRARY_PATH

# 或者复制到系统库目录
sudo cp libinput_simulator_linux.so /usr/local/lib/
sudo ldconfig
```

## 注意事项

### X11 vs Wayland
此库基于X11实现。如果您使用Wayland桌面环境，需要：

1. 确保XWayland已安装
2. 或者切换到X11会话

检查当前会话类型：
```bash
echo $XDG_SESSION_TYPE
```

### 权限问题
某些Linux发行版可能需要特殊权限才能模拟输入。如果遇到权限问题：

```bash
# 将用户添加到input组
sudo usermod -a -G input $USER

# 重新登录使更改生效
```

## API说明

与Windows版本相同的API接口。

## 键码参考

Linux使用X11 KeySym：
- 字母: XK_a (0x61) 到 XK_z (0x7A)
- 数字: XK_0 (0x30) 到 XK_9 (0x39)
- 功能键: XK_F1 (0xFFBE) 到 XK_F12 (0xFFC9)
- 特殊键: 
  - Enter: XK_Return (0xFF0D)
  - Escape: XK_Escape (0xFF1B)
  - Space: XK_space (0x20)

完整列表参考: `/usr/include/X11/keysymdef.h`

