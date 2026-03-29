package io.kumo01.revere

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * AndroidLogTransportPlugin
 * Receives log events from Dart and logs to Android Logcat.
 */
class AndroidLogTransportPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "android_log_transport")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "log") {
            val level = call.argument<String>("level") ?: "info"
            val message = call.argument<String>("message") ?: ""
            val context = call.argument<String>("context")
            val tag = call.argument<String>("tag")

            var resolvedTag = "Revere";
            if (tag != null) {
                resolvedTag = tag.replace("{context}", context ?: "")
            } else if (context != null) {
                resolvedTag = context
            }
            when (level.lowercase()) {
                "trace", "debug" -> Log.d(resolvedTag, message)
                "info" -> Log.i(resolvedTag, message)
                "warn", "warning" -> Log.w(resolvedTag, message)
                "error" -> Log.e(resolvedTag, message)
                "fatal" -> Log.wtf(resolvedTag, message)
                else -> Log.i(resolvedTag, message)
            }
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
