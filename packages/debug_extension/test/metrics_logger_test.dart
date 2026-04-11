import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/logger/metrics_logger.dart';

void main() {
  group('MetricsLogger', () {
    test('can be constructed and started/stopped', () {
      final logger = MetricsLogger();
      logger.start();
      logger.stop();
      expect(logger, isA<MetricsLogger>());
    });
  });
}
