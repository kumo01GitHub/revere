import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/debug_extension.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'RevereDebugExtension getMetrics returns a Future or throws UnimplementedError or MissingPluginException',
      () async {
    try {
      final result = await RevereDebugExtension.getMetrics();
      expect(result, isA<Map<String, dynamic>?>());
    } catch (e) {
      expect(
        e.runtimeType == UnimplementedError ||
            e.runtimeType.toString() == 'MissingPluginException',
        true,
        reason:
            'Should throw UnimplementedError or MissingPluginException, got: \\${e.runtimeType}',
      );
    }
  });
}
