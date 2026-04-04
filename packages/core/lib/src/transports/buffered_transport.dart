import 'dart:async';

import '../log_event.dart';
import '../log_level.dart';
import '../transport.dart';

/// A [Transport] decorator that buffers [LogEvent]s and flushes them in
/// batches to an inner [Transport].
///
/// Flushing is triggered by either:
/// - The buffer reaching [maxSize] (default: 100).
/// - The [flushInterval] timer firing (if provided).
///
/// Call [flush] manually to drain the buffer on demand, and [dispose] when
/// the transport is no longer needed to cancel the timer and flush remaining
/// events.
///
/// Example:
/// ```dart
/// final transport = BufferedTransport(
///   HttpTransport('https://logs.example.com'),
///   maxSize: 50,
///   flushInterval: Duration(seconds: 30),
/// );
///
/// // Or via extension:
/// HttpTransport('https://logs.example.com')
///   .withBuffer(maxSize: 50, flushInterval: Duration(seconds: 30));
/// ```
class BufferedTransport extends Transport {
  /// The inner transport that receives events on flush.
  final Transport inner;

  /// Maximum number of events to buffer before an automatic flush.
  final int maxSize;

  /// How often to automatically flush the buffer.
  /// When `null`, only [maxSize] triggers automatic flushes.
  final Duration? flushInterval;

  final List<LogEvent> _buffer = [];
  Timer? _timer;

  BufferedTransport(
    this.inner, {
    this.maxSize = 100,
    this.flushInterval,
    super.level = LogLevel.trace,
    super.config,
  }) {
    if (flushInterval != null) {
      _timer = Timer.periodic(flushInterval!, (_) => flush());
    }
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    _buffer.add(event);
    if (_buffer.length >= maxSize) {
      await flush();
    }
  }

  /// Sends all buffered events to [inner] and clears the buffer.
  ///
  /// Safe to call concurrently — the buffer is snapshotted atomically
  /// before any async work begins.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final events = List<LogEvent>.from(_buffer);
    _buffer.clear();
    for (final event in events) {
      await inner.log(event);
    }
  }

  /// Cancels the periodic timer and flushes any remaining buffered events.
  ///
  /// Should be called when the transport is no longer needed.
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await flush();
  }

  /// Number of events currently in the buffer.
  int get pendingCount => _buffer.length;
}

/// Extension that adds a [withBuffer] decorator to any [Transport].
extension BufferedTransportExtension on Transport {
  /// Wraps this transport in a [BufferedTransport].
  ///
  /// ```dart
  /// HttpTransport('https://logs.example.com')
  ///   .withBuffer(maxSize: 100, flushInterval: Duration(seconds: 30));
  /// ```
  BufferedTransport withBuffer({int maxSize = 100, Duration? flushInterval}) {
    return BufferedTransport(
      this,
      maxSize: maxSize,
      flushInterval: flushInterval,
    );
  }
}
