import 'logger.dart';

/// Mixin to provide a shared logger instance to any class.
/// Mixin to provide a shared logger instance and context-aware logging.
mixin LoggerMixin {
  static final Logger logger = Logger();

  String get loggerContext => runtimeType.toString();

  Future<void> logInfo(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => logger.info(
    message,
    error: error,
    stackTrace: stackTrace,
    context: loggerContext,
  );
  Future<void> logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => logger.error(
    message,
    error: error,
    stackTrace: stackTrace,
    context: loggerContext,
  );
}
