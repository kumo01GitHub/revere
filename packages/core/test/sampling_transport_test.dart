import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:revere/sampling_transport.dart';

class _CollectingTransport extends Transport {
  final List<LogEvent> received = [];

  _CollectingTransport({super.level = LogLevel.trace});

  @override
  Future<void> emitLog(LogEvent event) async => received.add(event);
}

/// A [Random] that always returns the given value.
class _FixedRandom implements Random {
  final double value;
  _FixedRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

LogEvent _event(LogLevel level, [String msg = 'msg']) =>
    LogEvent(level: level, message: msg);

void main() {
  group('SamplingTransport', () {
    // --- always forward ---

    test('sampleRate 1.0 forwards all events', () async {
      final inner = _CollectingTransport();
      final t = SamplingTransport(
        inner,
        sampleRate: 1.0,
        random: _FixedRandom(0.5),
      );

      await t.log(_event(LogLevel.info));
      await t.log(_event(LogLevel.warn));
      expect(inner.received, hasLength(2));
    });

    // --- always drop ---

    test('sampleRate 0.0 drops all events', () async {
      final inner = _CollectingTransport();
      final t = SamplingTransport(
        inner,
        sampleRate: 0.0,
        random: _FixedRandom(0.0),
      );

      await t.log(_event(LogLevel.info));
      expect(inner.received, isEmpty);
    });

    // --- deterministic sampling ---

    test('drops event when random >= sampleRate', () async {
      final inner = _CollectingTransport();
      // sampleRate=0.3, random always returns 0.5 → 0.5 >= 0.3 → drop
      final t = SamplingTransport(
        inner,
        sampleRate: 0.3,
        random: _FixedRandom(0.5),
      );

      await t.log(_event(LogLevel.debug));
      expect(inner.received, isEmpty);
    });

    test('forwards event when random < sampleRate', () async {
      final inner = _CollectingTransport();
      // sampleRate=0.8, random always returns 0.5 → 0.5 < 0.8 → forward
      final t = SamplingTransport(
        inner,
        sampleRate: 0.8,
        random: _FixedRandom(0.5),
      );

      await t.log(_event(LogLevel.debug));
      expect(inner.received, hasLength(1));
    });

    // --- level filter ---

    test('unlisted levels always forwarded regardless of sampleRate', () async {
      final inner = _CollectingTransport();
      // sampleRate=0.0 but levels=[debug] → info is not sampled → forwarded
      final t = SamplingTransport(
        inner,
        sampleRate: 0.0,
        levels: [LogLevel.debug],
        random: _FixedRandom(0.0),
      );

      await t.log(_event(LogLevel.info));
      expect(inner.received, hasLength(1));
    });

    test('listed levels are subject to sampling', () async {
      final inner = _CollectingTransport();
      final t = SamplingTransport(
        inner,
        sampleRate: 0.0, // drop all
        levels: [LogLevel.debug],
        random: _FixedRandom(0.0),
      );

      await t.log(_event(LogLevel.debug));
      expect(inner.received, isEmpty);
    });

    test('empty levels list samples all levels', () async {
      final inner = _CollectingTransport();
      final t = SamplingTransport(
        inner,
        sampleRate: 0.0,
        random: _FixedRandom(0.0),
      );

      await t.log(_event(LogLevel.info));
      await t.log(_event(LogLevel.error));
      expect(inner.received, isEmpty);
    });

    // --- Transport.level threshold ---

    test('Transport.level threshold is respected before sampling', () async {
      final inner = _CollectingTransport();
      final t = SamplingTransport(
        inner,
        sampleRate: 1.0,
        level: LogLevel.error,
        random: _FixedRandom(0.0),
      );

      await t.log(_event(LogLevel.info));
      expect(inner.received, isEmpty);
    });

    // --- extension ---

    test('withSampling extension wraps transport', () async {
      final inner = _CollectingTransport();
      final t = inner.withSampling(sampleRate: 1.0, random: _FixedRandom(0.0));
      expect(t, isA<SamplingTransport>());
      expect(t.inner, same(inner));
      expect(t.sampleRate, 1.0);
    });

    // --- assert ---

    test('throws AssertionError for sampleRate > 1.0', () {
      expect(
        () => SamplingTransport(_CollectingTransport(), sampleRate: 1.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError for sampleRate < 0.0', () {
      expect(
        () => SamplingTransport(_CollectingTransport(), sampleRate: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
