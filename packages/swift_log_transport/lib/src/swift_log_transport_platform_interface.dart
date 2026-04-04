import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'swift_log_transport_method_channel.dart';

abstract class SwiftLogTransportPlatform extends PlatformInterface {
  SwiftLogTransportPlatform() : super(token: _token);

  static final Object _token = Object();
  static SwiftLogTransportPlatform _instance = MethodChannelSwiftLogTransport();

  static SwiftLogTransportPlatform get instance => _instance;

  static set instance(SwiftLogTransportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> log(Map<String, dynamic> event);
}
