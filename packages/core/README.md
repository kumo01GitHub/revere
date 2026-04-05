# Revere Core

## Overview

The core package for the Revere ecosystem. Provides `Logger`, `Transport`, `LogLevel`, `LogEvent`, built-in transports, and two opt-in mixins for class-level logging and automatic error tracking.

## Usage

```dart
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(PrettyConsoleTransport(level: LogLevel.debug));
logger.addTransport(HttpTransport(
  'https://example.com/logs',
  level: LogLevel.error,
  config: {'headers': {'Authorization': 'Bearer token'}, 'timeout': 2000},
));

await logger.info('Server started', context: 'Main');
await logger.error('Unhandled exception', error: e, stackTrace: st, context: 'Main');
```

## Log Levels

In order from lowest to highest severity: `trace`, `debug`, `info`, `warn`, `error`, `fatal`.

Each transport filters events by comparing `event.level >= transport.level`.

## Built-in Transports

### ConsoleTransport

Writes to stdout with a configurable format string.

```dart
ConsoleTransport(
  level: LogLevel.info,
  config: {
    'format': '{timestamp} [{level}] {message}',  // default template
    'colorize': true,                              // ANSI color output
  },
)
```

Template placeholders: `{level}`, `{message}`, `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`.

### PrettyConsoleTransport

Human-friendly output with emoji indicators, aligned level labels, and optional error/stack trace formatting.

```
🐛 DEBUG  12:34:56.789  [MyApp] Hello world
ℹ️ INFO   12:34:56.790  [MyApp] Server started
🔥 ERROR  12:34:56.792  [MyApp] Unhandled exception
          ↳ Exception: something went wrong
          ↳ #0  main (file:///...:10:5)
```

```dart
PrettyConsoleTransport(
  level: LogLevel.debug,
  config: {
    'colorize': true,         // ANSI colors (default true)
    'showTimestamp': true,    // HH:mm:ss.SSS prefix (default true)
    'showContext': true,      // context label (default true)
    'showStackTrace': true,   // stack traces (default true)
  },
)
```

### HttpTransport

Posts log events as JSON to an HTTP endpoint. Optionally provide a `serializer` for a custom payload shape.

```dart
HttpTransport(
  'https://logs.example.com/ingest',
  level: LogLevel.warn,
  config: {
    'headers': {'X-Api-Key': 'secret'},
    'timeout': 3000,   // ms
    'proxy': 'localhost:8888',
  },
)

// Custom payload
HttpTransport(
  'https://logs.example.com/ingest',
  serializer: (e) => {'ts': e.timestamp.millisecondsSinceEpoch, 'msg': e.message},
)
```

### BufferedTransport

Decorator that batches events before forwarding them to an inner transport. Flush is triggered when the buffer reaches `maxSize` or after `flushInterval`.

```dart
// Wrap any transport
final buffered = HttpTransport('https://logs.example.com')
    .withBuffer(maxSize: 50, flushInterval: Duration(seconds: 30));

logger.addTransport(buffered);

// Drain on app shutdown
await buffered.dispose();
```

### SamplingTransport

Decorator that probabilistically forwards events to an inner transport. Events at unlisted `levels` are always forwarded; listed levels are sampled at `sampleRate`.

```dart
import 'package:revere/sampling_transport.dart';

// Forward only 10 % of debug/trace events to Sentry, but always forward errors.
final sampled = SentryTransport()
    .withSampling(
      sampleRate: 0.1,
      levels: [LogLevel.trace, LogLevel.debug],
    );

logger.addTransport(sampled);
```

`sampleRate` must be between `0.0` (drop all) and `1.0` (forward all). Import via `package:revere/sampling_transport.dart`.

## LoggerMixin

Mix into any class for concise, context-aware logging without managing a `Logger` instance manually. The class name is automatically attached as the log context.

| Method | Level |
|--------|-------|
| `t(msg)` | `trace` |
| `d(msg)` | `debug` |
| `i(msg)` | `info` |
| `w(msg)` | `warn` |
| `e(msg)` | `error` |
| `f(msg)` | `fatal` |

```dart
class AuthService with LoggerMixin {
  Future<void> signIn(String email) async {
    await i('Sign-in attempt for $email');
    try {
      await _api.signIn(email);
      await i('Sign-in succeeded');
    } catch (err, st) {
      await e('Sign-in failed', error: err, stackTrace: st);
      rethrow;
    }
  }
}
```

All methods accept optional `error` and `stackTrace` parameters.

`LoggerMixin.logger` is a shared singleton. Configure it once at app startup:

```dart
void main() {
  LoggerMixin.logger.addTransport(PrettyConsoleTransport());
  runApp(const MyApp());
}
```

Override `loggerContext` to provide a custom label:

```dart
@override
String get loggerContext => 'AuthModule';
```

## ErrorTrackerMixin

Adds structured error tracking and optional global Flutter error handling to any class.

### trackError

Records an error at `error` level (or `fatal` when `fatal: true`).

```dart
await trackError(e, stackTrace: st, message: 'Payment failed');
await trackError(e, stackTrace: st, fatal: true);
```

### withTracking

Logs an action name at `info` on entry, then catches and records any thrown error before re-throwing.

```dart
Future<void> purchase(Item item) => withTracking(
  'purchase',
  () async { await _api.purchase(item); },
  params: {'item_id': item.id, 'price': item.price},
);
```

### guarded

Wraps a body in try/catch; records any error and re-throws. Use when you need error protection without action logging.

```dart
Future<void> fetchUser(String id) => guarded(() async {
  final data = await api.getUser(id);
  setState(() => _user = data);
});
```

### setupFlutterErrorTracking

Installs `FlutterError.onError` and `PlatformDispatcher.instance.onError` handlers. Call once at startup.

```dart
class AppErrorTracker with ErrorTrackerMixin {
  @override
  Logger get logger => MyApp.logger;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorTracker().setupFlutterErrorTracking();
  runApp(const MyApp());
}
```

## How to Extend

Implement `emitLog` in a subclass of `Transport`:

```dart
class MyTransport extends Transport {
  MyTransport({super.level, super.config});

  @override
  Future<void> emitLog(LogEvent event) async {
    // deliver event to your destination
  }
}

logger.addTransport(MyTransport(level: LogLevel.warn));
```

## Additional Information

- Foundation for all other Revere packages (`file_transport`, `firebase_transport`, etc.)
- Run `flutter test` in this package to verify logger and transports
- Repository: [github.com/kumo01GitHub/revere](https://github.com/kumo01GitHub/revere)
