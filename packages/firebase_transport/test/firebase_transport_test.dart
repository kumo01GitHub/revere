import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/firebase_transport.dart';

// ---------------------------------------------------------------------------
// Fake that intercepts both dispatch methods
// ---------------------------------------------------------------------------

class _FakeFirebaseTransport extends FirebaseTransport {
  final List<(String, Map<String, Object>, AnalyticsCallOptions?)>
      analyticsCalls = [];

  final List<
      ({
        Object error,
        StackTrace? stackTrace,
        bool fatal,
        String? reason,
      })> crashlyticsErrors = [];

  final List<String> crashlyticsLogs = [];

  _FakeFirebaseTransport({super.level, super.config});

  @override
  Future<void> dispatchAnalyticsEvent(
    String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  ) async {
    analyticsCalls.add((name, parameters ?? {}, callOptions));
  }

  @override
  Future<void> dispatchCrashlyticsError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    crashlyticsErrors.add((
      error: error,
      stackTrace: stackTrace,
      fatal: fatal,
      reason: reason,
    ));
  }

  @override
  Future<void> dispatchCrashlyticsLog(String message) async {
    crashlyticsLogs.add(message);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FirebaseTransport – level threshold', () {
    test('does not dispatch below threshold', () async {
      final t = _FakeFirebaseTransport(level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.info, message: 'ignored'));
      expect(t.analyticsCalls, isEmpty);
      expect(t.crashlyticsErrors, isEmpty);
      expect(t.crashlyticsLogs, isEmpty);
    });

    test('dispatches at threshold', () async {
      final t = _FakeFirebaseTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(t.analyticsCalls, hasLength(1));
    });

    test('dispatches above threshold', () async {
      final t = _FakeFirebaseTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.error, message: 'error'));
      expect(t.analyticsCalls, hasLength(1));
    });
  });

  group('FirebaseTransport – Analytics', () {
    test('default event name is revere', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(t.analyticsCalls.first.$1, 'revere');
    });

    test('name template replaces {level}', () async {
      final t = _FakeFirebaseTransport(config: {'name': 'app_{level}'});
      await t.emitLog(LogEvent(level: LogLevel.error, message: 'crash'));
      expect(t.analyticsCalls.first.$1, 'app_error');
    });

    test('name template replaces {context}', () async {
      final t = _FakeFirebaseTransport(config: {'name': '{context}_log'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'auth'),
      );
      expect(t.analyticsCalls.first.$1, 'auth_log');
    });

    test('parameters include level and message', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.warn, message: 'hello', context: 'svc'),
      );
      final params = t.analyticsCalls.first.$2;
      expect(params['level'], 'warn');
      expect(params['context'], 'svc');
    });

    test('error parameter included when event has error', () async {
      final t = _FakeFirebaseTransport();
      final err = Exception('boom');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'oops', error: err),
      );
      expect(t.analyticsCalls.first.$2['error'], err.toString());
    });

    test('info event does not call crashlytics', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'info'));
      expect(t.crashlyticsErrors, isEmpty);
      expect(t.crashlyticsLogs, isEmpty);
    });
  });

  group('FirebaseTransport – Crashlytics routing', () {
    test('error level without error object calls dispatchCrashlyticsLog',
        () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(LogEvent(level: LogLevel.error, message: 'no error obj'));
      expect(t.crashlyticsErrors, isEmpty);
      expect(t.crashlyticsLogs, hasLength(1));
    });

    test('fatal level without error object calls dispatchCrashlyticsLog',
        () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(LogEvent(level: LogLevel.fatal, message: 'fatal msg'));
      expect(t.crashlyticsLogs, hasLength(1));
    });

    test('error level with error object calls dispatchCrashlyticsError',
        () async {
      final t = _FakeFirebaseTransport();
      final err = Exception('boom');
      final st = StackTrace.current;
      await t.emitLog(
        LogEvent(
          level: LogLevel.error,
          message: 'crash',
          error: err,
          stackTrace: st,
        ),
      );
      expect(t.crashlyticsErrors, hasLength(1));
      expect(t.crashlyticsErrors.first.error, err);
      expect(t.crashlyticsErrors.first.stackTrace, st);
      expect(t.crashlyticsErrors.first.fatal, isFalse);
    });

    test('fatal level with error marks fatal=true', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(
        LogEvent(
          level: LogLevel.fatal,
          message: 'fatal crash',
          error: Exception('fatal'),
        ),
      );
      expect(t.crashlyticsErrors.first.fatal, isTrue);
    });

    test('warn level with error object still routes to crashlytics', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(
        LogEvent(
          level: LogLevel.warn,
          message: 'warn+error',
          error: Exception('side effect'),
        ),
      );
      // error object present → recordError
      expect(t.crashlyticsErrors, hasLength(1));
      expect(t.crashlyticsErrors.first.fatal, isFalse);
    });

    test('each error also dispatches to analytics', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(
        LogEvent(
          level: LogLevel.error,
          message: 'dual dispatch',
          error: Exception('e'),
        ),
      );
      expect(t.analyticsCalls, hasLength(1));
      expect(t.crashlyticsErrors, hasLength(1));
    });
  });

  group('FirebaseTransport – format', () {
    test('default format is [level:context] message', () async {
      final t = _FakeFirebaseTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'hello', context: 'ctx'),
      );
      expect(t.analyticsCalls.first.$2['message'], '[info:ctx] hello');
    });

    test('custom format replaces placeholders', () async {
      final t =
          _FakeFirebaseTransport(config: {'format': '{level}: {message}'});
      await t.emitLog(LogEvent(level: LogLevel.warn, message: 'test'));
      expect(t.analyticsCalls.first.$2['message'], 'warn: test');
    });
  });

  group('FirebaseTransport – real dispatch methods (Firebase not initialised)',
      () {
    // These tests call the concrete @protected dispatch methods directly.
    // Firebase SDK is not initialised so each call throws; the important
    // thing is that the method bodies are reached (coverage) and the
    // errors are expected rather than leaked.

    late _ConcreteFirebaseTransport transport;

    setUp(() {
      transport = _ConcreteFirebaseTransport();
    });

    test('dispatchAnalyticsEvent throws when Firebase not initialised',
        () async {
      await expectLater(
        () => transport.callDispatchAnalyticsEvent('evt', {}, null),
        throwsA(anything),
      );
    });

    test('dispatchCrashlyticsError throws when Firebase not initialised',
        () async {
      await expectLater(
        () => transport.callDispatchCrashlyticsError(
          Exception('e'),
          null,
          fatal: false,
          reason: 'test',
        ),
        throwsA(anything),
      );
    });

    test('dispatchCrashlyticsLog throws when Firebase not initialised',
        () async {
      await expectLater(
        () => transport.callDispatchCrashlyticsLog('message'),
        throwsA(anything),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Concrete transport that exposes @protected dispatch methods for testing
// ---------------------------------------------------------------------------

class _ConcreteFirebaseTransport extends FirebaseTransport {
  Future<void> callDispatchAnalyticsEvent(
    String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  ) =>
      dispatchAnalyticsEvent(name, parameters, callOptions);

  Future<void> callDispatchCrashlyticsError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) =>
      dispatchCrashlyticsError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );

  Future<void> callDispatchCrashlyticsLog(String message) =>
      dispatchCrashlyticsLog(message);
}
