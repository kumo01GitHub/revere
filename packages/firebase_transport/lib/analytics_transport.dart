import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// AnalyticsTransport: sends logs to Firebase Analytics only.
class AnalyticsTransport extends Transport {
  final String format;
  final String name;
  final AnalyticsCallOptions? callOptions;

  AnalyticsTransport({super.level, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}',
        name = (config['name'] as String?) ?? 'revere',
        callOptions = config['callOptions'] as AnalyticsCallOptions?;

  @override
  Future<void> emitLog(LogEvent event) async {
    final String name = this
        .name
        .replaceAll('{context}', event.context ?? '')
        .replaceAll('{level}', event.level.name);

    final msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message)
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

    await dispatchEvent(name, params, callOptions);
  }

  @protected
  Future<void> dispatchEvent(
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
}
