import 'package:test/test.dart';
import 'package:revere/core.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_transport/sentry_transport.dart';

class _FakeSentryTransport extends SentryTransport {
  final List<Breadcrumb> breadcrumbs = [];
  final List<({Object exception, StackTrace? stackTrace, bool fatal})>
      exceptions = [];

  _FakeSentryTransport({super.level, super.config});

  @override
  Future<void> dispatchBreadcrumb(Breadcrumb breadcrumb) async {
    breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> dispatchException(
    Object exception, {
    StackTrace? stackTrace,
    bool fatal = false,
    dynamic hint,
  }) async {
    exceptions.add((
      exception: exception,
      stackTrace: stackTrace,
      fatal: fatal,
    ));
  }
}

void main() {
  group('SentryTransport', () {
    // --- level threshold ---

    test('does not emit below threshold', () async {
      final t = _FakeSentryTransport(level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.info, message: 'ignored'));
      expect(t.breadcrumbs, isEmpty);
      expect(t.exceptions, isEmpty);
    });

    // --- breadcrumb routing ---

    test('info level adds breadcrumb', () async {
      final t = _FakeSentryTransport();
      await t.log(LogEvent(level: LogLevel.info, message: 'hello'));
      expect(t.breadcrumbs, hasLength(1));
      expect(t.exceptions, isEmpty);
    });

    test('warn level adds breadcrumb', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(t.breadcrumbs, hasLength(1));
      expect(t.exceptions, isEmpty);
    });

    test('breadcrumb level maps correctly', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      await t.log(LogEvent(level: LogLevel.trace, message: 'trace'));
      await t.log(LogEvent(level: LogLevel.debug, message: 'debug'));
      await t.log(LogEvent(level: LogLevel.info, message: 'info'));
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(t.breadcrumbs.map((b) => b.level).toList(), [
        SentryLevel.debug,
        SentryLevel.debug,
        SentryLevel.info,
        SentryLevel.warning,
      ]);
    });

    test('breadcrumb uses context as category', () async {
      final t = _FakeSentryTransport();
      await t.log(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'auth'),
      );
      expect(t.breadcrumbs.first.category, 'auth');
    });

    test('breadcrumb timestamp matches event timestamp', () async {
      final ts = DateTime.parse('2024-03-01T12:00:00.000Z');
      final t = _FakeSentryTransport();
      await t.log(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(t.breadcrumbs.first.timestamp, ts);
    });

    // --- exception routing ---

    test('error level captures exception', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      final err = Exception('boom');
      await t.log(LogEvent(level: LogLevel.error, message: 'err', error: err));
      expect(t.exceptions, hasLength(1));
      expect(t.exceptions.first.exception, err);
      expect(t.exceptions.first.fatal, isFalse);
    });

    test('fatal level captures exception with fatal=true', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      await t.log(
        LogEvent(
          level: LogLevel.fatal,
          message: 'crash',
          error: Exception('x'),
        ),
      );
      expect(t.exceptions.first.fatal, isTrue);
    });

    test(
      'event with error object routes to exception even at info level',
      () async {
        final t = _FakeSentryTransport();
        await t.log(
          LogEvent(
            level: LogLevel.info,
            message: 'msg',
            error: Exception('oops'),
          ),
        );
        expect(t.exceptions, hasLength(1));
        expect(t.breadcrumbs, isEmpty);
      },
    );

    test('error without LogEvent.error uses message as exception', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      await t.log(LogEvent(level: LogLevel.error, message: 'bare error'));
      expect(t.exceptions.first.exception, 'bare error');
    });

    test('exception stackTrace is forwarded', () async {
      final t = _FakeSentryTransport(level: LogLevel.trace);
      final st = StackTrace.current;
      await t.log(
        LogEvent(
          level: LogLevel.error,
          message: 'err',
          error: Exception('e'),
          stackTrace: st,
        ),
      );
      expect(t.exceptions.first.stackTrace, st);
    });

    // --- breadcrumb format ---

    test('default format is [level:context] message', () async {
      final t = _FakeSentryTransport();
      await t.log(
        LogEvent(level: LogLevel.info, message: 'hello', context: 'svc'),
      );
      expect(t.breadcrumbs.first.message, '[info:svc] hello');
    });

    test('null context replaced with empty string in format', () async {
      final t = _FakeSentryTransport();
      await t.log(LogEvent(level: LogLevel.info, message: 'hello'));
      expect(t.breadcrumbs.first.message, '[info:] hello');
    });

    test('custom format via config', () async {
      final t = _FakeSentryTransport(config: {'format': '{level}: {message}'});
      await t.log(LogEvent(level: LogLevel.info, message: 'hi'));
      expect(t.breadcrumbs.first.message, 'info: hi');
    });
  });
}
