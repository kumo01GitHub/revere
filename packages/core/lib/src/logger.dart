import 'package:meta/meta.dart';

import 'log_level.dart';
import 'transport.dart';
import 'log_event.dart';

/// Logger main class — collects [Transport] instances and fans out log events.
class Logger {
  @visibleForTesting
  final List<Transport> transports;

  Logger([List<Transport>? transports]) : transports = transports ?? [];

  void addTransport(Transport transport) => transports.add(transport);

  Future<void> log(
    LogLevel level,
    Object message, {
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
