# Revere WebSocket Transport

Streams log events as JSON frames over a WebSocket connection.

Useful for real-time log monitoring, development tooling, and AI agent log feeds.
The transport reconnects automatically when the connection is lost.

## Usage

```dart
import 'package:websocket_transport/websocket_transport.dart';
import 'package:revere/core.dart';
final transport = WebSocketTransport(
  'ws://localhost:9000/logs',
  level: LogLevel.debug,
);
final logger = Logger();
logger.addTransport(transport);

await logger.info('Hello WebSocket!');

// Dispose when done:
await transport.dispose();
```

### JSON payload

Each log event is sent as a UTF-8 text frame:
```json
{
  "level": "info",
  "message": "Hello WebSocket!",
  "timestamp": "2024-03-01T12:00:00.000Z",
  "context": "AuthService"
}
```
`context`, `error`, and `stackTrace` are omitted when null.

### Reconnection

Events emitted while the connection is unavailable are dropped. The transport
retries with exponential back-off (1 s → 2 s → 4 s … capped at `maxReconnectDelay`).

## Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `uri` | `String` | required | WebSocket server URI (e.g. `ws://host:port/path`) |
| `level` | `LogLevel` | `LogLevel.info` | Minimum level to forward |
| `maxReconnectDelay` | `Duration` | `Duration(seconds: 30)` | Back-off cap for reconnection |

## App-side Setup

N/A

## Additional Information

- Works on all Dart/Flutter platforms that support `dart:io`.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
