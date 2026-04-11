import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/metrics/metrics_collector.dart';
import 'package:revere_debug_extension/src/transport/state_transport.dart';

void main() {
  group('StateTransport', () {
    test('add and state', () {
      final transport = StateTransport<MetricsData>(maxLength: 2);
      final data1 = MetricsData(
          cpuUsage: 1.0, memoryUsage: 100, timestamp: DateTime.now());
      final data2 = MetricsData(
          cpuUsage: 2.0, memoryUsage: 200, timestamp: DateTime.now());
      final data3 = MetricsData(
          cpuUsage: 3.0, memoryUsage: 300, timestamp: DateTime.now());
      transport.add(data1);
      transport.add(data2);
      expect(transport.state.length, 2);
      transport.add(data3);
      expect(transport.state.length, 2);
      expect(transport.state.first, data2);
      expect(transport.state.last, data3);
    });
  });
}
