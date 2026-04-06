import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Sends log events to Firebase Analytics.
///
/// Each event name is derived from [config['name']] (default `'revere'`),
/// with `{context}` and `{level}` placeholders replaced at runtime.
///
/// config keys: `format` (String), `name` (String), `callOptions`.
class AnalyticsTransport extends Transport {
  /// Log message template. Supports `{level}`, `{message}`, `{timestamp}`,
  /// `{context}`, `{error}`, `{stackTrace}` placeholders.
  final String format;

  /// Analytics event name template. Supports `{context}` and `{level}`.
  /// Defaults to `'revere'`.
  final String name;

  /// Optional [AnalyticsCallOptions] forwarded to Firebase Analytics.
  final AnalyticsCallOptions? callOptions;

  /// Creates an [AnalyticsTransport].
  ///
  /// Options are read from [config] when available.
  AnalyticsTransport({super.level, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}',
        name = (config['name'] as String?) ?? 'revere',
        callOptions = config['callOptions'] as AnalyticsCallOptions?;

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

    final params = <String, Object>{
      'level': event.level.name,
      'message': msg,
      'timestamp': event.timestamp.toIso8601String(),
      if (event.context != null) 'context': event.context!,
      if (event.error != null) 'error': event.error.toString(),
      if (event.stackTrace != null) 'stackTrace': event.stackTrace.toString(),
    };

    await dispatchEvent(eventName, params, callOptions);
  }

  @protected
  Future<void> dispatchEvent(
    String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  ) async {
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
      callOptions: callOptions,
    );
  }
}
