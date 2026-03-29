import 'logger.dart';

/// Mixin to provide a shared logger instance and context-aware logging.
mixin LoggerMixin {
  static final Logger logger = Logger();

  String get loggerContext => runtimeType.toString();

  Future<void> t(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.trace(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
  Future<void> d(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.debug(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
  Future<void> i(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.info(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
  Future<void> w(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.warn(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
  Future<void> e(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.error(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
  Future<void> f(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.fatal(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
}
