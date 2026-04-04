import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:revere/pretty_console_transport.dart';

LogEvent _event(
  LogLevel level,
  String msg, {
  Object? error,
  StackTrace? stackTrace,
  String? context,
}) => LogEvent(
  level: level,
  message: msg,
  error: error,
  stackTrace: stackTrace,
  context: context,
  timestamp: DateTime(2024, 1, 15, 12, 34, 56, 789),
);

/// Subclass that captures print() output via a Zone instead of hitting stdout.
class _TestPrettyTransport extends PrettyConsoleTransport {
  final List<String> lines;

  _TestPrettyTransport(this.lines, {super.config});

  @override
  Future<void> emitLog(LogEvent event) async {
    final captured = <String>[];
    await runZoned(
      () => super.emitLog(event),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => captured.add(line),
      ),
    );
    lines.addAll(captured);
  }
}

void main() {
  group('PrettyConsoleTransport', () {
    test('emitLog does not throw for all levels', () async {
      final t = PrettyConsoleTransport(
        level: LogLevel.trace,
        config: {'colorize': false},
      );
      for (final level in LogLevel.values) {
        await expectLater(t.log(_event(level, 'test message')), completes);
      }
    });

    test('level threshold suppresses below-threshold events', () async {
      final t = PrettyConsoleTransport(
        level: LogLevel.error,
        config: {'colorize': false},
      );
      await t.log(_event(LogLevel.debug, 'suppressed'));
    });

    test('context is included when showContext=true', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showContext': true},
      );
      await t.emitLog(_event(LogLevel.info, 'hello', context: 'MyApp'));
      expect(lines.join(''), contains('[MyApp]'));
    });

    test('context omitted when showContext=false', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showContext': false},
      );
      await t.emitLog(_event(LogLevel.info, 'hello', context: 'MyApp'));
      expect(lines.join(''), isNot(contains('[MyApp]')));
    });

    test('timestamp included when showTimestamp=true', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showTimestamp': true},
      );
      await t.emitLog(_event(LogLevel.info, 'hello'));
      expect(lines.join(''), contains('12:34:56.789'));
    });

    test('timestamp omitted when showTimestamp=false', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showTimestamp': false},
      );
      await t.emitLog(_event(LogLevel.info, 'hello'));
      expect(lines.join(''), isNot(contains('12:34:56')));
    });

    test('error appended with arrow prefix', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(lines, config: {'colorize': false});
      await t.emitLog(_event(LogLevel.error, 'boom', error: Exception('oops')));
      final out = lines.join('');
      expect(out, contains('↳'));
      expect(out, contains('oops'));
    });

    test('stackTrace appended when showStackTrace=true', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showStackTrace': true},
      );
      final trace = StackTrace.fromString('#0  main (file:///test.dart:1:1)');
      await t.emitLog(_event(LogLevel.error, 'boom', stackTrace: trace));
      expect(lines.join('\n'), contains('#0  main'));
    });

    test('stackTrace omitted when showStackTrace=false', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(
        lines,
        config: {'colorize': false, 'showStackTrace': false},
      );
      final trace = StackTrace.fromString('#0  main (file:///test.dart:1:1)');
      await t.emitLog(_event(LogLevel.error, 'boom', stackTrace: trace));
      expect(lines.join('\n'), isNot(contains('#0  main')));
    });

    test('correct emoji for each level', () async {
      final emojis = {
        LogLevel.trace: '🔍',
        LogLevel.debug: '🐛',
        LogLevel.info: 'ℹ️',
        LogLevel.warn: '⚠️',
        LogLevel.error: '🔥',
        LogLevel.fatal: '💀',
      };
      for (final entry in emojis.entries) {
        final lines = <String>[];
        final t = _TestPrettyTransport(lines, config: {'colorize': false});
        await t.emitLog(_event(entry.key, 'msg'));
        expect(lines.join(''), contains(entry.value));
      }
    });

    test('colorize wraps output in ANSI escape codes', () async {
      final lines = <String>[];
      final t = _TestPrettyTransport(lines, config: {'colorize': true});
      await t.emitLog(_event(LogLevel.info, 'hello'));
      expect(lines.join(''), contains('\x1B'));
    });
  });
}
