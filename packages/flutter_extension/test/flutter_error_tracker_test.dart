import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:revere_flutter_extension/flutter_error_tracker.dart';

class _CollectingTransport extends Transport {
  final List<LogEvent> logged = [];
  _CollectingTransport() : super(level: LogLevel.trace);
  @override
  Future<void> emitLog(LogEvent event) async => logged.add(event);
}

class _Service with ErrorTrackerMixin {
  final Logger _log;
  _Service(this._log);
  @override
  Logger get logger => _log;
}

void main() {
  late _CollectingTransport transport;
  late Logger log;
  late _Service svc;

  setUp(() {
    transport = _CollectingTransport();
    log = Logger([transport]);
    svc = _Service(log);
  });

  group('FlutterErrorTracker extension', () {
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

    test(
      'PlatformDispatcher handler calls trackError with fatal=true',
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
      },
    );
  });
}
