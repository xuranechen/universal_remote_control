package com.example.universal_remote_control

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android输入模拟插件
 * 通过Platform Channel与Flutter通信
 */
class InputSimulatorPlugin : FlutterPlugin, MethodCallHandler {
    
    companion object {
        private const val TAG = "InputSimulatorPlugin"
        private const val CHANNEL_NAME = "com.example.universal_remote_control/input_simulator"
        
        // 静态方法供MainActivity使用
        private var pluginInstance: InputSimulatorPlugin? = null
        
        fun moveMouse(dx: Double, dy: Double) {
            pluginInstance?.simulateMouseMove(dx.toFloat(), dy.toFloat())
        }
        
        fun mouseClick(button: String) {
            // 实现鼠标点击
            val service = RemoteControlAccessibilityService.getInstance()
            service?.let {
                val pos = it.getCursorPosition()
                it.performClick(pos.first, pos.second)
            }
        }
        
        fun keyPress(key: String) {
            // 实现按键
            Log.d(TAG, "Key press: $key")
        }
        
        fun typeText(text: String) {
            // 实现文本输入
            Log.d(TAG, "Type text: $text")
        }
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        pluginInstance = this
        Log.i(TAG, "输入模拟插件已附加")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginInstance = null
        Log.i(TAG, "输入模拟插件已分离")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "isServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                
                "performClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 100L
                    
                    val success = performClick(x, y, duration)
                    result.success(success)
                }
                
                "performSwipe" -> {
                    val x1 = call.argument<Double>("x1")?.toFloat() ?: 0f
                    val y1 = call.argument<Double>("y1")?.toFloat() ?: 0f
                    val x2 = call.argument<Double>("x2")?.toFloat() ?: 0f
                    val y2 = call.argument<Double>("y2")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 300L
                    
                    val success = performSwipe(x1, y1, x2, y2, duration)
                    result.success(success)
                }
                
                "performLongPress" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 1000L
                    
                    val success = performLongPress(x, y, duration)
                    result.success(success)
                }
                
                "performBack" -> {
                    val success = performGlobalAction("back")
                    result.success(success)
                }
                
                "performHome" -> {
                    val success = performGlobalAction("home")
                    result.success(success)
                }
                
                "performRecents" -> {
                    val success = performGlobalAction("recents")
                    result.success(success)
                }
                
                "simulateMouseMove" -> {
                    val dx = call.argument<Double>("dx")?.toFloat() ?: 0f
                    val dy = call.argument<Double>("dy")?.toFloat() ?: 0f
                    
                    val success = simulateMouseMove(dx, dy)
                    result.success(success)
                }
                
                "getCursorPosition" -> {
                    val position = getCursorPosition()
                    result.success(mapOf("x" to position.first, "y" to position.second))
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "方法调用失败: ${call.method}", e)
            result.error("ERROR", e.message, null)
        }
    }

    /**
     * 检查无障碍服务是否已启用
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${context.packageName}/${RemoteControlAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        
        return enabledServices?.contains(service) == true &&
               RemoteControlAccessibilityService.isServiceEnabled()
    }

    /**
     * 打开无障碍设置页面
     */
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    /**
     * 执行点击操作
     */
    private fun performClick(x: Float, y: Float, duration: Long): Boolean {
        val service = RemoteControlAccessibilityService.getInstance()
        if (service == null) {
            Log.w(TAG, "无障碍服务未启用")
            return false
        }
        return service.performClick(x, y, duration)
    }

    /**
     * 执行滑动操作
     */
    private fun performSwipe(
        x1: Float, y1: Float,
        x2: Float, y2: Float,
        duration: Long
    ): Boolean {
        val service = RemoteControlAccessibilityService.getInstance()
        if (service == null) {
            Log.w(TAG, "无障碍服务未启用")
            return false
        }
        return service.performSwipe(x1, y1, x2, y2, duration)
    }

    /**
     * 执行长按操作
     */
    private fun performLongPress(x: Float, y: Float, duration: Long): Boolean {
        val service = RemoteControlAccessibilityService.getInstance()
        if (service == null) {
            Log.w(TAG, "无障碍服务未启用")
            return false
        }
        return service.performLongPress(x, y, duration)
    }

    /**
     * 执行全局操作
     */
    private fun performGlobalAction(action: String): Boolean {
        val service = RemoteControlAccessibilityService.getInstance()
        if (service == null) {
            Log.w(TAG, "无障碍服务未启用")
            return false
        }
        
        return when (action) {
            "back" -> service.performBack()
            "home" -> service.performHome()
            "recents" -> service.performRecents()
            else -> false
        }
    }

    /**
     * 模拟鼠标移动
     */
    private fun simulateMouseMove(dx: Float, dy: Float): Boolean {
        val service = RemoteControlAccessibilityService.getInstance()
        if (service == null) {
            Log.w(TAG, "无障碍服务未启用")
            return false
        }
        return service.simulateMouseMove(dx, dy)
    }

    /**
     * 获取光标位置
     */
    private fun getCursorPosition(): Pair<Float, Float> {
        val service = RemoteControlAccessibilityService.getInstance()
        return service?.getCursorPosition() ?: Pair(0f, 0f)
    }
}

