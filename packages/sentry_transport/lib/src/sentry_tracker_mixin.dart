import 'dart:async' show unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:revere/core.dart';
import 'sentry_transport.dart';

/// Mixin that adds breadcrumb tracking (→ Sentry breadcrumbs) and error
/// reporting (→ Sentry captureException) to any class via a [Logger] backed
/// by [SentryTransport].
///
/// The default transport and logger are shared singletons. Override
/// [sentryTransport] and [logger] together to inject custom instances.
///
/// Example:
/// ```dart
/// class CheckoutService with SentryTrackerMixin {
///   @override
///   SentryTransport get sentryTransport => _myTransport;
///   @override
///   Logger get logger => Logger([_myTransport]);
///
///   Future<void> purchase(Item item) {
///     return withTracking(
///       'purchase',
///       () async { /* ... */ },
///       params: {'item_id': item.id},
///     );
///   }
/// }
/// ```
mixin SentryTrackerMixin {
  static final SentryTransport _defaultTransport = SentryTransport();

  /// The [SentryTransport] backing the [logger].
  ///
  /// Override to provide a custom instance (e.g. for testing or a
  /// differently-configured transport). The [logger] is automatically
  /// constructed from this value, so overriding [sentryTransport] alone
  /// is sufficient.
  SentryTransport get sentryTransport => _defaultTransport;

  /// The [Logger] used for all tracking calls.
  ///
  /// Lazily initialised from [sentryTransport] on first access. Override
  /// only when you need full control over the [Logger] configuration.
  late final Logger _logger = Logger([sentryTransport]);
  Logger get logger => _logger;

  /// Context label embedded in log events. Defaults to the runtime type name.
  String get trackerContext => runtimeType.toString();

  /// Records a breadcrumb to Sentry.
  ///
  /// [action] becomes the log message. [params] are appended to the message
  /// as `key=value` pairs.
  Future<void> trackAction(String action, {Map<String, dynamic>? params}) {
    final String message = (params != null && params.isNotEmpty)
        ? '$action: ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}'
        : action;
    return logger.info(message, context: trackerContext);
  }

  /// Reports an error to Sentry via [logger].
  ///
  /// When [LogEvent.error] is set, `SentryTransport` calls
  /// `Sentry.captureException`. Set [fatal] to `true` to mark the event as a
  /// fatal crash.
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

  /// Runs [body], recording [action] as a breadcrumb on entry.
  ///
  /// If [body] throws, the exception is captured via [trackError] and
  /// re-thrown so the caller can still handle it.
  Future<T> withTracking<T>(
    String action,
    Future<T> Function() body, {
    Map<String, dynamic>? params,
  }) async {
    await trackAction(action, params: params);
    try {
      return await body();
    } catch (e, st) {
      await trackError(e, stackTrace: st, message: 'Error during $action');
      rethrow;
    }
  }

  /// Runs [body] and automatically captures any thrown error to Sentry.
  ///
  /// Simpler than [withTracking] — no action name is required. Use this when
  /// you only need error protection without breadcrumb logging.
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

  /// Installs global Flutter error handlers that forward all uncaught errors
  /// to Sentry via [sentryTransport].
  ///
  /// Call this once in `main()` after `WidgetsFlutterBinding.ensureInitialized()`:
  ///
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   MyService().setupFlutterErrorTracking();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Hooks installed:
  /// - [FlutterError.onError] — Flutter framework / widget build errors.
  /// - [PlatformDispatcher.instance.onError] — uncaught Dart async errors.
  ///
  /// Any previously installed handler is preserved and called first.
  void setupFlutterErrorTracking() {
    final prevFlutter = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      prevFlutter?.call(details);
      unawaited(
        trackError(
          details.exception,
          stackTrace: details.stack,
          message: details.exceptionAsString(),
        ),
      );
    };

    final prevPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      prevPlatform?.call(error, stack);
      unawaited(trackError(error, stackTrace: stack, fatal: true));
      // Return false so the runtime still treats this as unhandled and
      // terminates / reports the crash normally.
      return false;
    };
  }
}
