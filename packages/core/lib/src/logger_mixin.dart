import 'logger.dart';

/// Mixin that provides a shared [Logger] instance and context-aware shortcut
/// methods with single-character names for brevity.
///
/// Mix this into any class to gain concise logging methods that automatically
/// attach the class name as the log context:
///
/// ```dart
/// class AuthService with LoggerMixin {
///   Future<void> signIn(String email) async {
///     await i('Sign-in attempt for $email');
///     // ...
///   }
/// }
/// ```
mixin LoggerMixin {
  /// Shared [Logger] instance used by all classes that mix in [LoggerMixin].
  static final Logger logger = Logger();

  /// Context label for log events. Defaults to the runtime type name.
  ///
  /// Override to provide a custom label:
  /// ```dart
  /// @override
  /// String get loggerContext => 'AuthModule';
  /// ```
  String get loggerContext => runtimeType.toString();

  /// Emits a [LogLevel.trace] event.
  Future<void> t(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.trace(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  /// Emits a [LogLevel.debug] event.
  Future<void> d(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.debug(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  /// Emits a [LogLevel.info] event.
  Future<void> i(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.info(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  /// Emits a [LogLevel.warn] event.
  Future<void> w(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.warn(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  /// Emits a [LogLevel.error] event.
  Future<void> e(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.error(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );

  /// Emits a [LogLevel.fatal] event.
  Future<void> f(Object message, {Object? error, StackTrace? stackTrace}) =>
      logger.fatal(
        message,
        error: error,
        stackTrace: stackTrace,
        context: loggerContext,
      );
}
