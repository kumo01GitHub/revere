import 'package:revere/core.dart';

import 'swift_log_transport_platform_interface.dart';

/// Forwards log events to Apple's swift-log via a platform channel.
///
/// config keys: `label` (String), `metadata` (Map[String, String]), `format` (String).
class SwiftLogTransport extends Transport {
  final String? label;
  final Map<String, String>? metadata;
  final String format;

  SwiftLogTransport({super.level, super.config})
      : label = config['label'] as String?,
        metadata = config['metadata'] as Map<String, String>?,
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

    await SwiftLogTransportPlatform.instance.log({
      'level': event.level.name,
      'message': msg,
      'timestamp': event.timestamp.toIso8601String(),
      'error': event.error?.toString(),
      'stackTrace': event.stackTrace?.toString(),
      'context': event.context,
      'label': label,
      'metadata': metadata,
    });
  }
}
