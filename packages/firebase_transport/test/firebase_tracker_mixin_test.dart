import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revere/core.dart';
import 'package:firebase_transport/firebase_transport.dart';
import 'package:firebase_transport/firebase_tracker_mixin.dart';

// ---------------------------------------------------------------------------
// Fake transport to capture calls without touching Firebase SDK
// ---------------------------------------------------------------------------

class _FakeFirebaseTransport extends FirebaseTransport {
  final List<LogEvent> logged = [];

  @override
  Future<void> dispatchAnalyticsEvent(
    String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  ) async {}

  @override
  Future<void> dispatchCrashlyticsError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> dispatchCrashlyticsLog(String message) async {}

  /// Override emitLog so we capture the raw event before it's processed.
  @override
  Future<void> emitLog(LogEvent event) async {
    logged.add(event);
    await super.emitLog(event);
  }
}

// ---------------------------------------------------------------------------
// Concrete classes that use the mixin
// ---------------------------------------------------------------------------

class _Service with FirebaseTrackerMixin {
  final _FakeFirebaseTransport _transport;
  _Service(this._transport);

  @override
  _FakeFirebaseTransport get firebaseTransport => _transport;
}

class _DefaultContextService with FirebaseTrackerMixin {
  final _FakeFirebaseTransport _transport;
  _DefaultContextService(this._transport);

  @override
  _FakeFirebaseTransport get firebaseTransport => _transport;
}

/// Uses the built-in default transport (does not override [firebaseTransport]).
class _DefaultTransportService with FirebaseTrackerMixin {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeFirebaseTransport transport;
  late _Service svc;

  setUp(() {
    transport = _FakeFirebaseTransport();
    svc = _Service(transport);
  });

  group('FirebaseTrackerMixin – trackAction', () {
    test('logs an info-level event', () async {
      await svc.trackAction('button_tap');
      expect(transport.logged, hasLength(1));
      expect(transport.logged.first.level, LogLevel.info);
    });

    test('message equals action when no params', () async {
      await svc.trackAction('page_view');
      expect(transport.logged.first.message, 'page_view');
    });

    test('message appends params as key=value pairs', () async {
      await svc.trackAction('purchase', params: {'item': 'shoes', 'qty': 2});
      final msg = transport.logged.first.message as String;
      expect(msg, startsWith('purchase: '));
      expect(msg, contains('item=shoes'));
      expect(msg, contains('qty=2'));
    });

    test('context is set from trackerContext', () async {
      await svc.trackAction('login');
      expect(transport.logged.first.context, '_Service');
    });
  });

  group('FirebaseTrackerMixin – trackError', () {
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
  });

  group('FirebaseTrackerMixin – withTracking', () {
    test('logs action before executing body', () async {
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
      expect(
        transport.logged.last.message as String,
        contains('myAction'),
      );
    });

    test('passes params to trackAction', () async {
      await svc.withTracking('buy', () async {}, params: {'sku': 'abc'});
      final msg = transport.logged.first.message as String;
      expect(msg, contains('sku=abc'));
    });
  });

  group('FirebaseTrackerMixin – trackerContext', () {
    test('default context is runtimeType name', () async {
      final svc2 = _DefaultContextService(transport);
      await svc2.trackAction('ping');
      expect(transport.logged.first.context, '_DefaultContextService');
    });
  });

  group('FirebaseTrackerMixin – default firebaseTransport', () {
    test('default firebaseTransport is a FirebaseTransport instance', () {
      final svc = _DefaultTransportService();
      expect(svc.firebaseTransport, isA<FirebaseTransport>());
    });
  });

  group('FirebaseTrackerMixin – guarded', () {
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
      await expectLater(
        () => svc.guarded(() async => throw err),
        throwsA(err),
      );
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

  group('FirebaseTrackerMixin – setupFlutterErrorTracking', () {
    late void Function(FlutterErrorDetails)? savedFlutterHandler;
    late bool Function(Object, StackTrace)? savedPlatformHandler;

    setUp(() {
      savedFlutterHandler = FlutterError.onError;
      savedPlatformHandler = PlatformDispatcher.instance.onError;
      transport.logged.clear();
    });

    tearDown(() {
      FlutterError.onError = savedFlutterHandler;
      PlatformDispatcher.instance.onError = savedPlatformHandler;
    });

    test('installs a FlutterError.onError handler', () {
      svc.setupFlutterErrorTracking();
      expect(FlutterError.onError, isNotNull);
    });

    test('FlutterError handler calls trackError with exception details',
        () async {
      svc.setupFlutterErrorTracking();
      final err = Exception('flutter error');
      final st = StackTrace.current;
      final details = FlutterErrorDetails(exception: err, stack: st);
      FlutterError.onError!(details);
      await pumpEventQueue();
      expect(transport.logged, hasLength(1));
      expect(transport.logged.first.level, LogLevel.error);
      expect(transport.logged.first.message, details.exceptionAsString());
      expect(transport.logged.first.stackTrace, st);
    });

    test('FlutterError handler calls previously installed handler', () async {
      bool prevCalled = false;
      FlutterError.onError = (_) => prevCalled = true;
      svc.setupFlutterErrorTracking();
      FlutterError.onError!(FlutterErrorDetails(exception: Exception('x')));
      await pumpEventQueue();
      expect(prevCalled, isTrue);
    });

    test('installs a PlatformDispatcher.onError handler', () {
      svc.setupFlutterErrorTracking();
      expect(PlatformDispatcher.instance.onError, isNotNull);
    });

    test('PlatformDispatcher handler calls trackError with fatal=true',
        () async {
      svc.setupFlutterErrorTracking();
      final err = Exception('platform error');
      final st = StackTrace.current;
      PlatformDispatcher.instance.onError!(err, st);
      await pumpEventQueue();
      expect(transport.logged, hasLength(1));
      expect(transport.logged.first.level, LogLevel.fatal);
      expect(transport.logged.first.error, err);
      expect(transport.logged.first.stackTrace, st);
    });

    test('PlatformDispatcher handler returns false', () {
      svc.setupFlutterErrorTracking();
      final result = PlatformDispatcher.instance.onError!(
          Exception('x'), StackTrace.empty);
      expect(result, isFalse);
    });

    test('PlatformDispatcher handler calls previously installed handler',
        () async {
      bool prevCalled = false;
      PlatformDispatcher.instance.onError = (_, __) {
        prevCalled = true;
        return true;
      };
      svc.setupFlutterErrorTracking();
      PlatformDispatcher.instance.onError!(Exception('x'), StackTrace.empty);
      await pumpEventQueue();
      expect(prevCalled, isTrue);
    });
  });
}
