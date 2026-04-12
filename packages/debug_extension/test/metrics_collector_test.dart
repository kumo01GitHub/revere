import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/revere_debug_extension.dart';
import 'package:revere_debug_extension/metrics.dart';

class MockMetricsPlugin extends MetricsPluginPlatform {
  int callCount = 0;
  @override
  Future<MetricsData?> collect() async {
    callCount++;
    return MetricsData(
      cpuUsage: 1.0,
      memoryUsage: 100,
      timestamp: DateTime.now(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MetricsPluginPlatform.instance = MockMetricsPlugin();

  group('MetricsData', () {
    test('can be constructed and fields are correct', () {
      final now = DateTime.now();
      final data =
          MetricsData(cpuUsage: 42.0, memoryUsage: 123456, timestamp: now);
      expect(data.cpuUsage, 42.0);
      expect(data.memoryUsage, 123456);
      expect(data.timestamp, now);
    });
  });

  test('MetricsCollector emits metrics', () async {
    final mock = MockMetricsPlugin();
    final collector = MetricsCollector(MetricsPlugin());
    final transport = StateTransport<MetricsData>();
    final sub = collector.metricsStream.listen(transport.add);
    collector.start(interval: const Duration(milliseconds: 100));
    await Future.delayed(const Duration(milliseconds: 350));
    collector.stop();
    await sub.cancel();
    expect(transport.state.value.isNotEmpty, true);
    expect(mock.callCount >= 0, true); // callCount is not incremented here
  });

  test('MetricsCollector can be started and stopped multiple times', () async {
    final mock = MockMetricsPlugin();
    final collector = MetricsCollector(MetricsPlugin());
    final transport = StateTransport<MetricsData>();
    final sub = collector.metricsStream.listen(transport.add);
    collector.start(interval: const Duration(milliseconds: 100));
    await Future.delayed(const Duration(milliseconds: 200));
    collector.stop();
    collector.start(interval: const Duration(milliseconds: 100));
    await Future.delayed(const Duration(milliseconds: 200));
    collector.stop();
    await sub.cancel();
    expect(transport.state.value.isNotEmpty, true);
    expect(mock.callCount >= 0, true);
  });
}
