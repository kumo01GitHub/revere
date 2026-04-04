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
    test('calls logEvent with formatted message and parameters', () async {
      final transport = _FakeAnalyticsTransport();

      await transport.emitLog(
        LogEvent(
          level: LogLevel.info,
          message: 'hello',
          context: 'auth',
          timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
      );

      expect(transport.calls, hasLength(1));
      final (name, params, options) = transport.calls.first;
      expect(name, 'revere');
      expect(params['level'], 'info');
      expect(params['message'], '[info:auth] hello');
      expect(params['context'], 'auth');
      expect(options, isNull);
    });

    test('uses custom name template', () async {
      final transport =
          _FakeAnalyticsTransport(config: {'name': 'app_{level}'});

      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash'),
      );

      expect(transport.calls.first.$1, 'app_error');
    });

    test('uses custom format template', () async {
      final transport = _FakeAnalyticsTransport(
        config: {'format': '{level}: {message}'},
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.warn, message: 'something'),
      );

      expect(transport.calls.first.$2['message'], 'warn: something');
    });

    test('includes error and stackTrace when present', () async {
      final transport = _FakeAnalyticsTransport();

      final error = Exception('oops');
      final stack = StackTrace.current;
      await transport.emitLog(
        LogEvent(
          level: LogLevel.error,
          message: 'failed',
          error: error,
          stackTrace: stack,
        ),
      );

      final params = transport.calls.first.$2;
      expect(params['error'], error.toString());
      expect(params['stackTrace'], stack.toString());
    });

    test('does not call dispatchEvent below threshold', () async {
      final transport = _FakeAnalyticsTransport(level: LogLevel.error);

      await transport.log(LogEvent(level: LogLevel.info, message: 'ignored'));

      expect(transport.calls, isEmpty);
    });

    test('calls dispatchEvent at or above threshold', () async {
      final transport = _FakeAnalyticsTransport(level: LogLevel.warn);

      await transport.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await transport.log(LogEvent(level: LogLevel.error, message: 'error'));

      expect(transport.calls, hasLength(2));
    });
  });
}
