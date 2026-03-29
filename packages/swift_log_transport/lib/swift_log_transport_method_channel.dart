import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'swift_log_transport_platform_interface.dart';

/// An implementation of [SwiftLogTransportPlatform] that uses method channels.
class MethodChannelSwiftLogTransport extends SwiftLogTransportPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('swift_log_transport');

  @override
  Future<void> log(Map<String, dynamic> event) async {
    await methodChannel.invokeMethod('log', event);
  }
}
