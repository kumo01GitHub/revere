import '../log_event.dart';
import '../log_level.dart';
import '../transport.dart';
import '../utils/ansi_color.dart';

/// A human-friendly console transport with emoji indicators, aligned level
/// labels, and optional multi-line formatting for errors and stack traces.
///
/// Example output:
/// ```
/// 🐛 DEBUG  12:34:56.789  [MyApp] Hello world
/// ℹ️ INFO   12:34:56.790  [MyApp] Server started
/// ⚠️ WARN   12:34:56.791  [MyApp] Disk usage high
/// 🔥 ERROR  12:34:56.792  [MyApp] Unhandled exception
///           ↳ Exception: something went wrong
///           ↳ #0  main (file:///...:10:5)
/// ```
///
/// config keys:
/// - `colorize` (bool): wrap output in ANSI colors (default `true`).
/// - `showTimestamp` (bool): include HH:mm:ss.SSS timestamp (default `true`).
/// - `showContext` (bool): include the context label (default `true`).
/// - `showStackTrace` (bool): print stack traces when present (default `true`).
class PrettyConsoleTransport extends Transport {
  final bool colorize;
  final bool showTimestamp;
  final bool showContext;
  final bool showStackTrace;

  PrettyConsoleTransport({super.level, super.config})
    : colorize = (config['colorize'] as bool?) ?? true,
      showTimestamp = (config['showTimestamp'] as bool?) ?? true,
      showContext = (config['showContext'] as bool?) ?? true,
      showStackTrace = (config['showStackTrace'] as bool?) ?? true;

  static const _emojis = {
    LogLevel.trace: '🔍',
    LogLevel.debug: '🐛',
    LogLevel.info: 'ℹ️',
    LogLevel.warn: '⚠️',
    LogLevel.error: '🔥',
    LogLevel.fatal: '💀',
  };

  // Right-padded to 5 chars so columns align (FATAL=5, others ≤5).
  static const _labels = {
    LogLevel.trace: 'TRACE',
    LogLevel.debug: 'DEBUG',
    LogLevel.info: 'INFO ',
    LogLevel.warn: 'WARN ',
    LogLevel.error: 'ERROR',
    LogLevel.fatal: 'FATAL',
  };

  static const _colors = {
    LogLevel.trace: AnsiColor.cyan,
    LogLevel.debug: AnsiColor.blue,
    LogLevel.info: AnsiColor.green,
    LogLevel.warn: AnsiColor.yellow,
    LogLevel.error: AnsiColor.red,
    LogLevel.fatal: AnsiColor.magenta,
  };

  @override
  Future<void> emitLog(LogEvent event) async {
    final buffer = StringBuffer();

    // --- Header line ---
    buffer.write('${_emojis[event.level]} ');
    buffer.write('${_labels[event.level]}  ');

    if (showTimestamp) {
      buffer.write('${_formatTime(event.timestamp)}  ');
    }

    if (showContext && event.context != null) {
      buffer.write('[${event.context}] ');
    }

    buffer.write(event.message.toString());

    final headerLine = buffer.toString();

    // --- Error line ---
    String? errorLine;
    if (event.error != null) {
      errorLine = '          ↳ ${event.error}';
    }

    // --- Stack trace lines ---
    List<String>? stackLines;
    if (showStackTrace && event.stackTrace != null) {
      stackLines = event.stackTrace
          .toString()
          .trimRight()
          .split('\n')
          .map((l) => '          ↳ $l')
          .toList();
    }

    // --- Colorize ---
    String output;
    if (colorize) {
      final color = _colors[event.level]!;
      final bold = AnsiColor.bold;
      final reset = AnsiColor.reset;
      final parts = [
        '$bold$color$headerLine$reset',
        if (errorLine != null) '$color$errorLine$reset',
        if (stackLines != null)
          stackLines.map((l) => '$color$l$reset').join('\n'),
      ];
      output = parts.join('\n');
    } else {
      final parts = [
        headerLine,
        ?errorLine,
        if (stackLines != null) stackLines.join('\n'),
      ];
      output = parts.join('\n');
    }

    // ignore: avoid_print
    print(output);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
