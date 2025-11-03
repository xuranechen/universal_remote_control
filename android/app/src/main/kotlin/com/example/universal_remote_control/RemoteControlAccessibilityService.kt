package com.example.universal_remote_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * 远程控制无障碍服务
 * 用于模拟触摸、点击等输入操作
 */
class RemoteControlAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "RemoteControlA11yService"
        private var instance: RemoteControlAccessibilityService? = null

        fun getInstance(): RemoteControlAccessibilityService? {
            return instance
        }

        fun isServiceEnabled(): Boolean {
            return instance != null
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "无障碍服务已连接")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // 我们不需要监听事件，只需要使用服务的功能
    }

    override fun onInterrupt() {
        Log.w(TAG, "无障碍服务被中断")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.i(TAG, "无障碍服务已销毁")
    }

    /**
     * 执行点击操作
     * @param x X坐标
     * @param y Y坐标
     * @param duration 点击持续时间（毫秒）
     */
    fun performClick(x: Float, y: Float, duration: Long = 100): Boolean {
        val path = Path()
        path.moveTo(x, y)

        val gestureBuilder = GestureDescription.Builder()
        gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, duration))

        val gesture = gestureBuilder.build()

        return dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                Log.d(TAG, "点击完成: ($x, $y)")
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                Log.w(TAG, "点击被取消: ($x, $y)")
            }
        }, null)
    }

    /**
     * 执行滑动操作
     * @param x1 起始X坐标
     * @param y1 起始Y坐标
     * @param x2 结束X坐标
     * @param y2 结束Y坐标
     * @param duration 滑动持续时间（毫秒）
     */
    fun performSwipe(
        x1: Float, y1: Float,
        x2: Float, y2: Float,
        duration: Long = 300
    ): Boolean {
        val path = Path()
        path.moveTo(x1, y1)
        path.lineTo(x2, y2)

        val gestureBuilder = GestureDescription.Builder()
        gestureBuilder.addStroke(GestureDescription.StrokeDescription(path, 0, duration))

        val gesture = gestureBuilder.build()

        return dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                Log.d(TAG, "滑动完成: ($x1, $y1) -> ($x2, $y2)")
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                Log.w(TAG, "滑动被取消")
            }
        }, null)
    }

    /**
     * 执行长按操作
     * @param x X坐标
     * @param y Y坐标
     * @param duration 长按持续时间（毫秒）
     */
    fun performLongPress(x: Float, y: Float, duration: Long = 1000): Boolean {
        return performClick(x, y, duration)
    }

    /**
     * 执行返回操作
     */
    fun performBack(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_BACK)
    }

    /**
     * 执行Home操作
     */
    fun performHome(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_HOME)
    }

    /**
     * 执行最近任务操作
     */
    fun performRecents(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_RECENTS)
    }

    /**
     * 执行通知栏操作
     */
    fun performNotifications(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
    }

    /**
     * 执行快速设置操作
     */
    fun performQuickSettings(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
    }

    /**
     * 执行电源对话框操作
     */
    fun performPowerDialog(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_POWER_DIALOG)
    }

    /**
     * 模拟鼠标移动（通过连续的点触实现光标移动效果）
     * 注意：Android原生不支持鼠标光标，这里通过触摸模拟
     */
    private var lastTouchX = 0f
    private var lastTouchY = 0f

    fun simulateMouseMove(dx: Float, dy: Float): Boolean {
        // 计算新位置
        lastTouchX += dx
        lastTouchY += dy

        // 限制在屏幕范围内
        val displayMetrics = resources.displayMetrics
        lastTouchX = lastTouchX.coerceIn(0f, displayMetrics.widthPixels.toFloat())
        lastTouchY = lastTouchY.coerceIn(0f, displayMetrics.heightPixels.toFloat())

        // 使用非常短的点击来模拟鼠标移动
        // 实际应用中可能需要显示一个自定义光标
        return true
    }

    /**
     * 获取当前光标位置
     */
    fun getCursorPosition(): Pair<Float, Float> {
        return Pair(lastTouchX, lastTouchY)
    }

    /**
     * 设置光标位置
     */
    fun setCursorPosition(x: Float, y: Float) {
        lastTouchX = x
        lastTouchY = y
    }

    /**
     * 执行多点触控手势
     * @param points 触摸点列表，每个点是 (x, y, startTime, duration)
     */
    fun performMultiTouch(points: List<TouchPoint>): Boolean {
        val gestureBuilder = GestureDescription.Builder()

        for (point in points) {
            val path = Path()
            path.moveTo(point.x, point.y)
            
            gestureBuilder.addStroke(
                GestureDescription.StrokeDescription(
                    path,
                    point.startTime,
                    point.duration
                )
            )
        }

        val gesture = gestureBuilder.build()

        return dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                Log.d(TAG, "多点触控完成")
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                Log.w(TAG, "多点触控被取消")
            }
        }, null)
    }
}

/**
 * 触摸点数据类
 */
data class TouchPoint(
    val x: Float,
    val y: Float,
    val startTime: Long = 0,
    val duration: Long = 100
)

