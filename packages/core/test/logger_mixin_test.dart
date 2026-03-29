import 'package:revere/console_transport.dart';
import 'package:revere/core.dart';
import 'package:flutter_test/flutter_test.dart';

class DummyTransport extends Transport {
  final List<String> messages;
  DummyTransport(this.messages) : super(level: LogLevel.trace);
  @override
  Future<void> emitLog(LogEvent event) async {
    messages.add(
      event.context != null
          ? '[${event.context}] ${event.message}'
          : event.message,
    );
  }
}

class TestService with LoggerMixin {
  Future<void> doSomething() async {
    await logInfo('Service started');
    try {
      throw Exception('fail');
    } catch (e, st) {
      await logError('Error occurred', error: e, stackTrace: st);
    }
  }
}

void main() {
  group('LoggerMixin', () {
    setUp(() {
      LoggerMixin.logger.transports.clear();
    });
    test('TestService logs info and error', () async {
      final messages = <String>[];
      LoggerMixin.logger.addTransport(DummyTransport(messages));
      LoggerMixin.logger.addTransport(
        ConsoleTransport(
          level: LogLevel.trace,
          config: {'colorize': false, 'format': '[TEST] {level}: {message}'},
        ),
      );
      final service = TestService();
      await service.doSomething();
      expect(
        messages.any((m) => m.contains('[TestService] Service started')),
        isTrue,
      );
      expect(
        messages.any((m) => m.contains('[TestService] Error occurred')),
        isTrue,
      );
    });
  });
}
