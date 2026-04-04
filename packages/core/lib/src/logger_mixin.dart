import 'logger.dart';

/// Mixin that provides a shared [Logger] instance and context-aware shortcut
/// methods with single-character names for brevity.
mixin LoggerMixin {
  static final Logger logger = Logger();

  String get loggerContext => runtimeType.toString();

  Future<void> t(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.trace(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  Future<void> d(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.debug(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  Future<void> i(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.info(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  Future<void> w(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.warn(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  Future<void> e(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.error(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  Future<void> f(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.fatal(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
}
