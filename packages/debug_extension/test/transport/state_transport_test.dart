import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/transport/state_transport.dart';
import 'package:revere/core.dart';

import 'package:revere/core.dart';
import 'package:revere/core.dart' show LogLevel;

class DummyLogEvent extends LogEvent {
  DummyLogEvent(dynamic message)
      : super(level: LogLevel.info, message: message);
}

void main() {
  group('StateTransport', () {
    test('initial state is empty', () {
      final transport = StateTransport<int>();
      expect(transport.state.value, isEmpty);
    });

    test('add() adds data to state', () {
      final transport = StateTransport<String>();
      transport.add('foo');
      expect(transport.state.value, ['foo']);
      transport.add('bar');
      expect(transport.state.value, ['foo', 'bar']);
    });

    test('emitLog only accepts correct type', () async {
      final transport = StateTransport<int>();
      await transport.emitLog(DummyLogEvent(42));
      expect(transport.state.value, [42]);
      await transport.emitLog(DummyLogEvent('not int'));
      expect(transport.state.value, [42]); // unchanged
    });
  });
}
