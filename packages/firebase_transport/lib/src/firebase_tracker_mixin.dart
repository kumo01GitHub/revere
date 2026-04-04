import 'dart:async' show unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:revere/core.dart';
import 'firebase_transport.dart';

/// Mixin that adds action tracking (→ Firebase Analytics) and error reporting
/// (→ Firebase Crashlytics) to any class via [FirebaseTransport].
///
/// The default transport is a shared singleton. Override [firebaseTransport]
/// to inject a custom or pre-initialized instance.
///
/// Example:
/// ```dart
/// class CheckoutService with FirebaseTrackerMixin {
///   @override
///   FirebaseTransport get firebaseTransport => _myTransport;
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
mixin FirebaseTrackerMixin {
  static final FirebaseTransport _defaultTransport = FirebaseTransport();

  /// The [FirebaseTransport] used for all tracking calls.
  ///
  /// Override to provide a custom instance.
  FirebaseTransport get firebaseTransport => _defaultTransport;

  /// Context label embedded in log events. Defaults to the runtime type name.
  String get trackerContext => runtimeType.toString();

  /// Records a user action to Firebase Analytics.
  ///
  /// [action] becomes the log message. [params] are appended to the message
  /// as `key=value` pairs (Analytics parameters are currently carried via the
  /// message string; extend [FirebaseTransport] if you need structured params).
  Future<void> trackAction(
    String action, {
    Map<String, dynamic>? params,
  }) {
    final String message = (params != null && params.isNotEmpty)
        ? '$action: ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}'
        : action;
    return firebaseTransport.log(LogEvent(
      level: LogLevel.info,
      message: message,
      context: trackerContext,
    ));
  }

  /// Records an error to Firebase Crashlytics (via [FirebaseTransport]).
  ///
  /// Set [fatal] to `true` to mark the event as a fatal crash.
  Future<void> trackError(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    bool fatal = false,
  }) {
    return firebaseTransport.log(LogEvent(
      level: fatal ? LogLevel.fatal : LogLevel.error,
      message: message ?? error.toString(),
      error: error,
      stackTrace: stackTrace,
      context: trackerContext,
    ));
  }

  /// Runs [body], logging [action] on entry.
  ///
  /// If [body] throws, the exception is recorded via [trackError] and
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

  /// Runs [body] and automatically records any thrown error to Crashlytics.
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
  Future<T> guarded<T>(
    Future<T> Function() body, {
    bool fatal = false,
  }) async {
    try {
      return await body();
    } catch (e, st) {
      await trackError(e, stackTrace: st, fatal: fatal);
      rethrow;
    }
  }

  /// Installs global Flutter error handlers that forward all uncaught errors
  /// to Firebase Crashlytics via [firebaseTransport].
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
      unawaited(trackError(
        details.exception,
        stackTrace: details.stack,
        message: details.exceptionAsString(),
      ));
    };

    final prevPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      prevPlatform?.call(error, stack);
      unawaited(trackError(error, stackTrace: stack, fatal: true));
      // Return false so the runtime still treats this as unhandled and
      // terminates / reports the crash normally. Returning true would
      // suppress the crash and swallow the error.
      return false;
    };
  }
}
