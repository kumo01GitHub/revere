library revere_debug_extension;

export 'src/ui/metrics_widget.dart';
export 'src/ui/floating_button.dart';
export 'src/transport/state_transport.dart';
export 'src/logger/metrics_logger.dart';
export 'src/metrics/metrics_collector.dart';

import 'revere_debug_extension_platform_interface.dart';
import 'revere_debug_extension_method_channel.dart';

// Set the default platform implementation
void _ensurePlatformRegistered() {
  RevereDebugExtensionPlatform.instance = MethodChannelRevereDebugExtension();
}

/// Main API for the plugin
class RevereDebugExtension {
  static Future<Map<String, dynamic>?> getMetrics() {
    _ensurePlatformRegistered();
    return RevereDebugExtensionPlatform.instance.getMetrics();
  }
}
