import '../metrics/metrics_collector.dart';
import 'dart:async';

class MetricsLogger {
  static final MetricsLogger _instance = MetricsLogger._internal();
  factory MetricsLogger() => _instance;
  MetricsLogger._internal();

  final MetricsCollector _collector = MetricsCollector();
  StreamSubscription<MetricsData>? _subscription;

  void start() {
    _collector.start();
    _subscription = _collector.metricsStream.listen((metrics) {
      // TODO: Extend revere logger to log metrics
    });
  }

  void stop() {
    _subscription?.cancel();
    _collector.stop();
  }
}
