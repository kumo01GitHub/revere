import 'metrics_plugin_platform_interface.dart';
import 'metrics_data.dart';

/// Provides a unified API for collecting metrics from the current platform.
class MetricsPlugin {
  /// Collects metrics from the current platform implementation.
  ///
  /// Returns a [MetricsData] object. If the platform returns null, a default value is returned.
  Future<MetricsData> collect() async {
    final metrics = await MetricsPluginPlatform.instance.collect();
    // Return default value if null.
    return metrics ??
        MetricsData(cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
  }
}
