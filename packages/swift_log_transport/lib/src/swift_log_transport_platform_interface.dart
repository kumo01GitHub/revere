import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'swift_log_transport_method_channel.dart';

/// Platform interface for [SwiftLogTransport].
///
/// Package authors can extend this class and call
/// `SwiftLogTransportPlatform.instance = MyImpl()` to provide a
/// custom platform implementation (e.g. for unit tests).
abstract class SwiftLogTransportPlatform extends PlatformInterface {
  /// Constructs a [SwiftLogTransportPlatform].
  SwiftLogTransportPlatform() : super(token: _token);

  static final Object _token = Object();
  static SwiftLogTransportPlatform _instance = MethodChannelSwiftLogTransport();

  /// The default instance of [SwiftLogTransportPlatform] to use.
  static SwiftLogTransportPlatform get instance => _instance;

  /// Sets a custom [instance]. Override in tests or alternative implementations.
  static set instance(SwiftLogTransportPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Sends [event] to swift-log via the platform channel.
  Future<void> log(Map<String, dynamic> event);
}
