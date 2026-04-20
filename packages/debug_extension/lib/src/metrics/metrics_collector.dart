import 'dart:async';
import '../plugin/debug_extension_plugin.dart';
import 'metrics_data.dart';

/// Collects metrics periodically and exposes them as a stream.
class MetricsCollector {
  final DebugExtensionPlugin _platformCollector;
  final _controller = StreamController<MetricsData>.broadcast();
  Timer? _timer;

  /// Creates a [MetricsCollector] using the given [DebugExtensionPlugin].
  MetricsCollector(this._platformCollector);

  /// Returns a broadcast stream of collected [MetricsData].
  Stream<MetricsData> get metricsStream => _controller.stream;

  /// Starts periodic metrics collection.
  ///
  /// [interval]: The interval between metric collections (default: 2 seconds).
  void start({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      try {
        final metrics = await _platformCollector.collect();
        _controller.add(metrics);
      } catch (e, st) {
        _controller.addError(e, st);
      }
    });
  }

  /// Stops periodic metrics collection.
  void stop() {
    _timer?.cancel();
  }
}
