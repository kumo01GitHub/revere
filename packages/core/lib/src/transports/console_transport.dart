import '../transport.dart';
import '../log_level.dart';
import '../log_event.dart';
import '../utils/ansi_color.dart';

/// Transport for console (stdout) output.
///
/// config keys:
/// - `format` (String): log line template; supports `{level}`, `{message}`,
///   `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`.
/// - `colorize` (bool): wrap output in ANSI colors (default `true`).
class ConsoleTransport extends Transport {
  /// Log line template. Supports `{level}`, `{message}`, `{timestamp}`,
  /// `{error}`, `{stackTrace}`, `{context}` placeholders.
  final String format;

  /// Whether to wrap output in ANSI colors. Defaults to `true`.
  final bool colorize;

  /// Creates a [ConsoleTransport].
  ///
  /// Reads `format` and `colorize` from [config] when available.
  ConsoleTransport({super.level, super.config})
    : format =
          (config['format'] as String?) ??
          '{timestamp} [{context}:{level}] {message} {error} {stackTrace}',
      colorize = (config['colorize'] as bool?) ?? true;

  @override
  Future<void> emitLog(LogEvent event) async {
    final logMsg = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message.toString())
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '')
        .replaceAll('{context}', event.context ?? '');
    final outputMsg = colorize ? _colorize(logMsg, event.level) : logMsg;
    // ignore: avoid_print
    print(outputMsg);
  }

  String _colorize(String msg, LogLevel level) {
    return switch (level) {
      LogLevel.trace => AnsiColor.wrap(msg, AnsiColor.cyan),
      LogLevel.debug => AnsiColor.wrap(msg, AnsiColor.blue),
      LogLevel.info => AnsiColor.wrap(msg, AnsiColor.green),
      LogLevel.warn => AnsiColor.wrap(msg, AnsiColor.yellow),
      LogLevel.error => AnsiColor.wrap(msg, AnsiColor.red),
      LogLevel.fatal => AnsiColor.wrap(msg, AnsiColor.magenta),
    };
  }
}
