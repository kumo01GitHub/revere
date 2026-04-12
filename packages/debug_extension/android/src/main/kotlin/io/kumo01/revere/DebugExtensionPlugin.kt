package io.kumo01.revere

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DebugExtensionPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "revere_debug_extension")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "collect") {
      // Android: Use Debug.MemoryInfo for memory usage, no direct API for CPU usage
      try {
        val memoryUsage = getMemoryUsageByDebug()
        // CPU usage: not available as instant value via Android API
        result.success(mapOf("cpu" to null, "memory" to memoryUsage))
      } catch (e: Exception) {
        result.success(mapOf("cpu" to null, "memory" to 0))
      }
    } else {
      result.notImplemented()
    }
    // Returns memory usage in bytes (resident set size) using Debug.MemoryInfo
    private fun getMemoryUsageByDebug(): Int {
      val mi = android.os.Debug.MemoryInfo()
      android.os.Debug.getMemoryInfo(mi)
      return mi.totalPss * 1024 // totalPss is in KB
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
