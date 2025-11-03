#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <X11/keysym.h>
#include <unistd.h>
#include <iostream>

// 全局Display指针
static Display* display = nullptr;

// 初始化函数
static void ensure_display() {
    if (display == nullptr) {
        display = XOpenDisplay(nullptr);
        if (display == nullptr) {
            std::cerr << "无法打开X Display" << std::endl;
        }
    }
}

extern "C" {
    __attribute__((visibility("default")))
    void mouse_move(int dx, int dy);
    
    __attribute__((visibility("default")))
    void mouse_click(int button);
    
    __attribute__((visibility("default")))
    void mouse_scroll(int dx, int dy);
    
    __attribute__((visibility("default")))
    void key_press(int keycode);
    
    __attribute__((visibility("default")))
    void key_down(int keycode);
    
    __attribute__((visibility("default")))
    void key_up(int keycode);
}

/**
 * 鼠标移动（相对移动）
 * @param dx X轴移动量
 * @param dy Y轴移动量
 */
void mouse_move(int dx, int dy) {
    ensure_display();
    if (display == nullptr) return;
    
    // 获取当前鼠标位置
    Window root, child;
    int root_x, root_y, win_x, win_y;
    unsigned int mask;
    
    XQueryPointer(display, DefaultRootWindow(display),
                  &root, &child, &root_x, &root_y, &win_x, &win_y, &mask);
    
    // 移动到新位置
    XTestFakeMotionEvent(display, -1, root_x + dx, root_y + dy, CurrentTime);
    XFlush(display);
}

/**
 * 鼠标点击
 * @param button 按钮类型 (0=左键, 1=右键, 2=中键)
 */
void mouse_click(int button) {
    ensure_display();
    if (display == nullptr) return;
    
    // X11按钮编号: 1=左键, 3=右键, 2=中键
    int x11_button;
    switch (button) {
        case 0: x11_button = 1; break; // 左键
        case 1: x11_button = 3; break; // 右键
        case 2: x11_button = 2; break; // 中键
        default: return;
    }
    
    // 按下
    XTestFakeButtonEvent(display, x11_button, True, CurrentTime);
    XFlush(display);
    
    // 短暂延迟
    usleep(10000); // 10ms
    
    // 释放
    XTestFakeButtonEvent(display, x11_button, False, CurrentTime);
    XFlush(display);
}

/**
 * 鼠标滚轮
 * @param dx 水平滚动量
 * @param dy 垂直滚动量（正值向上滚动，负值向下滚动）
 */
void mouse_scroll(int dx, int dy) {
    ensure_display();
    if (display == nullptr) return;
    
    // X11使用按钮4和5来表示滚轮
    // 按钮4 = 向上滚动
    // 按钮5 = 向下滚动
    
    if (dy > 0) {
        // 向上滚动
        for (int i = 0; i < dy; i++) {
            XTestFakeButtonEvent(display, 4, True, CurrentTime);
            XTestFakeButtonEvent(display, 4, False, CurrentTime);
        }
    } else if (dy < 0) {
        // 向下滚动
        for (int i = 0; i < -dy; i++) {
            XTestFakeButtonEvent(display, 5, True, CurrentTime);
            XTestFakeButtonEvent(display, 5, False, CurrentTime);
        }
    }
    
    // 水平滚动（按钮6和7）
    if (dx > 0) {
        for (int i = 0; i < dx; i++) {
            XTestFakeButtonEvent(display, 6, True, CurrentTime);
            XTestFakeButtonEvent(display, 6, False, CurrentTime);
        }
    } else if (dx < 0) {
        for (int i = 0; i < -dx; i++) {
            XTestFakeButtonEvent(display, 7, True, CurrentTime);
            XTestFakeButtonEvent(display, 7, False, CurrentTime);
        }
    }
    
    XFlush(display);
}

/**
 * 键盘按键（按下并释放）
 * @param keycode 键码
 */
void key_press(int keycode) {
    key_down(keycode);
    usleep(10000); // 10ms延迟
    key_up(keycode);
}

/**
 * 键盘按下
 * @param keycode 键码
 */
void key_down(int keycode) {
    ensure_display();
    if (display == nullptr) return;
    
    // 将虚拟键码转换为X11键码
    KeyCode xkeycode = XKeysymToKeycode(display, keycode);
    if (xkeycode == 0) {
        // 如果转换失败，尝试直接使用
        xkeycode = keycode;
    }
    
    XTestFakeKeyEvent(display, xkeycode, True, CurrentTime);
    XFlush(display);
}

/**
 * 键盘释放
 * @param keycode 键码
 */
void key_up(int keycode) {
    ensure_display();
    if (display == nullptr) return;
    
    // 将虚拟键码转换为X11键码
    KeyCode xkeycode = XKeysymToKeycode(display, keycode);
    if (xkeycode == 0) {
        xkeycode = keycode;
    }
    
    XTestFakeKeyEvent(display, xkeycode, False, CurrentTime);
    XFlush(display);
}

// 库析构函数
__attribute__((destructor))
static void cleanup() {
    if (display != nullptr) {
        XCloseDisplay(display);
        display = nullptr;
    }
}

