import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_log_transport_method_channel.dart';

abstract class AndroidLogTransportPlatform extends PlatformInterface {
  AndroidLogTransportPlatform() : super(token: _token);

  static final Object _token = Object();
  static AndroidLogTransportPlatform _instance =
      MethodChannelAndroidLogTransport();

  static AndroidLogTransportPlatform get instance => _instance;

  static set instance(AndroidLogTransportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> log(Map<String, dynamic> event);
}
