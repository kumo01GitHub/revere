import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revere/core.dart';

/// Streams log events as JSON over a WebSocket connection.
///
/// Each log event is serialised as a JSON object and sent as a text frame.
/// The transport automatically reconnects when the connection is lost, with
/// an exponential back-off capped at [maxReconnectDelay].
///
/// Call [dispose] when the transport is no longer needed to close the
/// connection and cancel the reconnect timer.
///
/// JSON payload keys:
/// | key | type | notes |
/// |-----|------|-------|
/// | `level` | String | e.g. `"info"` |
/// | `message` | String | |
/// | `timestamp` | String | ISO-8601 |
/// | `context` | String? | |
/// | `error` | String? | |
/// | `stackTrace` | String? | |
///
/// Example:
/// ```dart
/// final transport = WebSocketTransport('ws://localhost:9000/logs');
/// final logger = Logger(transports: [transport]);
/// // ...
/// await transport.dispose();
/// ```
class WebSocketTransport extends Transport {
  /// The WebSocket server URI to connect to.
  final Uri uri;

  /// Maximum delay between reconnection attempts. Default: 30 seconds.
  final Duration maxReconnectDelay;

  WebSocket? _socket;
  bool _disposed = false;
  Duration _reconnectDelay = const Duration(seconds: 1);
  Future<void>? _connectFuture;

  WebSocketTransport(
    String uri, {
    this.maxReconnectDelay = const Duration(seconds: 30),
    super.level,
    super.config,
  }) : uri = Uri.parse(uri);

  /// Ensures a WebSocket connection is open, (re)connecting if needed.
  Future<void> _ensureConnected() async {
    if (_connectFuture != null) {
      await _connectFuture;
      return;
    }
    if (_socket != null && _socket!.closeCode == null) {
      return;
    }
    _connectFuture = _connect();
    await _connectFuture;
    _connectFuture = null;
  }

  Future<void> _connect() async {
    if (_disposed) return;
    try {
      _socket = await createWebSocket(uri.toString());
      _reconnectDelay = const Duration(seconds: 1);
      _socket!.done.then((_) {
        _socket = null;
      });
    } catch (_) {
      _socket = null;
    }
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    await _ensureConnected();
    if (_socket == null || _socket!.closeCode != null) {
      // Connection unavailable — drop event and schedule reconnect.
      _scheduleReconnect();
      return;
    }
    try {
      _socket!.add(_serialize(event));
    } catch (_) {
      _socket = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    Future.delayed(_reconnectDelay, () async {
      if (_disposed) return;
      await _connect();
    });
    _reconnectDelay = _reconnectDelay * 2;
    if (_reconnectDelay > maxReconnectDelay) {
      _reconnectDelay = maxReconnectDelay;
    }
  }

  String _serialize(LogEvent event) => jsonEncode({
    'level': event.level.name,
    'message': event.message.toString(),
    'timestamp': event.timestamp.toIso8601String(),
    if (event.context != null) 'context': event.context,
    if (event.error != null) 'error': event.error.toString(),
    if (event.stackTrace != null) 'stackTrace': event.stackTrace.toString(),
  });

  /// Closes the WebSocket connection.
  ///
  /// After calling this method, the transport must not be used again.
  Future<void> dispose() async {
    _disposed = true;
    await _socket?.close();
    _socket = null;
  }

  /// Creates the underlying [WebSocket]. Override in tests to inject a fake.
  Future<WebSocket> createWebSocket(String url) => WebSocket.connect(url); // coverage:ignore-line
}
