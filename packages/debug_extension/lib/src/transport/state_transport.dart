import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';

/// StateTransport can be used as a Transport for Logger/metrics logger.
class StateTransport<T> extends Transport {
  final ValueNotifier<List<T>> state;

  StateTransport() : state = ValueNotifier<List<T>>([]);

  void add(T data) {
    final list = List<T>.from(state.value);
    list.add(data);
    state.value = list;
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    // Only accept T
    final value = event.message;
    if (value is T) {
      add(value as T);
    }
  }
}
