import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'dart:io';

import 'package:revere/http_transport.dart';

class DummyHttpServer {
  late HttpServer server;
  late Uri uri;
  final List<Map<String, dynamic>> received = [];

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    uri = Uri.parse('http://localhost:${server.port}');
    server.listen((HttpRequest request) async {
      final content = await utf8.decoder.bind(request).join();
      received.add(
        content.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(content))
            : {},
      );
      request.response.statusCode = 200;
      await request.response.close();
    });
  }

  Future<void> stop() async {
    await server.close(force: true);
  }
}

void main() {
  // ConsoleTransport tests are intentionally omitted due to inability to patch developer.log in Dart.

  group('HttpTransport', () {
    late DummyHttpServer server;
    setUp(() async {
      server = DummyHttpServer();
      await server.start();
    });
    tearDown(() async {
      await server.stop();
    });
    test('should send log event as JSON', () async {
      final transport = HttpTransport(
        server.uri.toString(),
        level: LogLevel.info,
      );
      await transport.log(LogEvent(level: LogLevel.info, message: 'info'));
      await Future.delayed(Duration(milliseconds: 100));
      expect(server.received.any((e) => e['message'] == 'info'), isTrue);
    });
    test('should not send below threshold', () async {
      final transport = HttpTransport(
        server.uri.toString(),
        level: LogLevel.error,
      );
      await transport.log(LogEvent(level: LogLevel.info, message: 'info'));
      await Future.delayed(Duration(milliseconds: 100));
      expect(server.received.isEmpty, isTrue);
    });
  });

  group('Logger', () {
    test('shortcut functions call log with correct level', () async {
      final logger = Logger();
      final events = <LogEvent>[];
      logger.addTransport(_CollectingTransport(events));
      await logger.trace('trace');
      await logger.debug('debug');
      await logger.info('info');
      await logger.warn('warn');
      await logger.error('error');
      await logger.fatal('fatal');
      expect(events.map((e) => e.level), containsAll(LogLevel.values));
    });
    test('log only calls transports at or above level', () async {
      final logger = Logger();
      final events = <LogEvent>[];
      logger.addTransport(_CollectingTransport(events, level: LogLevel.warn));
      await logger.info('info');
      await logger.error('error');
      expect(events.any((e) => e.level == LogLevel.info), isFalse);
      expect(events.any((e) => e.level == LogLevel.error), isTrue);
    });
  });
}

class _CollectingTransport extends Transport {
  final List<LogEvent> events;
  _CollectingTransport(this.events, {super.level = LogLevel.trace});
  @override
  Future<void> emitLog(LogEvent event) async {
    if (event.level.index >= level.index) {
      events.add(event);
    }
  }
}
