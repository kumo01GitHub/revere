import 'package:meta/meta.dart';

import 'log_level.dart';
import 'transport.dart';
import 'log_event.dart';

/// Logger main class — collects [Transport] instances and fans out log events.
///
/// Create one logger per application or service boundary, add the transports
/// you need, then use the level-specific methods to emit log events.
///
/// ```dart
/// final logger = Logger();
/// logger.addTransport(ConsoleTransport());
/// logger.addTransport(FileTransport('/var/log/app.log'));
///
/// await logger.info('Server started on port 8080');
/// await logger.error('Unhandled exception', error: e, stackTrace: st);
/// ```
class Logger {
  /// The list of registered transports.
  ///
  /// Exposed for testing purposes. Prefer [addTransport] for mutations.
  @visibleForTesting
  final List<Transport> transports;

  /// Creates a logger, optionally pre-populating [transports].
  Logger([List<Transport>? transports]) : transports = transports ?? [];

  /// Registers [transport] to receive future log events.
  void addTransport(Transport transport) => transports.add(transport);

  /// Emits a log event at [level] and fans it out to all registered transports.
  ///
  /// [message] can be any object; transports call [toString] when needed.
  /// [error] and [stackTrace] attach exception details to the event.
  /// [context] is an optional source label (e.g. class or module name).
  Future<void> log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) async {
    if (level == LogLevel.silent) {
      throw ArgumentError.value(
        level,
        'level',
        'LogLevel.silent is a threshold sentinel and cannot be used to emit events.',
      );
    }
    final event = LogEvent(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
    await Future.wait(transports.map((t) => t.log(event)));
  }

  /// Emits a [LogLevel.trace] event. Use for fine-grained diagnostic output.
  Future<void> trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.trace,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Emits a [LogLevel.debug] event. Use for detailed debugging information.
  Future<void> debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.debug,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Emits a [LogLevel.info] event. Use for normal operational milestones.
  Future<void> info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.info,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Emits a [LogLevel.warn] event. Use for potentially harmful situations.
  Future<void> warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.warn,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Emits a [LogLevel.error] event. Use for recoverable error conditions.
  Future<void> error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );

  /// Emits a [LogLevel.fatal] event. Use for unrecoverable failures.
  Future<void> fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) => log(
    LogLevel.fatal,
    message,
    error: error,
    stackTrace: stackTrace,
    context: context,
  );
}
