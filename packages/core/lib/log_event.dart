import 'log_level.dart';

/// Log event type
class LogEvent {
  final LogLevel level;
  final String message;
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
