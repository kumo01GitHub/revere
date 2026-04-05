import 'dart:math';

import '../log_event.dart';
import '../log_level.dart';
import '../transport.dart';

/// A [Transport] decorator that probabilistically samples log events before
/// forwarding them to an inner [Transport].
///
/// Pass [sampleRate] between `0.0` (drop all) and `1.0` (forward all).
/// Optionally restrict sampling to specific [levels]; events at unlisted
/// levels are always forwarded.
///
/// Example — forward only 10 % of debug/trace logs to Sentry:
/// ```dart
/// SentryTransport()
///   .withSampling(
///     sampleRate: 0.1,
///     levels: [LogLevel.trace, LogLevel.debug],
///   );
/// ```
class SamplingTransport extends Transport {
  /// The inner transport that receives sampled events.
  final Transport inner;

  /// Fraction of matching events to forward. Must be between 0.0 and 1.0.
  final double sampleRate;

  /// Levels subject to sampling. Events at other levels are always forwarded.
  /// When empty, all levels are sampled.
  final List<LogLevel> levels;

  final Random _random;

  /// Creates a [SamplingTransport].
  ///
  /// [sampleRate] must be between 0.0 and 1.0.
  /// [random] may be injected for deterministic testing.
  SamplingTransport(
    this.inner, {
    required this.sampleRate,
    this.levels = const [],
    Random? random,
    super.level = LogLevel.trace,
    super.config,
  }) : assert(
         sampleRate >= 0.0 && sampleRate <= 1.0,
         'sampleRate must be between 0.0 and 1.0',
       ),
       _random = random ?? Random();

  @override
  Future<void> emitLog(LogEvent event) async {
    final shouldSample = levels.isEmpty || levels.contains(event.level);
    if (shouldSample && _random.nextDouble() >= sampleRate) {
      return; // dropped
    }
    await inner.log(event);
  }
}

/// Extension that adds a [withSampling] decorator to any [Transport].
extension SamplingTransportExtension on Transport {
  /// Wraps this transport in a [SamplingTransport].
  ///
  /// ```dart
  /// SentryTransport()
  ///   .withSampling(sampleRate: 0.1, levels: [LogLevel.debug]);
  /// ```
  SamplingTransport withSampling({
    required double sampleRate,
    List<LogLevel> levels = const [],
    Random? random,
  }) {
    return SamplingTransport(
      this,
      sampleRate: sampleRate,
      levels: levels,
      random: random,
    );
  }
}
