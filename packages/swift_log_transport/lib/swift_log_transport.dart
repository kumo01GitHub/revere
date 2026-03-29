import 'package:revere/core.dart';
import 'swift_log_transport_platform_interface.dart';

/// SwiftLog transport for revere logger.
/// Uses platform channel to send logs to Apple swift-log.
class SwiftLogTransport extends Transport {
  /// Custom logger label. If null, uses 'revere'.
  final String? label;

  /// Custom metadata to add to each log.
  final Map<String, String>? metadata;

  /// Custom log message format. If null, uses default.
  final String format;

  SwiftLogTransport({
    super.level,
    super.config,
  })  : label = config['label'] as String?,
        metadata = config['metadata'] as Map<String, String>?,
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
