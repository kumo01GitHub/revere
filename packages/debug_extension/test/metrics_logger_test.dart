import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/metrics.dart';
import 'package:revere_debug_extension/revere_debug_extension.dart';

class MockMetricsPlugin extends MetricsPluginPlatform {
  @override
  Future<MetricsData?> collect() async {
    return MetricsData(
        cpuUsage: 42.0, memoryUsage: 123, timestamp: DateTime.now());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MetricsPluginPlatform.instance = MockMetricsPlugin();
  group('MetricsLogger', () {
    test('can be constructed and started/stopped', () async {
      final logger = MetricsLogger();
      logger.start(interval: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 150));
      logger.stop();
      expect(logger, isA<MetricsLogger>());
    });
  });
}
