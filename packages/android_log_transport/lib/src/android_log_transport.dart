import 'package:revere/core.dart';

import 'android_log_transport_platform_interface.dart';

/// Forwards log events to Android's Logcat via a platform channel.
///
/// Use the standard `adb logcat` command to view output. Each event is sent
/// with the Android log priority that matches the [LogLevel].
///
/// config keys:
/// - `tag` (String): Logcat tag. Defaults to `null` (platform uses app name).
/// - `format` (String): message template; supports `{level}`, `{message}`,
///   `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`.
class AndroidLogTransport extends Transport {
  /// Optional Logcat tag. When `null` the platform falls back to the app name.
  final String? tag;

  /// Message template applied to each event before sending to Logcat.
  final String format;

  /// Creates an [AndroidLogTransport].
  ///
  /// Options are read from [config] when available.
  AndroidLogTransport({super.level, super.config})
      : tag = config['tag'] as String?,
        format = (config['format'] as String?) ?? '{message}';

  @override
  Future<void> emitLog(LogEvent event) async {
    final msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message.toString())
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '')
        .replaceAll('{context}', event.context ?? '');

    await AndroidLogTransportPlatform.instance.log({
      'level': event.level.name,
      'message': msg,
      'timestamp': event.timestamp.toIso8601String(),
      'error': event.error?.toString(),
      'stackTrace': event.stackTrace?.toString(),
      'context': event.context,
      'tag': tag,
    });
  }
}
