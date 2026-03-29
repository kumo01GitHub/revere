import 'package:revere/console_transport.dart';
import 'package:revere/core.dart';
import 'package:flutter_test/flutter_test.dart';

class DummyTransport extends Transport {
  final List<String> messages;
  DummyTransport(this.messages) : super(level: LogLevel.trace);
  @override
  Future<void> emitLog(LogEvent event) async {
    messages.add(event.message);
  }
}

void main() {
  group('Logger', () {
    test('logs info and error to DummyTransport', () async {
      final logger = Logger();
      final messages = <String>[];
      logger.addTransport(DummyTransport(messages));
      logger.addTransport(
        ConsoleTransport(
          level: LogLevel.trace,
          config: {'colorize': false, 'format': '[TEST] {level}: {message}'},
        ),
      );
      await logger.info('info message');
      await logger.error('error message');
      expect(messages.any((m) => m.contains('info message')), isTrue);
      expect(messages.any((m) => m.contains('error message')), isTrue);
    });
  });
}
