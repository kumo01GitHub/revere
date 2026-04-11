import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class RevereDebugExtensionPlatform extends PlatformInterface {
  RevereDebugExtensionPlatform() : super(token: _token);

  static final Object _token = Object();
  static RevereDebugExtensionPlatform _instance =
      _DefaultRevereDebugExtensionPlatform();

  static RevereDebugExtensionPlatform get instance => _instance;
  static set instance(RevereDebugExtensionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<String, dynamic>?> getMetrics();
}

class _DefaultRevereDebugExtensionPlatform
    extends RevereDebugExtensionPlatform {
  @override
  Future<Map<String, dynamic>?> getMetrics() async {
    throw UnimplementedError('getMetrics() has not been implemented.');
  }
}
