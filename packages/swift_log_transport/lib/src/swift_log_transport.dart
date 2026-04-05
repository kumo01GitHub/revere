import 'package:revere/core.dart';

import 'swift_log_transport_platform_interface.dart';

/// Forwards log events to Apple's swift-log via a platform channel.
///
/// Requires the companion Swift package in the iOS/macOS runner. Each Dart
/// [LogLevel] is mapped to the corresponding `swift-log` log level.
///
/// config keys:
/// - `label` (String): logger label passed to swift-log. Defaults to `null`.
/// - `metadata` (Map\<String, String\>): static metadata attached to every event.
/// - `format` (String): message template; supports `{level}`, `{message}`,
///   `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`.
class SwiftLogTransport extends Transport {
  /// Logger label forwarded to swift-log. When `null` the platform default is used.
  final String? label;

  /// Static metadata entries attached to every log event.
  final Map<String, String>? metadata;

  /// Message template applied to each event before forwarding.
  final String format;

  /// Creates a [SwiftLogTransport].
  ///
  /// Options are read from [config] when available.
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
