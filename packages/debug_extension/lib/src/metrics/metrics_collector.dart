import 'dart:async';
import 'metrics_core.dart';
import 'metrics_plugin.dart';

/// Collects metrics periodically and exposes them as a stream.
class MetricsCollector {
  final MetricsPlugin _platformCollector;
  final _controller = StreamController<MetricsData>.broadcast();
  Timer? _timer;

  /// Creates a [MetricsCollector] using the given [MetricsPlugin].
  MetricsCollector(this._platformCollector);

  /// Returns a broadcast stream of collected [MetricsData].
  Stream<MetricsData> get metricsStream => _controller.stream;

  /// Starts periodic metrics collection.
  ///
  /// [interval]: The interval between metric collections (default: 2 seconds).
  void start({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final metrics = await _platformCollector.collect();
      _controller.add(metrics);
    });
  }

  /// Stops periodic metrics collection.
  void stop() {
    _timer?.cancel();
  }
}
