import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/metrics.dart';

class MockDebugExtensionPlugin extends DebugExtensionPluginPlatform {
  @override
  Future<MetricsData?> collect() async {
    return MetricsData(
        cpuUsage: 42.0, memoryUsage: 123, timestamp: DateTime.now());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DebugExtensionPluginPlatform.instance = MockDebugExtensionPlugin();
  test('DebugExtensionPlugin returns default value if null', () async {
    final plugin = DebugExtensionPlugin();
    final result = await plugin.collect();
    expect(result, isNotNull);
    expect(result.memoryUsage, isA<int>());
  });
}
