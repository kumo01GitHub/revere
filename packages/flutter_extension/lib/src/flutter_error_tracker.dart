import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:revere/core.dart';

/// Provides Flutter error integration for ErrorTrackerMixin.
///
/// Call [setupFlutterErrorTracking] in your main() to forward all uncaught
/// Flutter and platform errors to your logger.
extension FlutterErrorTracker on ErrorTrackerMixin {
  /// Installs global Flutter error handlers that forward all uncaught errors
  /// to [logger].
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
      logger.log(
        LogLevel.error,
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
        context: trackerContext,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logger.log(
        LogLevel.fatal,
        error.toString(),
        error: error,
        stackTrace: stack,
        context: trackerContext,
      );
      return false;
    };
  }
}
