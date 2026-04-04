import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/analytics_transport.dart';

class _FakeAnalyticsTransport extends AnalyticsTransport {
  final List<(String, Map<String, dynamic>, AnalyticsCallOptions?)> calls = [];

  _FakeAnalyticsTransport({super.level, super.config});

  @override
  Future<void> dispatchEvent(
    String name,
    Map<String, dynamic> parameters,
    AnalyticsCallOptions? callOptions,
  ) async {
    calls.add((name, parameters, callOptions));
  }
}

void main() {
  group('AnalyticsTransport', () {
    // --- level threshold ---

    test('does not call dispatchEvent below threshold', () async {
      final t = _FakeAnalyticsTransport(level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.info, message: 'ignored'));
      expect(t.calls, isEmpty);
    });

    test('calls dispatchEvent at threshold level', () async {
      final t = _FakeAnalyticsTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(t.calls, hasLength(1));
    });

    test('calls dispatchEvent above threshold level', () async {
      final t = _FakeAnalyticsTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.error, message: 'error'));
      expect(t.calls, hasLength(1));
    });

    // --- event name ---

    test('default event name is revere', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$1, 'revere');
    });

    test('custom name template replaces {level}', () async {
      final t = _FakeAnalyticsTransport(config: {'name': 'app_{level}'});
      await t.emitLog(LogEvent(level: LogLevel.error, message: 'crash'));
      expect(t.calls.first.$1, 'app_error');
    });

    test('custom name template replaces {context}', () async {
      final t = _FakeAnalyticsTransport(config: {'name': '{context}_log'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'auth'),
      );
      expect(t.calls.first.$1, 'auth_log');
    });

    test('null context in name template replaced with empty string', () async {
      final t = _FakeAnalyticsTransport(config: {'name': '{context}_log'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$1, '_log');
    });

    // --- event parameters ---

    test('parameters contain level string', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.warn, message: 'msg'));
      expect(t.calls.first.$2['level'], 'warn');
    });

    test('parameters contain context', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'auth'),
      );
      expect(t.calls.first.$2['context'], 'auth');
    });

    test('parameters contain null context when not provided', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$2['context'], isNull);
    });

    test('parameters contain ISO-8601 timestamp', () async {
      final ts = DateTime.parse('2024-06-01T00:00:00.000Z');
      final t = _FakeAnalyticsTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(t.calls.first.$2['timestamp'], ts.toIso8601String());
    });

    test('parameters contain error string when present', () async {
      final t = _FakeAnalyticsTransport();
      final err = Exception('oops');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'fail', error: err),
      );
      expect(t.calls.first.$2['error'], err.toString());
    });

    test('parameters do not contain error key when error is null', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$2.containsKey('error'), isFalse);
    });

    test('parameters contain stackTrace string when present', () async {
      final t = _FakeAnalyticsTransport();
      final trace = StackTrace.fromString('#0 main (file.dart:1:1)');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(t.calls.first.$2['stackTrace'], trace.toString());
    });

    test('parameters do not contain stackTrace key when absent', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$2.containsKey('stackTrace'), isFalse);
    });

    // --- message format ---

    test('default format is [level:context] message', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(
        LogEvent(
            level: LogLevel.info,
            message: 'hello',
            context: 'auth',
            timestamp: DateTime.parse('2024-01-01T00:00:00.000Z')),
      );
      expect(t.calls.first.$2['message'], '[info:auth] hello');
    });

    test('custom format replaces {level}', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '{level}: {message}'});
      await t.emitLog(LogEvent(level: LogLevel.warn, message: 'something'));
      expect(t.calls.first.$2['message'], 'warn: something');
    });

    test('custom format replaces {context}', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '[{context}] {message}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'ping', context: 'svc'),
      );
      expect(t.calls.first.$2['message'], '[svc] ping');
    });

    test('null context in format replaced with empty string', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '[{context}] {message}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ping'));
      expect(t.calls.first.$2['message'], '[] ping');
    });

    test('format replaces {timestamp}', () async {
      final ts = DateTime.parse('2024-03-01T08:00:00.000Z');
      final t = _FakeAnalyticsTransport(config: {'format': '{timestamp}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(t.calls.first.$2['message'], ts.toIso8601String());
    });

    test('format replaces {error} with empty string when null', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '{message}|{error}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(t.calls.first.$2['message'], 'ok|');
    });

    test('format replaces {stackTrace} when present', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '{message}|{stackTrace}'});
      final trace = StackTrace.fromString('frame0');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(t.calls.first.$2['message'], 'crash|${trace.toString()}');
    });

    test('format replaces {stackTrace} with empty string when null', () async {
      final t =
          _FakeAnalyticsTransport(config: {'format': '{message}|{stackTrace}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(t.calls.first.$2['message'], 'ok|');
    });

    // --- callOptions ---

    test('callOptions defaults to null', () async {
      final t = _FakeAnalyticsTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$3, isNull);
    });

    test('callOptions forwarded when configured', () async {
      final opts = AnalyticsCallOptions(global: true);
      final t = _FakeAnalyticsTransport(config: {'callOptions': opts});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.calls.first.$3, same(opts));
    });
  });
}
