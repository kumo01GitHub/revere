import 'log_level.dart';
import 'logger.dart';

/// Mixin that adds automatic error logging to any class via a [Logger].
///
/// The default logger is a shared singleton. Override [logger] to inject a
/// custom or pre-configured instance from the application layer.
///
/// Example:
/// ```dart
/// class CheckoutService with ErrorTrackerMixin {
///   @override
///   Logger get logger => MyApp.logger;
///
///   Future<void> purchase(Item item) {
///     return guarded(() async {
///       // any error here is automatically logged
///       await _api.purchase(item);
///     });
///   }
/// }
/// ```
mixin ErrorTrackerMixin {
  static final Logger _defaultLogger = Logger();

  /// The [Logger] used for all error tracking calls.
  ///
  /// Override to provide a custom instance configured by the application.
  Logger get logger => _defaultLogger;

  /// Context label embedded in log events. Defaults to the runtime type name.
  String get trackerContext => runtimeType.toString();

  /// Records an error to [logger].
  ///
  /// Set [fatal] to `true` to mark the event at [LogLevel.fatal].
  Future<void> trackError(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    bool fatal = false,
  }) {
    return logger.log(
      fatal ? LogLevel.fatal : LogLevel.error,
      message ?? error.toString(),
      error: error,
      stackTrace: stackTrace,
      context: trackerContext,
    );
  }

  /// Runs [body], logging [action] at [LogLevel.info] on entry.
  ///
  /// If [body] throws, the exception is recorded via [trackError] and
  /// re-thrown so the caller can still handle it.
  ///
  /// Optional [params] are appended to the log message as `key=value` pairs.
  Future<T> withTracking<T>(
    String action,
    Future<T> Function() body, {
    Map<String, dynamic>? params,
  }) async {
    final String message = (params != null && params.isNotEmpty)
        ? '$action: ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}'
        : action;
    await logger.info(message, context: trackerContext);
    try {
      return await body();
    } catch (e, st) {
      await trackError(e, stackTrace: st, message: 'Error during $action');
      rethrow;
    }
  }

  /// Runs [body] and automatically logs any thrown error.
  ///
  /// Simpler than [withTracking] — no action name is required. Use this when
  /// you only need error protection without action logging.
  ///
  /// ```dart
  /// Future<void> fetchUser(String id) => guarded(() async {
  ///   final data = await api.getUser(id);
  ///   setState(() => _user = data);
  /// });
  /// ```
  ///
  /// The error is re-thrown after recording so the caller can still handle it.
  Future<T> guarded<T>(Future<T> Function() body, {bool fatal = false}) async {
    try {
      return await body();
    } catch (e, st) {
      await trackError(e, stackTrace: st, fatal: fatal);
      rethrow;
    }
  }
}
