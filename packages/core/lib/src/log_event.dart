import 'log_level.dart';

/// Represents a single log event.
///
/// [message] accepts any object. String transports call [message.toString()];
/// structured transports (e.g. [HttpTransport]) can inspect the runtime type
/// to embed rich data directly in their payload.
class LogEvent {
  /// Severity of this event.
  final LogLevel level;

  /// Log payload. String transports call [toString]; structured transports
  /// (e.g. [HttpTransport]) can inspect the runtime type to embed rich data.
  final Object message;

  /// When the event occurred. Defaults to [DateTime.now] at construction time.
  final DateTime timestamp;

  /// Optional exception or error associated with this event.
  final Object? error;

  /// Optional stack trace associated with [error].
  final StackTrace? stackTrace;

  /// Optional label identifying the source of the event (e.g. class name).
  final String? context;

  /// Creates a [LogEvent].
  ///
  /// [timestamp] defaults to [DateTime.now] when omitted.
  LogEvent({
    required this.level,
    required this.message,
    DateTime? timestamp,
    this.error,
    this.stackTrace,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();
}
