import 'package:revere/core.dart';

import 'android_log_transport_platform_interface.dart';

/// Forwards log events to Android's Logcat via a platform channel.
///
/// config keys: `tag` (String), `format` (String).
class AndroidLogTransport extends Transport {
  final String? tag;
  final String format;

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
