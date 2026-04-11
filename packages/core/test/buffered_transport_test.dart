import 'package:test/test.dart';
import 'package:revere/core.dart';
import 'package:revere/buffered_transport.dart';

class CollectingTransport extends Transport {
  final List<LogEvent> received = [];

  CollectingTransport({super.level = LogLevel.trace});

  @override
  Future<void> emitLog(LogEvent event) async => received.add(event);
}

class FailingTransport extends Transport {
  int callCount = 0;

  FailingTransport() : super(level: LogLevel.trace);

  @override
  Future<void> emitLog(LogEvent event) async {
    callCount++;
    throw Exception('transport error');
  }
}

LogEvent _event(LogLevel level, String msg) =>
    LogEvent(level: level, message: msg);

void main() {
  group('BufferedTransport', () {
    test('does not forward events before flush', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 10);

      await buffer.log(_event(LogLevel.info, 'a'));
      await buffer.log(_event(LogLevel.info, 'b'));

      expect(inner.received, isEmpty);
      expect(buffer.pendingCount, 2);
      await buffer.dispose();
    });

    test('auto-flushes when maxSize reached', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 3);

      await buffer.log(_event(LogLevel.info, 'a'));
      await buffer.log(_event(LogLevel.info, 'b'));
      await buffer.log(_event(LogLevel.info, 'c')); // triggers flush

      expect(inner.received.length, 3);
      expect(buffer.pendingCount, 0);
      await buffer.dispose();
    });

    test('flush() sends all buffered events in order', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 100);

      await buffer.log(_event(LogLevel.info, 'first'));
      await buffer.log(_event(LogLevel.warn, 'second'));
      await buffer.log(_event(LogLevel.error, 'third'));
      await buffer.flush();

      expect(inner.received.map((e) => e.message), [
        'first',
        'second',
        'third',
      ]);
      await buffer.dispose();
    });

    test('flush() on empty buffer is a no-op', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 10);
      await buffer.flush(); // must not throw
      expect(inner.received, isEmpty);
      await buffer.dispose();
    });

    test('dispose() flushes remaining events', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 100);

      await buffer.log(_event(LogLevel.info, 'before dispose'));
      expect(inner.received, isEmpty);

      await buffer.dispose();
      expect(inner.received.length, 1);
      expect(inner.received.first.message, 'before dispose');
    });

    test('inner level filter is applied on flush', () async {
      final inner = CollectingTransport(level: LogLevel.error);
      final buffer = BufferedTransport(inner, maxSize: 10);

      await buffer.log(_event(LogLevel.info, 'below threshold'));
      await buffer.log(_event(LogLevel.error, 'at threshold'));
      await buffer.flush();

      expect(inner.received.length, 1);
      expect(inner.received.first.level, LogLevel.error);
      await buffer.dispose();
    });

    test(
      'BufferedTransport level pre-filters events before buffering',
      () async {
        final inner = CollectingTransport();
        final buffer = BufferedTransport(
          inner,
          maxSize: 10,
          level: LogLevel.warn,
        );

        await buffer.log(_event(LogLevel.info, 'filtered'));
        await buffer.log(_event(LogLevel.warn, 'kept'));
        await buffer.flush();

        expect(inner.received.length, 1);
        expect(inner.received.first.message, 'kept');
        await buffer.dispose();
      },
    );

    test('flushInterval triggers periodic flush', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(
        inner,
        maxSize: 1000,
        flushInterval: Duration(milliseconds: 50),
      );

      await buffer.log(_event(LogLevel.info, 'msg'));
      expect(inner.received, isEmpty); // not yet flushed

      await Future.delayed(Duration(milliseconds: 100));
      expect(inner.received.length, 1);

      await buffer.dispose();
    });

    test('withBuffer extension wraps transport', () async {
      final inner = CollectingTransport();
      final buffer = inner.withBuffer(maxSize: 5);

      await buffer.log(_event(LogLevel.info, 'x'));
      expect(inner.received, isEmpty);
      expect(buffer.pendingCount, 1);

      await buffer.dispose();
    });

    test('multiple flushes after dispose are safe', () async {
      final inner = CollectingTransport();
      final buffer = BufferedTransport(inner, maxSize: 100);

      await buffer.log(_event(LogLevel.info, 'msg'));
      await buffer.dispose();
      await buffer.flush(); // second flush: buffer already empty
      expect(inner.received.length, 1);
    });
  });
}
