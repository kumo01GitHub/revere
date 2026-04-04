import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'swift_log_transport_platform_interface.dart';

/// [MethodChannel]-based implementation of [SwiftLogTransportPlatform].
class MethodChannelSwiftLogTransport extends SwiftLogTransportPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('swift_log_transport');

  @override
  Future<void> log(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('log', event);
  }
}
