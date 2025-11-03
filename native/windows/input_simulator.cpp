#include <windows.h>
#include <iostream>

// 导出函数声明
extern "C" {
    __declspec(dllexport) void mouse_move(int dx, int dy);
    __declspec(dllexport) void mouse_click(int button);
    __declspec(dllexport) void mouse_scroll(int dx, int dy);
    __declspec(dllexport) void key_press(int keycode);
    __declspec(dllexport) void key_down(int keycode);
    __declspec(dllexport) void key_up(int keycode);
}

/**
 * 鼠标移动（相对移动）
 * @param dx X轴移动量
 * @param dy Y轴移动量
 */
void mouse_move(int dx, int dy) {
    INPUT input = {0};
    input.type = INPUT_MOUSE;
    input.mi.dx = dx;
    input.mi.dy = dy;
    input.mi.dwFlags = MOUSEEVENTF_MOVE;
    
    SendInput(1, &input, sizeof(INPUT));
}

/**
 * 鼠标点击
 * @param button 按钮类型 (0=左键, 1=右键, 2=中键)
 */
void mouse_click(int button) {
    INPUT inputs[2] = {0};
    DWORD downFlag, upFlag;
    
    switch (button) {
        case 0: // 左键
            downFlag = MOUSEEVENTF_LEFTDOWN;
            upFlag = MOUSEEVENTF_LEFTUP;
            break;
        case 1: // 右键
            downFlag = MOUSEEVENTF_RIGHTDOWN;
            upFlag = MOUSEEVENTF_RIGHTUP;
            break;
        case 2: // 中键
            downFlag = MOUSEEVENTF_MIDDLEDOWN;
            upFlag = MOUSEEVENTF_MIDDLEUP;
            break;
        default:
            return;
    }
    
    // 按下
    inputs[0].type = INPUT_MOUSE;
    inputs[0].mi.dwFlags = downFlag;
    
    // 释放
    inputs[1].type = INPUT_MOUSE;
    inputs[1].mi.dwFlags = upFlag;
    
    SendInput(2, inputs, sizeof(INPUT));
}

/**
 * 鼠标滚轮
 * @param dx 水平滚动量（不常用）
 * @param dy 垂直滚动量（正值向上滚动，负值向下滚动）
 */
void mouse_scroll(int dx, int dy) {
    if (dy != 0) {
        INPUT input = {0};
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = MOUSEEVENTF_WHEEL;
        input.mi.mouseData = dy * WHEEL_DELTA;
        
        SendInput(1, &input, sizeof(INPUT));
    }
    
    // Windows也支持水平滚轮
    if (dx != 0) {
        INPUT input = {0};
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = MOUSEEVENTF_HWHEEL;
        input.mi.mouseData = dx * WHEEL_DELTA;
        
        SendInput(1, &input, sizeof(INPUT));
    }
}

/**
 * 键盘按键（按下并释放）
 * @param keycode 虚拟键码
 */
void key_press(int keycode) {
    key_down(keycode);
    Sleep(10); // 短暂延迟
    key_up(keycode);
}

/**
 * 键盘按下
 * @param keycode 虚拟键码
 */
void key_down(int keycode) {
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = keycode;
    input.ki.dwFlags = 0; // 0表示按下
    
    SendInput(1, &input, sizeof(INPUT));
}

/**
 * 键盘释放
 * @param keycode 虚拟键码
 */
void key_up(int keycode) {
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = keycode;
    input.ki.dwFlags = KEYEVENTF_KEYUP;
    
    SendInput(1, &input, sizeof(INPUT));
}

// DLL入口点
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}

