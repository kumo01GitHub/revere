import 'dart:io';

import 'package:revere/core.dart';

/// Writes logs to a single file (append-only).
///
/// See [RollingFileTransport] for size-based rotation.
class FileTransport extends Transport {
  final String filePath;

  FileTransport(
    String? filePath, {
    super.level,
    super.config,
  }) : filePath = filePath ??
            (config['filePath'] is String ? config['filePath'] as String : '') {
    if (this.filePath.isEmpty) {
      throw ArgumentError(
        'filePath must be provided either as argument or in config',
      );
    }
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    final line = _format(event);
    final file = File(filePath);
    await file.writeAsString(line + '\n', mode: FileMode.append, flush: true);
  }

  String _format(LogEvent event) {
    final ts = event.timestamp.toIso8601String();
    final ctx = event.context != null ? ' [${event.context}]' : '';
    final err = event.error != null ? ' error: ${event.error}' : '';
    final stack = event.stackTrace != null ? '\n${event.stackTrace}' : '';
    return '[$ts] [${event.level.name}] ${event.message}$err$stack$ctx';
  }
}
