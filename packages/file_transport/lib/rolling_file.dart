import 'dart:io';
import 'package:revere/core.dart';

/// RollingFile utility (for internal use)
class RollingFile {
  final String filePath;
  final int maxBytes;
  final int maxFiles;

  RollingFile(this.filePath, {this.maxBytes = 1024 * 1024, this.maxFiles = 5});

  Future<void> write(String line) async {
    final file = File(filePath);
    // Check if rolling is needed
    if (await file.exists() && await file.length() + line.length > maxBytes) {
      await _rollFiles();
    }
    await file.writeAsString(line + '\n', mode: FileMode.append, flush: true);
  }

  Future<void> _rollFiles() async {
    // Delete the oldest file if maxFiles reached
    final oldest = File(_fileName(maxFiles - 1));
    if (await oldest.exists()) {
      await oldest.delete();
    }
    // Shift files: N-2 -> N-1, ..., 0 -> 1
    for (int i = maxFiles - 2; i >= 0; i--) {
      final src = File(_fileName(i));
      if (await src.exists()) {
        await src.rename(_fileName(i + 1));
      }
    }
    // Rename current file to .0
    final current = File(filePath);
    if (await current.exists()) {
      await current.rename(_fileName(0));
    }
  }

  String _fileName(int index) {
    if (index == 0) {
      return filePath + '.0';
    }
    return filePath + '.$index';
  }
}

/// RollingFileTransport: Transport implementation for rolling file output
class RollingFileTransport extends Transport {
  final RollingFile rollingFile;

  RollingFileTransport(
    String? filePath, {
    int? maxBytes,
    int? maxFiles,
    super.level,
    super.config,
  }) : rollingFile = RollingFile(
          filePath ??
              (config['filePath'] is String
                  ? config['filePath'] as String
                  : ''),
          maxBytes: maxBytes ??
              (config['maxBytes'] is int
                  ? config['maxBytes'] as int
                  : 1024 * 1024),
          maxFiles: maxFiles ??
              (config['maxFiles'] is int ? config['maxFiles'] as int : 5),
        ) {
    if (rollingFile.filePath.isEmpty) {
      throw ArgumentError(
          'filePath must be provided either as argument or in config');
    }
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    final ts = event.timestamp.toIso8601String();
    final ctx = event.context != null ? ' [${event.context}]' : '';
    final err = event.error != null ? ' error: ${event.error}' : '';
    final stack = event.stackTrace != null ? '\n${event.stackTrace}' : '';
    final line = '[$ts] [${event.level.name}] ${event.message}$err$stack$ctx';
    await rollingFile.write(line);
  }
}
