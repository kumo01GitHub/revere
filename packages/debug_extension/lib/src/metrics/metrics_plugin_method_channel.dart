import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'metrics_plugin_platform_interface.dart';
import 'metrics_data.dart';

/// MethodChannel-based implementation of [MetricsPluginPlatform].
class MethodChannelMetricsPlugin extends MetricsPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('revere_debug_extension');

  /// Collects metrics by invoking the 'collect' method on the platform channel.
  @override
  Future<MetricsData?> collect() async {
    final result = await methodChannel.invokeMethod<Map>('collect');
    if (result == null) return null;
    return MetricsData(
      cpuUsage: (result['cpu'] as num?)?.toDouble(),
      memoryUsage: (result['memory'] as int?) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}
