import 'package:revere/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _CollectingTransport extends Transport {
  final List<LogEvent> received = [];
  _CollectingTransport({super.level = LogLevel.trace});
  @override
  Future<void> emitLog(LogEvent event) async => received.add(event);
}

void main() {
  group('Logger', () {
    // --- addTransport ---

    test('starts with no transports', () {
      final logger = Logger();
      expect(logger.transports, isEmpty);
    });

    test('addTransport appends to transports list', () {
      final logger = Logger();
      final t = _CollectingTransport();
      logger.addTransport(t);
      expect(logger.transports, contains(t));
    });

    test('initial transports passed via constructor are used', () {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      expect(logger.transports, [t]);
    });

    // --- fan-out ---

    test('log() fans out to all transports', () async {
      final a = _CollectingTransport();
      final b = _CollectingTransport();
      final logger = Logger([a, b]);
      await logger.log(LogLevel.info, 'broadcast');
      expect(a.received, hasLength(1));
      expect(b.received, hasLength(1));
    });

    test('log() passes error and stackTrace through to transport', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      final err = Exception('fail');
      final trace = StackTrace.fromString('#0 main');
      await logger.log(
        LogLevel.error,
        'msg',
        error: err,
        stackTrace: trace,
        context: 'ctx',
      );
      final event = t.received.first;
      expect(event.error, same(err));
      expect(event.stackTrace, same(trace));
      expect(event.context, 'ctx');
    });

    // --- shortcut methods ---

    test('trace() produces LogLevel.trace event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.trace('msg');
      expect(t.received.first.level, LogLevel.trace);
    });

    test('debug() produces LogLevel.debug event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.debug('msg');
      expect(t.received.first.level, LogLevel.debug);
    });

    test('info() produces LogLevel.info event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.info('msg');
      expect(t.received.first.level, LogLevel.info);
    });

    test('warn() produces LogLevel.warn event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.warn('msg');
      expect(t.received.first.level, LogLevel.warn);
    });

    test('error() produces LogLevel.error event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.error('msg');
      expect(t.received.first.level, LogLevel.error);
    });

    test('fatal() produces LogLevel.fatal event', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.fatal('msg');
      expect(t.received.first.level, LogLevel.fatal);
    });

    test('all six shortcut methods produce distinct levels', () async {
      final t = _CollectingTransport();
      final logger = Logger([t]);
      await logger.trace('t');
      await logger.debug('d');
      await logger.info('i');
      await logger.warn('w');
      await logger.error('e');
      await logger.fatal('f');
      // LogLevel.silent is a threshold sentinel, not an emittable level.
      final emittable = LogLevel.values.where((l) => l != LogLevel.silent);
      expect(t.received.map((e) => e.level).toSet(), containsAll(emittable));
    });

    // --- transport level filtering ---

    test('events below transport threshold are not received', () async {
      final t = _CollectingTransport(level: LogLevel.error);
      final logger = Logger([t]);
      await logger.info('suppressed');
      await logger.warn('also suppressed');
      expect(t.received, isEmpty);
    });

    test('events at or above threshold are received', () async {
      final t = _CollectingTransport(level: LogLevel.warn);
      final logger = Logger([t]);
      await logger.warn('warn');
      await logger.error('error');
      await logger.fatal('fatal');
      expect(t.received, hasLength(3));
    });

    test('different transports can have different level thresholds', () async {
      final low = _CollectingTransport(level: LogLevel.trace);
      final high = _CollectingTransport(level: LogLevel.error);
      final logger = Logger([low, high]);
      await logger.debug('debug');
      await logger.error('error');
      expect(low.received, hasLength(2));
      expect(high.received, hasLength(1));
    });
  });
}
