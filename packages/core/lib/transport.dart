import 'package:meta/meta.dart';

import 'log_event.dart';
import 'log_level.dart';

/// Abstract class for log transport with per-transport config.
///
/// Example config: {`format`: String, `colorize`: bool, ...}
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
