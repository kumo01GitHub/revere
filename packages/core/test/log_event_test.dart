import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';

void main() {
  group('LogEvent', () {
    // --- required fields ---

    test('level is stored as supplied', () {
      for (final level in LogLevel.values) {
        final e = LogEvent(level: level, message: 'msg');
        expect(e.level, level, reason: '$level');
      }
    });

    test('message is stored as supplied (String)', () {
      final e = LogEvent(level: LogLevel.info, message: 'hello');
      expect(e.message, 'hello');
    });

    test('message can be a non-String object', () {
      final obj = {'key': 'value'};
      final e = LogEvent(level: LogLevel.info, message: obj);
      expect(e.message, same(obj));
    });

    // --- optional fields ---

    test('error defaults to null', () {
      final e = LogEvent(level: LogLevel.info, message: 'msg');
      expect(e.error, isNull);
    });

    test('error is stored when provided', () {
      final err = Exception('oops');
      final e = LogEvent(level: LogLevel.error, message: 'fail', error: err);
      expect(e.error, same(err));
    });

    test('stackTrace defaults to null', () {
      final e = LogEvent(level: LogLevel.info, message: 'msg');
      expect(e.stackTrace, isNull);
    });

    test('stackTrace is stored when provided', () {
      final trace = StackTrace.fromString('#0 main (file.dart:1:1)');
      final e = LogEvent(
        level: LogLevel.error,
        message: 'crash',
        stackTrace: trace,
      );
      expect(e.stackTrace, same(trace));
    });

    test('context defaults to null', () {
      final e = LogEvent(level: LogLevel.info, message: 'msg');
      expect(e.context, isNull);
    });

    test('context is stored when provided', () {
      final e = LogEvent(level: LogLevel.info, message: 'msg', context: 'auth');
      expect(e.context, 'auth');
    });

    // --- timestamp ---

    test('timestamp defaults to approximately now', () {
      final before = DateTime.now();
      final e = LogEvent(level: LogLevel.info, message: 'msg');
      final after = DateTime.now();
      expect(
        e.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        e.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('timestamp is stored when explicitly provided', () {
      final ts = DateTime.parse('2024-01-01T00:00:00.000Z');
      final e = LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts);
      expect(e.timestamp, ts);
    });
  });

  group('LogLevel', () {
    test('values are ordered trace < debug < info < warn < error < fatal', () {
      final levels = LogLevel.values;
      for (var i = 0; i < levels.length - 1; i++) {
        expect(
          levels[i].index,
          lessThan(levels[i + 1].index),
          reason: '${levels[i]} should be less than ${levels[i + 1]}',
        );
      }
    });

    test('has exactly 6 levels', () {
      expect(LogLevel.values.length, 6);
    });

    test('level names match enum names', () {
      expect(LogLevel.trace.name, 'trace');
      expect(LogLevel.debug.name, 'debug');
      expect(LogLevel.info.name, 'info');
      expect(LogLevel.warn.name, 'warn');
      expect(LogLevel.error.name, 'error');
      expect(LogLevel.fatal.name, 'fatal');
    });
  });
}
