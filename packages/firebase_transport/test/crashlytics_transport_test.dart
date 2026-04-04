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
    test('calls log with formatted message', () async {
      final transport = _FakeCrashlyticsTransport();

      await transport.emitLog(
        LogEvent(
          level: LogLevel.info,
          message: 'hello',
          context: 'auth',
          timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
      );

      expect(transport.calls, ['[info:auth] hello']);
    });

    test('uses custom format template', () async {
      final transport = _FakeCrashlyticsTransport(
        config: {'format': '{level}: {message}'},
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash'),
      );

      expect(transport.calls, ['error: crash']);
    });

    test('includes error in formatted message', () async {
      final transport = _FakeCrashlyticsTransport(
        config: {'format': '{message} ({error})'},
      );

      final error = Exception('oops');
      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'failed', error: error),
      );

      expect(transport.calls, ['failed (${error.toString()})']);
    });

    test('does not call dispatchLog below threshold', () async {
      final transport = _FakeCrashlyticsTransport(level: LogLevel.error);

      await transport.log(LogEvent(level: LogLevel.info, message: 'ignored'));

      expect(transport.calls, isEmpty);
    });

    test('calls dispatchLog at or above threshold', () async {
      final transport = _FakeCrashlyticsTransport(level: LogLevel.warn);

      await transport.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await transport.log(LogEvent(level: LogLevel.error, message: 'error'));

      expect(transport.calls, hasLength(2));
    });
  });
}
