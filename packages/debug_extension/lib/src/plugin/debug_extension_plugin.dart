import 'debug_extension_plugin_platform_interface.dart';
import '../metrics/metrics_data.dart';

/// Provides a unified API for collecting metrics from the current platform.
class DebugExtensionPlugin {
  /// Collects metrics from the current platform implementation.
  ///
  /// Returns a [MetricsData] object. If the platform returns null, a default value is returned.
  Future<MetricsData> collect() async {
    final metrics = await DebugExtensionPluginPlatform.instance.collect();
    // Return default value if null.
    return metrics ??
        MetricsData(cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
  }
}
