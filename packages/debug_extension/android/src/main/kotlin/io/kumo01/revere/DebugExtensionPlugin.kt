package io.kumo01.revere

import androidx.annotation.NonNull
import android.os.SystemClock
import android.util.Log
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
      try {
        val memoryUsage = getMemoryUsageByDebug()
        val cpuPercent = getSimpleCpuUsagePercent()
        result.success(mapOf("cpu" to cpuPercent, "memory" to memoryUsage))
      } catch (e: Exception) {
        Log.e(TAG, "collect failed: ${e.javaClass.name}: ${e.message}")
        result.error(e.javaClass.name, e.message, null)
      }
    } else {
      result.notImplemented()
    }
  }

  companion object {
    private const val TAG = "DebugExtensionPlugin"
    private var lastCpuTime: Long? = null
    private var lastSampleTime: Long? = null
    private var lastPercent: Double? = null
    private fun getSimpleCpuUsagePercent(): Double? {
      try {
        val stat = java.io.RandomAccessFile("/proc/self/stat", "r")
        val toks = stat.readLine().split(" ")
        val utime = toks[13].toLong()
        val stime = toks[14].toLong()
        val totalTime = utime + stime
        val now = SystemClock.elapsedRealtime()
        var percent: Double? = null
        if (lastCpuTime != null && lastSampleTime != null && now > lastSampleTime!!) {
          val diffCpu = totalTime - lastCpuTime!!
          val diffTime = now - lastSampleTime!!
          if (diffTime > 0) {
            percent = 100.0 * (diffCpu.toDouble() / android.os.Process.getElapsedCpuTime().toDouble())
            if (percent < 0) percent = 0.0
            lastPercent = percent
          } else {
            percent = lastPercent
          }
        } else {
          percent = lastPercent
        }
        lastCpuTime = totalTime
        lastSampleTime = now
        stat.close()
        return percent
      } catch (e: Exception) {
        return lastPercent
      }
    }
  }

  // Returns memory usage in bytes (resident set size) using Debug.MemoryInfo
  private fun getMemoryUsageByDebug(): Int {
    val mi = android.os.Debug.MemoryInfo()
    android.os.Debug.getMemoryInfo(mi)
    return mi.totalPss * 1024 // totalPss is in KB
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
