import '../metrics/metrics_collector.dart';
import '../plugin/debug_extension_plugin.dart';
import '../metrics/metrics_data.dart';
import 'dart:async';
import 'package:revere/core.dart';

class MetricsLogger {
  Logger get logger => _logger;

  MetricsLogger() {
    _collector = MetricsCollector(DebugExtensionPlugin());
  }

  final Logger _logger = Logger();
  MetricsCollector? _collector;
  StreamSubscription<MetricsData>? _subscription;

  /// Add a transport for metrics logs (e.g. PrettyConsoleTransport)
  void addTransport(Transport transport) => _logger.addTransport(transport);

  /// Public stream getter for metrics
  Stream<MetricsData> get metricsStream => _collector!.metricsStream;

  /// interval: log output interval
  /// formatter: message format (default is metrics.toString())
  void start({
    Duration interval = const Duration(seconds: 2),
    String Function(MetricsData)? formatter,
  }) {
    _collector!.start(interval: interval);
    _subscription = _collector!.metricsStream.listen(
      (metrics) {
        try {
          final msg =
              formatter != null ? formatter(metrics) : metrics.toString();
          _logger.info(msg);
        } catch (e, st) {
          _logger.error('[MetricsLogger] Error logging metrics',
              error: e, stackTrace: st);
        }
      },
      onError: (e, st) {
        _logger.error('[MetricsLogger] MetricsCollector error',
            error: e, stackTrace: st);
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _collector?.stop();
  }
}
