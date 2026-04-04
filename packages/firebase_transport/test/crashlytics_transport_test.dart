import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/crashlytics_transport.dart';

void main() {
  group('CrashlyticsTransport', () {
    test('calls log with formatted message', () async {
      String? capturedMsg;

      final transport = CrashlyticsTransport(
        logOverride: (msg) async {
          capturedMsg = msg;
        },
      );

      await transport.emitLog(
        LogEvent(
          level: LogLevel.info,
          message: 'hello',
          context: 'auth',
          timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
      );

      expect(capturedMsg, '[info:auth] hello');
    });

    test('uses custom format template', () async {
      String? capturedMsg;

      final transport = CrashlyticsTransport(
        config: {'format': '{level}: {message}'},
        logOverride: (msg) async {
          capturedMsg = msg;
        },
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash'),
      );

      expect(capturedMsg, 'error: crash');
    });

    test('includes error in formatted message', () async {
      String? capturedMsg;

      final transport = CrashlyticsTransport(
        config: {'format': '{message} ({error})'},
        logOverride: (msg) async {
          capturedMsg = msg;
        },
      );

      final error = Exception('oops');
      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'failed', error: error),
      );

      expect(capturedMsg, 'failed (${error.toString()})');
    });

    test('does not call log below threshold', () async {
      int callCount = 0;

      final transport = CrashlyticsTransport(
        level: LogLevel.error,
        logOverride: (msg) async {
          callCount++;
        },
      );

      await transport.log(LogEvent(level: LogLevel.info, message: 'ignored'));

      expect(callCount, 0);
    });

    test('calls log at or above threshold', () async {
      int callCount = 0;

      final transport = CrashlyticsTransport(
        level: LogLevel.warn,
        logOverride: (msg) async {
          callCount++;
        },
      );

      await transport.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await transport.log(LogEvent(level: LogLevel.error, message: 'error'));

      expect(callCount, 2);
    });
  });
}
