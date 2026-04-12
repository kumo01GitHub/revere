/// Represents a snapshot of system metrics (CPU, memory, timestamp).
class MetricsData {
  final double? cpuUsage;
  final int memoryUsage;
  final DateTime timestamp;

  /// Creates a new [MetricsData] instance.
  ///
  /// [cpuUsage]: CPU usage as a percentage (nullable).
  /// [memoryUsage]: Memory usage in bytes.
  /// [timestamp]: The time when the metrics were collected.
  MetricsData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'CPU: '
        '${cpuUsage != null ? '${cpuUsage!.toStringAsFixed(2)}%' : 'N/A'}, '
        'Memory: $memoryUsage bytes, Time: $timestamp';
  }
}
