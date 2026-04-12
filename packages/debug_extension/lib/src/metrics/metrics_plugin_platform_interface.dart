import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'metrics_plugin_method_channel.dart';
import 'metrics_data.dart';

abstract class MetricsPluginPlatform extends PlatformInterface {
  /// Constructs a [MetricsPluginPlatform].
  MetricsPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static MetricsPluginPlatform _instance = MethodChannelMetricsPlugin();

  /// The current platform-specific implementation instance.
  static MetricsPluginPlatform get instance => _instance;

  /// Sets the platform-specific implementation instance.
  static set instance(MetricsPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Collects metrics from the platform implementation.
  Future<MetricsData?> collect() {
    throw UnimplementedError('collect() has not been implemented.');
  }
}
