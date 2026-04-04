import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/analytics_transport.dart';

void main() {
  group('AnalyticsTransport', () {
    test('calls logEvent with formatted message and parameters', () async {
      String? capturedName;
      Map<String, dynamic>? capturedParams;
      AnalyticsCallOptions? capturedOptions;

      final transport = AnalyticsTransport(
        logEventOverride: (name, params, options) async {
          capturedName = name;
          capturedParams = params;
          capturedOptions = options;
        },
      );

      final event = LogEvent(
        level: LogLevel.info,
        message: 'hello',
        context: 'auth',
        timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );
      await transport.emitLog(event);

      expect(capturedName, 'revere');
      expect(capturedParams?['level'], 'info');
      expect(capturedParams?['message'], '[info:auth] hello');
      expect(capturedParams?['context'], 'auth');
      expect(capturedOptions, isNull);
    });

    test('uses custom name template', () async {
      String? capturedName;

      final transport = AnalyticsTransport(
        config: {'name': 'app_{level}'},
        logEventOverride: (name, params, options) async {
          capturedName = name;
        },
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash'),
      );

      expect(capturedName, 'app_error');
    });

    test('uses custom format template', () async {
      Map<String, dynamic>? capturedParams;

      final transport = AnalyticsTransport(
        config: {'format': '{level}: {message}'},
        logEventOverride: (name, params, options) async {
          capturedParams = params;
        },
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.warn, message: 'something'),
      );

      expect(capturedParams?['message'], 'warn: something');
    });

    test('includes error and stackTrace when present', () async {
      Map<String, dynamic>? capturedParams;

      final transport = AnalyticsTransport(
        logEventOverride: (name, params, options) async {
          capturedParams = params;
        },
      );

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

      expect(capturedParams?['error'], error.toString());
      expect(capturedParams?['stackTrace'], stack.toString());
    });

    test('does not call logEvent below threshold', () async {
      int callCount = 0;

      final transport = AnalyticsTransport(
        level: LogLevel.error,
        logEventOverride: (name, params, options) async {
          callCount++;
        },
      );

      await transport.log(LogEvent(level: LogLevel.info, message: 'ignored'));

      expect(callCount, 0);
    });

    test('calls logEvent at or above threshold', () async {
      int callCount = 0;

      final transport = AnalyticsTransport(
        level: LogLevel.warn,
        logEventOverride: (name, params, options) async {
          callCount++;
        },
      );

      await transport.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await transport.log(LogEvent(level: LogLevel.error, message: 'error'));

      expect(callCount, 2);
    });
  });
}
