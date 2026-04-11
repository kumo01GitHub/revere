import 'package:flutter/services.dart';
import 'revere_debug_extension_platform_interface.dart';

class MethodChannelRevereDebugExtension extends RevereDebugExtensionPlatform {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');

  @override
  Future<Map<String, dynamic>?> getMetrics() async {
    final result = await _channel.invokeMethod<Map>('getMetrics');
    return result?.cast<String, dynamic>();
  }
}
