import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:sentry_flutter/sentry_flutter.dart' hide Transport;

/// Sends log events to Sentry.
///
/// Routing rules:
/// - **[LogLevel.error] / [LogLevel.fatal]**, or any event where
///   [LogEvent.error] is non-null → [Sentry.captureException] (fatal only
///   for [LogLevel.fatal]).
/// - **All other levels** → [Sentry.addBreadcrumb].
///
/// config keys (all optional):
/// | key | type | description |
/// |-----|------|-------------|
/// | `format` | String | Breadcrumb message template. Placeholders: `{level}`, `{message}`, `{timestamp}`, `{context}`, `{error}`, `{stackTrace}`. Default: `'[{level}:{context}] {message}'`. |
class SentryTransport extends Transport {
  /// Breadcrumb message template.
  final String format;

  /// Creates a [SentryTransport].
  SentryTransport({super.level = LogLevel.info, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}';

  @override
  Future<void> emitLog(LogEvent event) async {
    final isError = event.level == LogLevel.error ||
        event.level == LogLevel.fatal ||
        event.error != null;

    if (isError) {
      await dispatchException(
        event.error ?? event.message,
        stackTrace: event.stackTrace,
        fatal: event.level == LogLevel.fatal,
        hint: Hint.withMap({'context': event.context ?? ''}),
      );
    } else {
      final msg = _format(event);
      await dispatchBreadcrumb(
        Breadcrumb(
          message: msg,
          level: _sentryLevel(event.level),
          timestamp: event.timestamp,
          category: event.context,
        ),
      );
    }
  }

  String _format(LogEvent event) => format
      .replaceAll('{level}', event.level.name)
      .replaceAll('{message}', event.message.toString())
      .replaceAll('{timestamp}', event.timestamp.toIso8601String())
      .replaceAll('{context}', event.context ?? '')
      .replaceAll('{error}', event.error?.toString() ?? '')
      .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '');

  SentryLevel _sentryLevel(LogLevel level) => switch (level) {
        LogLevel.trace => SentryLevel.debug,
        LogLevel.debug => SentryLevel.debug,
        LogLevel.info => SentryLevel.info,
        LogLevel.warn => SentryLevel.warning,
        LogLevel.error => SentryLevel.error,
        LogLevel.fatal => SentryLevel.fatal,
      };

  @protected
  Future<void> dispatchBreadcrumb(Breadcrumb breadcrumb) async {
    await Sentry.addBreadcrumb(breadcrumb);
  }

  @protected
  Future<void> dispatchException(
    Object exception, {
    StackTrace? stackTrace,
    bool fatal = false,
    Hint? hint,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint,
      withScope: (scope) => scope.setTag('fatal', '$fatal'),
    );
  }
}
