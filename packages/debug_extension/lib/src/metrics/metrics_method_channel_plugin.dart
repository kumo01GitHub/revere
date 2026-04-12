import 'package:flutter/services.dart';
import 'metrics_plugin_interface.dart';
import 'metrics_core.dart';

/// MethodChannel-based implementation of [MetricsPluginInterface].
class MethodChannelMetricsPlugin extends MetricsPluginInterface {
  /// インスタンス生成時にDart側のinstanceを自動セット
  MethodChannelMetricsPlugin() {
    MetricsPluginInterface.instance = this;
  }

  static const MethodChannel _channel = MethodChannel('revere_debug_extension');

  /// Collects metrics by invoking the 'collect' method on the platform channel.
  @override
  Future<MetricsData?> collect() async {
    final result = await _channel.invokeMethod<Map>('collect');
    if (result == null) return null;
    return MetricsData(
      cpuUsage: (result['cpu'] as num?)?.toDouble(),
      memoryUsage: (result['memory'] as int?) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}
