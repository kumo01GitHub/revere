import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:websocket_transport/websocket_transport.dart';

// ---------------------------------------------------------------------------
// Fake WebSocket helpers
// ---------------------------------------------------------------------------

class _FakeWebSocket implements WebSocket {
  final List<Object> sent = [];
  bool closeCalled = false;
  final _done = Completer<void>();

  @override
  int? get closeCode => closeCalled ? WebSocketStatus.normalClosure : null;

  @override
  Future get done => _done.future;

  @override
  void add(dynamic data) => sent.add(data as Object);

  @override
  Future<void> close([int? code, String? reason]) async {
    closeCalled = true;
    _done.complete();
  }

  // Unused WebSocket members
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeWebSocketTransport extends WebSocketTransport {
  final _FakeWebSocket fakeSocket;

  _FakeWebSocketTransport(super.url, this.fakeSocket, {super.level});

  @override
  Future<WebSocket> createWebSocket(String url) async => fakeSocket;
}

class _FailingWebSocketTransport extends WebSocketTransport {
  _FailingWebSocketTransport(super.url);

  @override
  Future<WebSocket> createWebSocket(String url) async {
    throw const SocketException('refused');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

LogEvent _event(LogLevel level, String msg) =>
    LogEvent(level: level, message: msg);

void main() {
  group('WebSocketTransport', () {
    test('sends JSON frame on log', () async {
      final fake = _FakeWebSocket();
      final t = _FakeWebSocketTransport('ws://localhost:9000', fake);

      await t.log(_event(LogLevel.info, 'hello'));

      expect(fake.sent, hasLength(1));
      final decoded = jsonDecode(fake.sent.first as String) as Map;
      expect(decoded['level'], 'info');
      expect(decoded['message'], 'hello');
      expect(decoded['timestamp'], isA<String>());
    });

    test('level threshold is respected', () async {
      final fake = _FakeWebSocket();
      final t = _FakeWebSocketTransport(
        'ws://localhost:9000',
        fake,
        level: LogLevel.error,
      );

      await t.log(_event(LogLevel.info, 'ignored'));
      expect(fake.sent, isEmpty);
    });

    test('optional fields omitted when null', () async {
      final fake = _FakeWebSocket();
      final t = _FakeWebSocketTransport('ws://localhost:9000', fake);

      await t.log(_event(LogLevel.info, 'msg'));

      final decoded = jsonDecode(fake.sent.first as String) as Map;
      expect(decoded.containsKey('context'), isFalse);
      expect(decoded.containsKey('error'), isFalse);
      expect(decoded.containsKey('stackTrace'), isFalse);
    });

    test('optional fields present when set', () async {
      final fake = _FakeWebSocket();
      final t = _FakeWebSocketTransport('ws://localhost:9000', fake);
      final err = Exception('boom');
      final st = StackTrace.current;

      await t.log(
        LogEvent(
          level: LogLevel.error,
          message: 'err',
          context: 'auth',
          error: err,
          stackTrace: st,
        ),
      );

      final decoded = jsonDecode(fake.sent.first as String) as Map;
      expect(decoded['context'], 'auth');
      expect(decoded['error'], err.toString());
      expect(decoded['stackTrace'], st.toString());
    });

    test('does not throw when connection fails', () async {
      final t = _FailingWebSocketTransport('ws://localhost:9999');
      // Must not throw
      await expectLater(t.log(_event(LogLevel.info, 'msg')), completes);
      await t.dispose();
    });

    test('dispose closes the socket', () async {
      final fake = _FakeWebSocket();
      final t = _FakeWebSocketTransport('ws://localhost:9000', fake);

      await t.log(_event(LogLevel.info, 'msg')); // triggers connect
      await t.dispose();

      expect(fake.closeCalled, isTrue);
    });
  });
}
