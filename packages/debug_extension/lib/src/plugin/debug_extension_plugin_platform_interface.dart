import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'debug_extension_plugin_method_channel.dart';
import '../metrics/metrics_data.dart';

abstract class DebugExtensionPluginPlatform extends PlatformInterface {
  /// Constructs a [DebugExtensionPluginPlatform].
  DebugExtensionPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static DebugExtensionPluginPlatform _instance =
      MethodChannelDebugExtensionPlugin();

  /// The current platform-specific implementation instance.
  static DebugExtensionPluginPlatform get instance => _instance;

  /// Sets the platform-specific implementation instance.
  static set instance(DebugExtensionPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Collects metrics from the platform implementation.
  Future<MetricsData?> collect() {
    throw UnimplementedError('collect() has not been implemented.');
  }
}
