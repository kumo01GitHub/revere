import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Combined Firebase transport that sends every log event to Analytics and
/// additionally forwards errors to Crashlytics.
///
/// Routing rules:
/// - **All levels** → [FirebaseAnalytics.instance.logEvent]
/// - **[LogLevel.error] / [LogLevel.fatal]**, or any event where
///   [LogEvent.error] is non-null → also sent to Crashlytics:
///   - If [LogEvent.error] is present → [FirebaseCrashlytics.instance.recordError]
///     (`fatal: true` only for [LogLevel.fatal]).
///   - If [LogEvent.error] is absent → [FirebaseCrashlytics.instance.log].
///
/// config keys (all optional):
/// | key | type | description |
/// |-----|------|-------------|
/// | `name` | String | Analytics event name template (`{context}`, `{level}`). Default `'revere'`. |
/// | `format` | String | Message body template. Default `'[{level}:{context}] {message}'`. |
/// | `callOptions` | AnalyticsCallOptions | Forwarded to Analytics. |
class FirebaseTransport extends Transport {
  /// Log message body template. Supports `{level}`, `{message}`, `{timestamp}`,
  /// `{context}`, `{error}`, `{stackTrace}` placeholders.
  final String format;

  /// Analytics event name template. Supports `{context}` and `{level}`.
  /// Defaults to `'revere'`.
  final String name;

  /// Optional [AnalyticsCallOptions] forwarded to Firebase Analytics.
  final AnalyticsCallOptions? callOptions;

  /// Creates a [FirebaseTransport].
  ///
  /// Options are read from [config] when available.
  FirebaseTransport({super.level, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}',
        name = (config['name'] as String?) ?? 'revere',
        callOptions = config['callOptions'] as AnalyticsCallOptions?;

  bool _shouldUseCrashlytics(LogEvent event) =>
      event.level == LogLevel.error ||
      event.level == LogLevel.fatal ||
      event.error != null;

  @override
  Future<void> emitLog(LogEvent event) async {
    final String eventName = name
        .replaceAll('{context}', event.context ?? '')
        .replaceAll('{level}', event.level.name);

    final msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message.toString())
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{context}', event.context ?? '')
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '');

    final params = <String, dynamic>{
      'level': event.level.name,
      'message': msg,
      'context': event.context,
      'timestamp': event.timestamp.toIso8601String(),
      if (event.error != null) 'error': event.error.toString(),
      if (event.stackTrace != null) 'stackTrace': event.stackTrace.toString(),
    };

    await dispatchAnalyticsEvent(eventName, params, callOptions);

    if (_shouldUseCrashlytics(event)) {
      if (event.error != null) {
        await dispatchCrashlyticsError(
          event.error!,
          event.stackTrace,
          fatal: event.level == LogLevel.fatal,
          reason: msg,
        );
      } else {
        await dispatchCrashlyticsLog(msg);
      }
    }
  }

  @protected
  Future<void> dispatchAnalyticsEvent(
    String name,
    Map<String, dynamic> parameters,
    AnalyticsCallOptions? callOptions,
  ) async {
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
      callOptions: callOptions,
    );
  }

  @protected
  Future<void> dispatchCrashlyticsError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  @protected
  Future<void> dispatchCrashlyticsLog(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }
}
