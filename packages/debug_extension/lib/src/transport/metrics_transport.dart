import '../metrics/metrics_collector.dart';

class MetricsTransport {
  final List<MetricsData> _state = [];
  final int maxLength;

  MetricsTransport({this.maxLength = 100});

  void add(MetricsData data) {
    _state.add(data);
    if (_state.length > maxLength) {
      _state.removeAt(0);
    }
  }

  List<MetricsData> get state => List.unmodifiable(_state);
}
