import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/metrics/metrics_collector.dart';
import 'package:revere_debug_extension/src/transport/state_transport.dart';

void main() {
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
    final collector = MetricsCollector();
    final transport = StateTransport<MetricsData>();
    final sub = collector.metricsStream.listen(transport.add);
    collector.start(interval: const Duration(milliseconds: 200));
    await Future.delayed(const Duration(milliseconds: 1100));
    collector.stop();
    await sub.cancel();
    expect(transport.state.isNotEmpty, true);
  });

  test('MetricsCollector can be started and stopped multiple times', () async {
    final collector = MetricsCollector();
    final transport = StateTransport<MetricsData>();
    final sub = collector.metricsStream.listen(transport.add);
    collector.start(interval: const Duration(milliseconds: 200));
    await Future.delayed(const Duration(milliseconds: 500));
    collector.stop();
    collector.start(interval: const Duration(milliseconds: 200));
    await Future.delayed(const Duration(milliseconds: 500));
    collector.stop();
    await sub.cancel();
    expect(transport.state.isNotEmpty, true);
  });
}
