import 'dart:convert';
import 'dart:io';

import '../transport.dart';
import '../log_event.dart';

/// Signature for a custom payload builder.
///
/// The returned value must be JSON-encodable (e.g. a `Map<String, dynamic>`
/// or a `List`). If the value implements `toJson()`, [jsonEncode] will call it
/// automatically.
typedef LogEventSerializer = Object Function(LogEvent event);

/// Transport that sends log events to an HTTP endpoint as JSON.
///
/// By default the payload is:
/// ```json
/// {
///   "level": "info",
///   "message": <message.toString() or the object itself if Map/List>,
///   "timestamp": "2024-...",
///   "error": "...",      // omitted when null
///   "stackTrace": "...", // omitted when null
///   "context": "..."     // omitted when null
/// }
/// ```
///
/// Provide [serializer] to send a fully custom payload:
/// ```dart
/// HttpTransport(
///   'https://example.com/logs',
///   serializer: (e) => {'ts': e.timestamp.millisecondsSinceEpoch, 'msg': e.message},
/// )
/// ```
///
/// config keys:
/// - `headers` (Map[String, String]): additional request headers.
/// - `proxy` (String): proxy address, e.g. `"localhost:8888"`.
/// - `timeout` (int): request timeout in milliseconds.
class HttpTransport extends Transport {
  final String endpoint;
  final Map<String, String> headers;
  final String? proxy;
  final int? timeout;

  /// Optional custom serializer. When set, its return value is JSON-encoded
  /// and sent as the request body, replacing the default payload.
  final LogEventSerializer? serializer;

  HttpTransport(this.endpoint, {super.level, super.config, this.serializer})
    : headers = (config['headers'] as Map<String, String>?) ?? {},
      proxy = config['proxy'] as String?,
      timeout = config['timeout'] as int?;

  /// Builds the default JSON payload from [event].
  ///
  /// When [event.message] is a [Map] or [List] it is embedded as-is so that
  /// structured data is preserved in the payload. Otherwise [toString] is used.
  Map<String, dynamic> _defaultPayload(LogEvent event) {
    final msg = event.message;
    return {
      'level': event.level.name,
      'message': (msg is Map || msg is List) ? msg : msg.toString(),
      'timestamp': event.timestamp.toIso8601String(),
      if (event.error != null) 'error': event.error.toString(),
      if (event.stackTrace != null) 'stackTrace': event.stackTrace.toString(),
      if (event.context != null) 'context': event.context,
    };
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    try {
      final payload = serializer != null
          ? serializer!(event)
          : _defaultPayload(event);
      final uri = Uri.parse(endpoint);
      final client = HttpClient();
      if (proxy != null) {
        client.findProxy = (_) => 'PROXY $proxy;';
      }
      final request = await client.postUrl(uri);
      headers.forEach((k, v) => request.headers.set(k, v));
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      if (timeout != null) {
        final response = await request.close().timeout(
          Duration(milliseconds: timeout!),
        );
        await response.drain<void>();
      } else {
        final response = await request.close();
        await response.drain<void>();
      }
      client.close();
    } catch (_) {
      // Swallow transport errors to avoid disrupting the application.
    }
  }
}
