import 'package:meta/meta.dart';

import 'log_event.dart';
import 'log_level.dart';

/// Abstract base class for log transports.
///
/// Subclasses implement [emitLog] to deliver log events to their destination.
/// config accepts arbitrary key/value options to configure the transport without
/// requiring subclass constructor changes.
abstract class Transport {
  /// Minimum severity level this transport will handle.
  ///
  /// Events with a lower level are silently dropped in [log].
  final LogLevel level;

  /// Arbitrary key/value options passed to the transport at construction time.
  ///
  /// Keys and their meanings are specific to each [Transport] subclass and
  /// documented on the concrete class.
  final Map<String, dynamic> config;

  /// Creates a transport.
  ///
  /// [level] defaults to [LogLevel.info]; [config] defaults to an empty map.
  Transport({this.level = LogLevel.info, this.config = const {}});

  /// Delivers [event] to the destination if `event.level >= this.level`.
  ///
  /// Subclasses should override [emitLog] rather than this method.
  Future<void> log(LogEvent event) async {
    if (event.level.index >= level.index) {
      await emitLog(event);
    }
  }

  /// Performs the actual delivery of [event] to the transport's destination.
  ///
  /// Called only when `event.level >= this.level`. Implementations must not
  /// throw; swallow or handle errors internally.
  @protected
  Future<void> emitLog(LogEvent event);
}
