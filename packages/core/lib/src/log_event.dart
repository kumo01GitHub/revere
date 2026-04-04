import 'log_level.dart';

/// Represents a single log event.
///
/// [message] accepts any object. String transports call [message.toString()];
/// structured transports (e.g. [HttpTransport]) can inspect the runtime type
/// to embed rich data directly in their payload.
class LogEvent {
  final LogLevel level;
  final Object message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final String? context;

  LogEvent({
    required this.level,
    required this.message,
    DateTime? timestamp,
    this.error,
    this.stackTrace,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();
}
