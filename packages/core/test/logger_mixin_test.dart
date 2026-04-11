import 'package:revere/core.dart';
import 'package:test/test.dart';

class _CollectingTransport extends Transport {
  final List<LogEvent> received = [];
  _CollectingTransport() : super(level: LogLevel.trace);
  @override
  Future<void> emitLog(LogEvent event) async => received.add(event);
}

class _ServiceA with LoggerMixin {}

class _ServiceB with LoggerMixin {}

class _ContextCapture with LoggerMixin {
  String get capturedContext => loggerContext;
}

void main() {
  group('LoggerMixin', () {
    late _CollectingTransport transport;

    setUp(() {
      LoggerMixin.logger.transports.clear();
      transport = _CollectingTransport();
      LoggerMixin.logger.addTransport(transport);
    });

    // --- loggerContext ---

    test('loggerContext returns runtimeType name', () {
      expect(_ContextCapture().capturedContext, '_ContextCapture');
    });

    test('loggerContext differs between unrelated classes', () {
      final a = _ServiceA();
      final b = _ServiceB();
      expect(a.loggerContext, isNot(equals(b.loggerContext)));
    });

    // --- shortcut methods produce correct levels ---

    test('t() logs at LogLevel.trace', () async {
      await _ServiceA().t('msg');
      expect(transport.received.first.level, LogLevel.trace);
    });

    test('d() logs at LogLevel.debug', () async {
      await _ServiceA().d('msg');
      expect(transport.received.first.level, LogLevel.debug);
    });

    test('i() logs at LogLevel.info', () async {
      await _ServiceA().i('msg');
      expect(transport.received.first.level, LogLevel.info);
    });

    test('w() logs at LogLevel.warn', () async {
      await _ServiceA().w('msg');
      expect(transport.received.first.level, LogLevel.warn);
    });

    test('e() logs at LogLevel.error', () async {
      await _ServiceA().e('msg');
      expect(transport.received.first.level, LogLevel.error);
    });

    test('f() logs at LogLevel.fatal', () async {
      await _ServiceA().f('msg');
      expect(transport.received.first.level, LogLevel.fatal);
    });

    // --- context is attached ---

    test('shortcut methods attach loggerContext to events', () async {
      await _ServiceA().i('hello');
      expect(transport.received.first.context, '_ServiceA');
    });

    test('error and stackTrace are forwarded', () async {
      final err = Exception('boom');
      final trace = StackTrace.fromString('#0 main');
      await _ServiceA().e('fail', error: err, stackTrace: trace);
      final event = transport.received.first;
      expect(event.error, same(err));
      expect(event.stackTrace, same(trace));
    });

    // --- static shared logger ---

    test('static logger is shared across all mixin instances', () async {
      await _ServiceA().i('from A');
      await _ServiceB().i('from B');
      expect(transport.received, hasLength(2));
    });
  });
}
