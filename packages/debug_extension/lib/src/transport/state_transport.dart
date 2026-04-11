/// Holds a limited-length state history for any data type.

import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:revere_debug_extension/src/metrics/metrics_collector.dart';

/// StateTransport can be used as a Transport for Logger/metrics logger.
class StateTransport<T> extends Transport {
  final ValueNotifier<List<T>> state;
  final int maxLength;

  StateTransport({this.maxLength = 100}) : state = ValueNotifier<List<T>>([]);

  void add(T data) {
    final list = List<T>.from(state.value);
    list.add(data);
    if (list.length > maxLength) {
      list.removeAt(0);
    }
    state.value = list;
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    // Only accept MetricsData or T
    final value = event.message;
    if (value is T) {
      add(value as T);
    } else if (T == MetricsData && value is String) {
      // Optionally: parse from string if needed (not implemented)
    }
  }
}
