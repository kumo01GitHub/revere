import 'package:meta/meta.dart';

import 'log_event.dart';
import 'log_level.dart';

/// Abstract base class for log transports.
///
/// Subclasses implement [emitLog] to deliver log events to their destination.
/// config accepts arbitrary key/value options to configure the transport without
/// requiring subclass constructor changes.
abstract class Transport {
  final LogLevel level;
  final Map<String, dynamic> config;

  Transport({this.level = LogLevel.info, this.config = const {}});

  Future<void> log(LogEvent event) async {
    if (event.level.index >= level.index) {
      await emitLog(event);
    }
  }

  @protected
  Future<void> emitLog(LogEvent event);
}
