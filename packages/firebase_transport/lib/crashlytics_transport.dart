import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// CrashlyticsTransport: sends logs to Firebase Crashlytics only.
class CrashlyticsTransport extends Transport {
  final String format;

  CrashlyticsTransport({super.level, super.config})
      : format =
            (config['format'] as String?) ?? '[{level}:{context}] {message}';

  @override
  Future<void> emitLog(LogEvent event) async {
    final msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message)
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
