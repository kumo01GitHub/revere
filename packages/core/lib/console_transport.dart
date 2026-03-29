import 'transport.dart';
import 'log_level.dart';
import 'log_event.dart';
import 'ansi_color.dart';

/// Transport for console output
class ConsoleTransport extends Transport {
  final String format;
  final bool colorize;

  /// config: {`format`: String, `colorize`: bool}
  ConsoleTransport({super.level, super.config})
    : format =
          (config['format'] as String?) ??
          '{timestamp} [{context}:{level}] {message} {error} {stackTrace}',
      colorize = (config['colorize'] as bool?) ?? true;

  @override
  Future<void> emitLog(LogEvent event) async {
    final logMsg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message)
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '')
        .replaceAll('{context}', event.context ?? '');
    final colorize = config['colorize'] as bool? ?? true;
    final outputMsg = colorize ? _colorize(logMsg, event.level) : logMsg;
    // ignore: avoid_print
    print(outputMsg);
  }

  String _colorize(String msg, LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return AnsiColor.wrap(msg, AnsiColor.cyan);
      case LogLevel.debug:
        return AnsiColor.wrap(msg, AnsiColor.blue);
      case LogLevel.info:
        return AnsiColor.wrap(msg, AnsiColor.green);
      case LogLevel.warn:
        return AnsiColor.wrap(msg, AnsiColor.yellow);
      case LogLevel.error:
        return AnsiColor.wrap(msg, AnsiColor.red);
      case LogLevel.fatal:
        return AnsiColor.wrap(msg, AnsiColor.magenta);
    }
  }
}
