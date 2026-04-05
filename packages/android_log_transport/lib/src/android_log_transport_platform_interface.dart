import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'android_log_transport_method_channel.dart';

/// Platform interface for [AndroidLogTransport].
///
/// Package authors can extend this class and call
/// `AndroidLogTransportPlatform.instance = MyImpl()` to provide a
/// custom platform implementation (e.g. for unit tests).
abstract class AndroidLogTransportPlatform extends PlatformInterface {
  /// Constructs an [AndroidLogTransportPlatform].
  AndroidLogTransportPlatform() : super(token: _token);

  static final Object _token = Object();
  static AndroidLogTransportPlatform _instance =
      MethodChannelAndroidLogTransport();

  /// The default instance of [AndroidLogTransportPlatform] to use.
  static AndroidLogTransportPlatform get instance => _instance;

  /// Sets a custom [instance]. Override in tests or alternative implementations.
  static set instance(AndroidLogTransportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Sends [event] to Android Logcat via the platform channel.
  Future<void> log(Map<String, dynamic> event);
}
