/// Represents a snapshot of system metrics (CPU, memory, thread count, timestamp).
class MetricsData {
  final double? cpuUsage;
  final int memoryUsage;
  final int? threadCount;
  final DateTime timestamp;

  /// Creates a new [MetricsData] instance.
  ///
  /// [cpuUsage]: CPU usage as a percentage (nullable).
  /// [memoryUsage]: Memory usage in bytes.
  /// [threadCount]: Number of threads (nullable).
  /// [timestamp]: The time when the metrics were collected.
  MetricsData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.timestamp,
    this.threadCount,
  });

  @override
  String toString() {
    return 'CPU: '
        '${cpuUsage != null ? '${cpuUsage!.toStringAsFixed(2)}%' : 'N/A'}, '
        'Memory: $memoryUsage bytes, '
        'Threads: ${threadCount ?? 'N/A'}, Time: $timestamp';
  }
}
