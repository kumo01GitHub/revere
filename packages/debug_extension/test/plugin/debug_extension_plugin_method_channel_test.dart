import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/plugin/debug_extension_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('revere_debug_extension');
  final plugin = MethodChannelDebugExtensionPlugin();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('collect invokes method channel and parses result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'collect');
      return {'cpu': 1.5, 'memory': 100};
    });
    final result = await plugin.collect();
    expect(result, isNotNull);
    expect(result?.cpuUsage, 1.5);
    expect(result?.memoryUsage, 100);
  });

  test('collect returns null if platform returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    final result = await plugin.collect();
    expect(result, isNull);
  });
}
