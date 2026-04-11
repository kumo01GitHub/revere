import '../metrics/metrics_collector.dart';
import 'dart:async';
import 'package:revere/core.dart';

class MetricsLogger {
  Logger get logger => _logger;
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

  /// interval: ログ出力間隔
  /// formatter: メッセージフォーマット (デフォルトは metrics.toString())
  void start({
    Duration interval = const Duration(seconds: 2),
    String Function(MetricsData)? formatter,
  }) {
    _collector.start(interval: interval);
    _subscription = _collector.metricsStream.listen((metrics) {
      final msg = formatter != null ? formatter(metrics) : metrics.toString();
      _logger.info(msg);
    });
  }

  void stop() {
    _subscription?.cancel();
    _collector.stop();
  }
}
