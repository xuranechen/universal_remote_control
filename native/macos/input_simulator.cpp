#include <ApplicationServices/ApplicationServices.h>
#include <CoreGraphics/CoreGraphics.h>
#include <unistd.h>
#include <iostream>

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
    // 获取当前鼠标位置
    CGEventRef event = CGEventCreate(nullptr);
    CGPoint cursor = CGEventGetLocation(event);
    CFRelease(event);
    
    // 计算新位置
    CGPoint newPoint = CGPointMake(cursor.x + dx, cursor.y + dy);
    
    // 创建鼠标移动事件
    CGEventRef moveEvent = CGEventCreateMouseEvent(
        nullptr,
        kCGEventMouseMoved,
        newPoint,
        kCGMouseButtonLeft
    );
    
    // 发送事件
    CGEventPost(kCGHIDEventTap, moveEvent);
    CFRelease(moveEvent);
}

/**
 * 鼠标点击
 * @param button 按钮类型 (0=左键, 1=右键, 2=中键)
 */
void mouse_click(int button) {
    // 获取当前鼠标位置
    CGEventRef event = CGEventCreate(nullptr);
    CGPoint cursor = CGEventGetLocation(event);
    CFRelease(event);
    
    CGEventType downType, upType;
    CGMouseButton mouseButton;
    
    switch (button) {
        case 0: // 左键
            downType = kCGEventLeftMouseDown;
            upType = kCGEventLeftMouseUp;
            mouseButton = kCGMouseButtonLeft;
            break;
        case 1: // 右键
            downType = kCGEventRightMouseDown;
            upType = kCGEventRightMouseUp;
            mouseButton = kCGMouseButtonRight;
            break;
        case 2: // 中键
            downType = kCGEventOtherMouseDown;
            upType = kCGEventOtherMouseUp;
            mouseButton = kCGMouseButtonCenter;
            break;
        default:
            return;
    }
    
    // 创建按下事件
    CGEventRef downEvent = CGEventCreateMouseEvent(
        nullptr,
        downType,
        cursor,
        mouseButton
    );
    
    // 创建释放事件
    CGEventRef upEvent = CGEventCreateMouseEvent(
        nullptr,
        upType,
        cursor,
        mouseButton
    );
    
    // 发送事件
    CGEventPost(kCGHIDEventTap, downEvent);
    usleep(10000); // 10ms延迟
    CGEventPost(kCGHIDEventTap, upEvent);
    
    CFRelease(downEvent);
    CFRelease(upEvent);
}

/**
 * 鼠标滚轮
 * @param dx 水平滚动量
 * @param dy 垂直滚动量（正值向上滚动，负值向下滚动）
 */
void mouse_scroll(int dx, int dy) {
    // macOS的滚轮事件
    // 注意：dy的方向在macOS中可能需要反转
    CGEventRef scrollEvent = CGEventCreateScrollWheelEvent(
        nullptr,
        kCGScrollEventUnitLine,
        2, // 滚轮数量（垂直和水平）
        dy, // 垂直滚动
        dx  // 水平滚动
    );
    
    CGEventPost(kCGHIDEventTap, scrollEvent);
    CFRelease(scrollEvent);
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
 * @param keycode 键码（CGKeyCode）
 */
void key_down(int keycode) {
    CGEventRef keyDownEvent = CGEventCreateKeyboardEvent(
        nullptr,
        (CGKeyCode)keycode,
        true
    );
    
    CGEventPost(kCGHIDEventTap, keyDownEvent);
    CFRelease(keyDownEvent);
}

/**
 * 键盘释放
 * @param keycode 键码（CGKeyCode）
 */
void key_up(int keycode) {
    CGEventRef keyUpEvent = CGEventCreateKeyboardEvent(
        nullptr,
        (CGKeyCode)keycode,
        false
    );
    
    CGEventPost(kCGHIDEventTap, keyUpEvent);
    CFRelease(keyUpEvent);
}

