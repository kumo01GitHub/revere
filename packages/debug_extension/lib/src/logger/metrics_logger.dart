import '../metrics/metrics_collector.dart';
import 'dart:async';
import 'package:revere/core.dart';

class MetricsLogger {
  static final MetricsLogger _instance = MetricsLogger._internal();
  factory MetricsLogger() => _instance;
  MetricsLogger._internal();

  final Logger _logger = Logger();
  final MetricsCollector _collector = MetricsCollector();
  StreamSubscription<MetricsData>? _subscription;

  /// Add a transport for metrics logs (e.g. PrettyConsoleTransport)
  void addTransport(Transport transport) => _logger.addTransport(transport);

  /// Public stream getter for metrics
  Stream<MetricsData> get metricsStream => _collector.metricsStream;

  void start() {
    _collector.start();
    _subscription = _collector.metricsStream.listen((metrics) {
      _logger.info(metrics);
    });
  }

  void stop() {
    _subscription?.cancel();
    _collector.stop();
  }
}
