import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/crashlytics_transport.dart';

class _FakeCrashlyticsTransport extends CrashlyticsTransport {
  final List<String> calls = [];

  _FakeCrashlyticsTransport({super.level, super.config});

  @override
  Future<void> dispatchLog(String message) async {
    calls.add(message);
  }
}

void main() {
  group('CrashlyticsTransport', () {
    // --- level threshold ---

    test('does not call dispatchLog below threshold', () async {
      final t = _FakeCrashlyticsTransport(level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.info, message: 'ignored'));
      expect(t.calls, isEmpty);
    });

    test('calls dispatchLog at threshold level', () async {
      final t = _FakeCrashlyticsTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(t.calls, hasLength(1));
    });

    test('calls dispatchLog above threshold level', () async {
      final t = _FakeCrashlyticsTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.error, message: 'error'));
      expect(t.calls, hasLength(1));
    });

    // --- default format ---

    test('default format is [level:context] message', () async {
      final t = _FakeCrashlyticsTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'hello', context: 'auth'),
      );
      expect(t.calls.first, '[info:auth] hello');
    });

    test('null context in default format replaced with empty string', () async {
      final t = _FakeCrashlyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'hello'));
      expect(t.calls.first, '[info:] hello');
    });

    // --- custom format placeholders ---

    test('custom format replaces {level}', () async {
      final t =
          _FakeCrashlyticsTransport(config: {'format': '{level}: {message}'});
      await t.emitLog(LogEvent(level: LogLevel.error, message: 'crash'));
      expect(t.calls.first, 'error: crash');
    });

    test('custom format replaces {context}', () async {
      final t = _FakeCrashlyticsTransport(
          config: {'format': '[{context}] {message}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'ping', context: 'svc'),
      );
      expect(t.calls.first, '[svc] ping');
    });

    test('null context in custom format replaced with empty string', () async {
      final t = _FakeCrashlyticsTransport(
          config: {'format': '[{context}] {message}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ping'));
      expect(t.calls.first, '[] ping');
    });

    test('format replaces {timestamp}', () async {
      final ts = DateTime.parse('2024-01-01T00:00:00.000Z');
      final t = _FakeCrashlyticsTransport(config: {'format': '{timestamp}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(t.calls.first, ts.toIso8601String());
    });

    test('format replaces {error} with exception string', () async {
      final t =
          _FakeCrashlyticsTransport(config: {'format': '{message} ({error})'});
      final err = Exception('oops');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'failed', error: err),
      );
      expect(t.calls.first, 'failed (${err.toString()})');
    });

    test('format replaces {error} with empty string when null', () async {
      final t =
          _FakeCrashlyticsTransport(config: {'format': '{message}|{error}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(t.calls.first, 'ok|');
    });

    test('format replaces {stackTrace} when present', () async {
      final t = _FakeCrashlyticsTransport(
          config: {'format': '{message}|{stackTrace}'});
      final trace = StackTrace.fromString('#0 main (file.dart:1:1)');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(t.calls.first, 'crash|${trace.toString()}');
    });

    test('format replaces {stackTrace} with empty string when null', () async {
      final t = _FakeCrashlyticsTransport(
          config: {'format': '{message}|{stackTrace}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(t.calls.first, 'ok|');
    });
  });
}
