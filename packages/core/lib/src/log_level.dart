/// Severity levels for log events, ordered from lowest to highest.
///
/// Use [trace] for fine-grained diagnostic output and [fatal] for unrecoverable
/// failures. Each [Transport] filters events by comparing
/// `event.level.index >= transport.level.index`.
enum LogLevel {
  /// Finest-grained diagnostic messages, typically only useful during
  /// development (e.g. function entry/exit points).
  trace,

  /// Detailed information useful during debugging but suppressed in normal
  /// production runs.
  debug,

  /// Informational messages confirming that things are working as expected.
  info,

  /// Potentially harmful situations that deserve attention but do not prevent
  /// normal operation.
  warn,

  /// Error events that might still allow the application to continue running.
  error,

  /// Very severe error events that usually lead the application to terminate.
  fatal,
}
