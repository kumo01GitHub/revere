import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_log_transport_platform_interface.dart';

/// [MethodChannel]-based implementation of [AndroidLogTransportPlatform].
class MethodChannelAndroidLogTransport extends AndroidLogTransportPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('android_log_transport');

  @override
  Future<void> log(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('log', event);
  }
}
