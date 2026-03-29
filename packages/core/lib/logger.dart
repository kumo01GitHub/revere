import 'log_level.dart';
import 'transport.dart';
import 'log_event.dart';
import 'package:meta/meta.dart';

/// Logger main class
class Logger {
  @visibleForTesting
  final List<Transport> transports;

  Logger([List<Transport>? transports]) : transports = transports ?? [];

  void addTransport(Transport transport) => transports.add(transport);

  Future<void> log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) async {
    final event = LogEvent(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
    await Future.wait(transports.map((t) => t.log(event)));
  }

  // Shortcut functions for each log level
  Future<void> trace(
    String message, {
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
  Future<void> debug(
    String message, {
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
  Future<void> info(
    String message, {
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
  Future<void> warn(
    String message, {
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
  Future<void> error(
    String message, {
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
  Future<void> fatal(
    String message, {
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
