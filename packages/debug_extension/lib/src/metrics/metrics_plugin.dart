import 'metrics_plugin_interface.dart';
import 'metrics_core.dart';

/// Provides a unified API for collecting metrics from the current platform.

class MetricsPlugin {
  /// Creates a [MetricsPlugin].
  ///
  /// The platform implementation should be set elsewhere (default is _DefaultMetricsPlugin).
  MetricsPlugin();

  /// Collects metrics from the current platform implementation.
  ///
  /// Returns a [MetricsData] object. If the platform returns null, a default value is returned.
  Future<MetricsData> collect() async {
    final metrics = await MetricsPluginInterface.instance.collect();
    // Return default value if null.
    return metrics ??
        MetricsData(cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
  }
}
