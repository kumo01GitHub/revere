import 'dart:convert';
import 'dart:io';

import 'transport.dart';
import 'log_event.dart';

/// Transport for HTTP output (format)
class HttpTransport extends Transport {
  final String endpoint;
  final Map<String, String> headers;
  final String? proxy;
  final int? timeout;

  /// config: {`headers`: Map&lt;String, String&gt;, `proxy`: String, `timeout`: int(ms)}
  HttpTransport(this.endpoint, {super.level, super.config})
    : headers = (config['headers'] as Map<String, String>?) ?? {},
      proxy = config['proxy'] as String?,
      timeout = config['timeout'] as int?;

  @override
  Future<void> emitLog(LogEvent event) async {
    try {
      final payload = {
        'level': event.level.name,
        'message': event.message,
        'timestamp': event.timestamp.toIso8601String(),
        if (event.error != null) 'error': event.error.toString(),
        if (event.stackTrace != null) 'stackTrace': event.stackTrace.toString(),
      };
      final uri = Uri.parse(endpoint);
      final client = HttpClient();
      // Proxy support
      if (proxy != null) {
        client.findProxy = (_) => 'PROXY $proxy;';
      }
      final request = await client.postUrl(uri);
      // Headers support
      headers.forEach((k, v) => request.headers.set(k, v));
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      // Timeout support
      if (timeout != null) {
        final response = await request.close().timeout(
          Duration(milliseconds: timeout!),
        );
        await response.drain();
      } else {
        final response = await request.close();
        await response.drain();
      }
      client.close();
    } catch (e) {
      // Optionally handle errors (e.g., print or ignore)
    }
  }
}
