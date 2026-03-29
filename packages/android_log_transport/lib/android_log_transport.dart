import 'package:revere/core.dart';
import 'android_log_transport_platform_interface.dart';

/// Android Logcat transport for revere logger.
/// Uses platform channel to send logs to Android's Logcat.
class AndroidLogTransport extends Transport {
  /// Custom tag for Logcat. If null, uses 'Revere/{loggerName}'.
  final String? tag;

  /// Custom log message format. If null, uses default.
  final String format;

  AndroidLogTransport({super.level, super.config})
      : tag = config['tag'] as String?,
        format = (config['format'] as String?) ?? '{message}';

  @override
  Future<void> emitLog(LogEvent event) async {
    String msg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message)
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
