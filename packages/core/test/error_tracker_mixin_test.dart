import 'package:test/test.dart';
import 'package:revere/core.dart';

// ---------------------------------------------------------------------------
// Fake transport to capture calls without touching real output
// ---------------------------------------------------------------------------

class _CollectingTransport extends Transport {
  final List<LogEvent> logged = [];
  _CollectingTransport() : super(level: LogLevel.trace);
  @override
  Future<void> emitLog(LogEvent event) async => logged.add(event);
}

// ---------------------------------------------------------------------------
// Concrete classes that use the mixin
// ---------------------------------------------------------------------------

class _Service with ErrorTrackerMixin {
  final Logger _log;
  _Service(this._log);

  @override
  Logger get logger => _log;
}

class _CustomContextService with ErrorTrackerMixin {
  final Logger _log;
  _CustomContextService(this._log);

  @override
  Logger get logger => _log;
}

/// Uses the built-in default logger (does not override [logger]).
class _DefaultLoggerService with ErrorTrackerMixin {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _CollectingTransport transport;
  late Logger log;
  late _Service svc;

  setUp(() {
    transport = _CollectingTransport();
    log = Logger([transport]);
    svc = _Service(log);
  });

  // -------------------------------------------------------------------------
  group('ErrorTrackerMixin – default logger', () {
    test('default logger is a Logger instance', () {
      final svc = _DefaultLoggerService();
      expect(svc.logger, isA<Logger>());
    });
  });

  // -------------------------------------------------------------------------
  group('ErrorTrackerMixin – trackerContext', () {
    test('default context is runtimeType name', () async {
      final svc2 = _CustomContextService(log);
      await svc2.trackError(Exception('x'));
      expect(transport.logged.first.context, '_CustomContextService');
    });
  });

  // -------------------------------------------------------------------------
  group('ErrorTrackerMixin – trackError', () {
    test('logs an error-level event by default', () async {
      await svc.trackError(Exception('oops'));
      expect(transport.logged.first.level, LogLevel.error);
    });

    test('logs fatal-level when fatal=true', () async {
      await svc.trackError(Exception('bad'), fatal: true);
      expect(transport.logged.first.level, LogLevel.fatal);
    });

    test('event carries the error object', () async {
      final err = Exception('boom');
      await svc.trackError(err);
      expect(transport.logged.first.error, err);
    });

    test('event carries stackTrace when provided', () async {
      final st = StackTrace.current;
      await svc.trackError(Exception('e'), stackTrace: st);
      expect(transport.logged.first.stackTrace, st);
    });

    test('custom message overrides default', () async {
      await svc.trackError(Exception('e'), message: 'custom msg');
      expect(transport.logged.first.message, 'custom msg');
    });

    test('default message is error.toString()', () async {
      final err = Exception('detail');
      await svc.trackError(err);
      expect(transport.logged.first.message, err.toString());
    });

    test('context is set from trackerContext', () async {
      await svc.trackError(Exception('ctx'));
      expect(transport.logged.first.context, '_Service');
    });
  });

  // -------------------------------------------------------------------------
  group('ErrorTrackerMixin – withTracking', () {
    test('logs info event before body executes', () async {
      await svc.withTracking('init', () async {});
      expect(transport.logged, hasLength(1));
      expect(transport.logged.first.level, LogLevel.info);
      expect(transport.logged.first.message, 'init');
    });

    test('returns body result', () async {
      final result = await svc.withTracking('compute', () async => 42);
      expect(result, 42);
    });

    test('records error and rethrows on exception', () async {
      final err = Exception('fail');
      await expectLater(
        () => svc.withTracking('risky', () async => throw err),
        throwsA(err),
      );
      // action log + error log
      expect(transport.logged, hasLength(2));
      expect(transport.logged.last.level, LogLevel.error);
      expect(transport.logged.last.error, err);
    });

    test('error event message contains action name', () async {
      await expectLater(
        () => svc.withTracking('myAction', () async => throw Exception('x')),
        throwsException,
      );
      expect(transport.logged.last.message as String, contains('myAction'));
    });

    test('passes params to info log message', () async {
      await svc.withTracking('buy', () async {}, params: {'sku': 'abc'});
      final msg = transport.logged.first.message as String;
      expect(msg, contains('sku=abc'));
    });

    test('context is set on logged action event', () async {
      await svc.withTracking('ping', () async {});
      expect(transport.logged.first.context, '_Service');
    });
  });

  // -------------------------------------------------------------------------
  group('ErrorTrackerMixin – guarded', () {
    test('returns body result when no error', () async {
      final result = await svc.guarded(() async => 99);
      expect(result, 99);
    });

    test('does not log anything when no error', () async {
      await svc.guarded(() async {});
      expect(transport.logged, isEmpty);
    });

    test('records error and rethrows', () async {
      final err = Exception('guarded fail');
      await expectLater(() => svc.guarded(() async => throw err), throwsA(err));
      expect(transport.logged, hasLength(1));
      expect(transport.logged.first.error, err);
      expect(transport.logged.first.level, LogLevel.error);
    });

    test('uses fatal level when fatal=true', () async {
      await expectLater(
        () => svc.guarded(() async => throw Exception('x'), fatal: true),
        throwsException,
      );
      expect(transport.logged.first.level, LogLevel.fatal);
    });

    test('records stackTrace', () async {
      StackTrace? captured;
      await expectLater(
        () => svc.guarded(() async {
          try {
            throw Exception('trace');
          } catch (_, st) {
            captured = st;
            rethrow;
          }
        }),
        throwsException,
      );
      expect(transport.logged.first.stackTrace, captured);
    });
  });

  // Flutter error tracking tests have been moved to revere_flutter_extension.
}
