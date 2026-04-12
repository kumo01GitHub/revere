/// Platform interface for metrics plugins.
///
/// This interface allows platform-specific implementations to provide metrics collection.
library metrics_plugin_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'metrics_core.dart';
import 'metrics_method_channel_plugin.dart';

abstract class MetricsPluginInterface extends PlatformInterface {
  /// Constructs a [MetricsPluginInterface].
  MetricsPluginInterface() : super(token: _token);
  static final Object _token = Object();
  static MetricsPluginInterface _instance = MethodChannelMetricsPlugin();

  /// The current platform-specific implementation instance.
  static MetricsPluginInterface get instance => _instance;

  /// Sets the platform-specific implementation instance.
  static set instance(MetricsPluginInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Collects metrics from the platform implementation.
  Future<MetricsData?> collect();
}
