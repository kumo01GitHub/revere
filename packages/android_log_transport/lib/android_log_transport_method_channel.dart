import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_log_transport_platform_interface.dart';

/// An implementation of [AndroidLogTransportPlatform] that uses method channels.
class MethodChannelAndroidLogTransport extends AndroidLogTransportPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('android_log_transport');

  @override
  Future<void> log(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('log', event);
  }
}
