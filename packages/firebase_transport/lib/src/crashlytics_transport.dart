import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Sends log events to Firebase Crashlytics as log messages.
///
/// config keys: `format` (String).
class CrashlyticsTransport extends Transport {
  /// Log message template. Supports `{level}`, `{message}`, `{timestamp}`,
  /// `{context}`, `{error}`, `{stackTrace}` placeholders.
  final String format;

  /// Creates a [CrashlyticsTransport].
  ///
  /// `format` may be customised via [config].
  CrashlyticsTransport({super.level, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}';

  @override
  Future<void> emitLog(LogEvent event) async {
    final msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message.toString())
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{context}', event.context ?? '')
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '');
    await dispatchLog(msg);
  }

  @protected
  Future<void> dispatchLog(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }
}
