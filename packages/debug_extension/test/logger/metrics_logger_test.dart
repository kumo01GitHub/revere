import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/metrics.dart';
import 'package:revere_debug_extension/revere_debug_extension.dart';
import 'package:revere/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DebugExtensionPluginPlatform.instance = MockDebugExtensionPlugin();
  group('MetricsLogger', () {
    test('can be constructed and started/stopped', () async {
      final logger = MetricsLogger();
      logger.start(interval: const Duration(milliseconds: 50));
      await Future.delayed(const Duration(milliseconds: 150));
      logger.stop();
      expect(logger, isA<MetricsLogger>());
    });

    test('addTransport adds a transport', () {
      final logger = MetricsLogger();
      final dummy = DummyTransport();
      logger.addTransport(dummy);
      expect(logger.logger.transports.contains(dummy), true);
    });

    test('metricsStream returns a Stream', () {
      final logger = MetricsLogger();
      expect(logger.metricsStream, isA<Stream>());
    });

    test('start/stop can be called multiple times', () async {
      final logger = MetricsLogger();
      logger.start(interval: const Duration(milliseconds: 10));
      logger.stop();
      logger.start(interval: const Duration(milliseconds: 10));
      logger.stop();
      logger.stop(); // stop only, no error
      expect(logger, isA<MetricsLogger>());
    });

    test('formatter is used when provided', () async {
      final logger = MetricsLogger();
      final logs = <String>[];
      logger.addTransport(_ListTransport(logs));
      logger.start(
        interval: const Duration(milliseconds: 10),
        formatter: (m) => 'formatted:${m.memoryUsage}',
      );
      await Future.delayed(const Duration(milliseconds: 50));
      logger.stop();
      expect(logs.any((e) => e.startsWith('formatted:')), true);
    });
  });
}

class DummyTransport extends Transport {
  @override
  Future<void> emitLog(LogEvent event) async {}
}

class _ListTransport extends Transport {
  final List<String> logs;
  _ListTransport(this.logs);
  @override
  Future<void> emitLog(LogEvent event) async {
    logs.add(event.message.toString());
  }
}

class MockDebugExtensionPlugin extends DebugExtensionPluginPlatform {
  @override
  Future<MetricsData?> collect() async {
    return MetricsData(
        cpuUsage: 42.0, memoryUsage: 123, timestamp: DateTime.now());
  }
}
