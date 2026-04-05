import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_transport/sentry_transport.dart';
import 'package:sentry_transport/sentry_tracker_mixin.dart';

// ---------------------------------------------------------------------------
// Fake transport to capture calls without touching Sentry SDK
// ---------------------------------------------------------------------------

class _FakeSentryTransport extends SentryTransport {
  final List<LogEvent> logged = [];
  final List<Breadcrumb> breadcrumbs = [];
  final List<({Object exception, StackTrace? stackTrace, bool fatal})>
  exceptions = [];

  _FakeSentryTransport() : super(level: LogLevel.trace);

  @override
  Future<void> emitLog(LogEvent event) async {
    logged.add(event);
    await super.emitLog(event);
  }

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

// ---------------------------------------------------------------------------
// Concrete classes that use the mixin
// ---------------------------------------------------------------------------

class _Service with SentryTrackerMixin {
  final _FakeSentryTransport _transport;
  _Service(this._transport);

  @override
  _FakeSentryTransport get sentryTransport => _transport;
}

class _DefaultContextService with SentryTrackerMixin {
  final _FakeSentryTransport _transport;
  _DefaultContextService(this._transport);

  @override
  _FakeSentryTransport get sentryTransport => _transport;
}

/// Uses the built-in default transport (does not override [sentryTransport]).
class _DefaultTransportService with SentryTrackerMixin {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeSentryTransport transport;
  late _Service svc;

  setUp(() {
    transport = _FakeSentryTransport();
    svc = _Service(transport);
  });

  group('SentryTrackerMixin – trackAction', () {
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

    test('routes to breadcrumb (not exception)', () async {
      await svc.trackAction('nav');
      expect(transport.breadcrumbs, hasLength(1));
      expect(transport.exceptions, isEmpty);
    });
  });

  group('SentryTrackerMixin – trackError', () {
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

    test('routes to captureException (not breadcrumb)', () async {
      await svc.trackError(Exception('e'));
      expect(transport.exceptions, hasLength(1));
      expect(transport.breadcrumbs, isEmpty);
    });

    test('fatal=true sets fatal on captureException', () async {
      await svc.trackError(Exception('e'), fatal: true);
      expect(transport.exceptions.first.fatal, isTrue);
    });
  });

  group('SentryTrackerMixin – withTracking', () {
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
      // action breadcrumb + exception
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

    test('passes params to trackAction', () async {
      await svc.withTracking('buy', () async {}, params: {'sku': 'abc'});
      final msg = transport.logged.first.message as String;
      expect(msg, contains('sku=abc'));
    });
  });

  group('SentryTrackerMixin – guarded', () {
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

  group('SentryTrackerMixin – trackerContext', () {
    test('default context is runtimeType name', () async {
      final svc2 = _DefaultContextService(transport);
      await svc2.trackAction('ping');
      expect(transport.logged.first.context, '_DefaultContextService');
    });
  });

  group('SentryTrackerMixin – default sentryTransport', () {
    test('default sentryTransport is a SentryTransport instance', () {
      final svc = _DefaultTransportService();
      expect(svc.sentryTransport, isA<SentryTransport>());
    });
  });

  group('SentryTrackerMixin – setupFlutterErrorTracking', () {
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

    test(
      'FlutterError handler calls trackError with exception details',
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
      },
    );

    test('FlutterError handler calls previously installed handler', () async {
      bool prevCalled = false;
      FlutterError.onError = (_) => prevCalled = true;
      svc.setupFlutterErrorTracking();
      FlutterError.onError!(FlutterErrorDetails(exception: Exception('x')));
      await pumpEventQueue();
      expect(prevCalled, isTrue);
    });

    test('PlatformDispatcher handler captures fatal errors', () async {
      svc.setupFlutterErrorTracking();
      final err = Exception('async crash');
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
        Exception('x'),
        StackTrace.empty,
      );
      expect(result, isFalse);
    });

    test(
      'PlatformDispatcher handler calls previously installed handler',
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
      },
    );
  });
}
