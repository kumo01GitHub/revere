import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
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

class _ThrowingAddWebSocket extends _FakeWebSocket {
  @override
  void add(dynamic data) => throw const SocketException('broken pipe');
}

/// Transport whose [createWebSocket] is provided by a callback, allowing
/// tests to control connection behaviour (blocking, failing, etc.).
class _CallbackTransport extends WebSocketTransport {
  final Future<WebSocket> Function(String) _factory;

  _CallbackTransport(
    super.url,
    this._factory, {
    super.maxReconnectDelay,
  });

  @override
  Future<WebSocket> createWebSocket(String url) => _factory(url);
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

    test('concurrent log calls share in-flight connect future', () async {
      final fake = _FakeWebSocket();
      final blocker = Completer<void>();
      final t = _CallbackTransport('ws://localhost:9000', (_) async {
        await blocker.future;
        return fake;
      });

      // Both calls started before connection completes — second hits L55.
      final f1 = t.log(_event(LogLevel.info, 'first'));
      final f2 = t.log(_event(LogLevel.info, 'second'));

      blocker.complete();
      await Future.wait([f1, f2]);

      expect(fake.sent, hasLength(2));
      await t.dispose();
    });

    test('socket.add failure drops event without throwing', () async {
      final throwing = _ThrowingAddWebSocket();
      final t = _FakeWebSocketTransport('ws://localhost:9000', throwing);

      await expectLater(t.log(_event(LogLevel.info, 'msg')), completes);
      await t.dispose();
    });

    test('reconnect callback fires after delay and caps back-off', () {
      // Use fakeAsync so the 1-second Future.delayed runs without real wait.
      fakeAsync((async) {
        var connectCount = 0;
        final fake = _FakeWebSocket();
        final t = _CallbackTransport(
          'ws://localhost:9000',
          (_) {
            connectCount++;
            if (connectCount == 1) {
              return Future.error(const SocketException('refused'));
            }
            return Future.value(fake);
          },
          // With maxReconnectDelay == initial delay (1s), the doubled delay
          // (2s) exceeds the cap and L103 is hit on the very first reconnect.
          maxReconnectDelay: const Duration(seconds: 1),
        );

        t.log(_event(LogLevel.info, 'msg')); // fire-and-forget
        async.flushMicrotasks(); // connect fails → _scheduleReconnect → L103

        async.elapse(const Duration(seconds: 1)); // timer fires → L98–99
        async.flushMicrotasks(); // second _connect succeeds

        expect(connectCount, 2);
        t.dispose();
        async.flushMicrotasks();
      });
    });
  });
}
