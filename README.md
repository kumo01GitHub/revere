# Revere Logging Monorepo

High-performance, extensible logging infrastructure for Dart/Flutter. Supports flexible log routing by combining multiple Transporters (output backends).

---

## Directory Structure

- `packages/core` – Core logger (Logger, Console/HTTP Transporters, abstract base)
- `packages/file_transport` – File and rolling file output
- `packages/firebase_transport` – Firebase Analytics/Crashlytics output
- `packages/android_log_transport` – Android Logcat output
- `packages/swift_log_transport` – Apple swift-log output

---

## Key Features

- Multiple Transporters per logger (e.g. file + Firebase + console)
- Per-Transporter config (format, color, headers, etc.)
- Log level threshold per Transporter
- Fully asynchronous, awaitable logging
- Easy extension via abstract base class

---

## Usage Example

```dart
import 'package:revere/core.dart';
import 'package:file_transport/file_transport.dart';
import 'package:firebase_transport/analytics_transport.dart';

final logger = Logger();
logger.addTransport(ConsoleTransport(
  level: LogLevel.info,
  config: {'format': '[{level}] {message}', 'colorize': true},
));
logger.addTransport(FileTransport('/tmp/app.log'));
logger.addTransport(AnalyticsTransport(config: {'name': 'custom_event'}));

await logger.info('Hello!');
```

---

## Provided Transporters

| Package Name              | Description / Features                                 |
|--------------------------|-------------------------------------------------------|
| core (Console/HTTP)      | Console output, HTTP POST. Config: color, format, headers, etc. |
| file_transport           | File output, rolling file support                      |
| firebase_transport       | Firebase Analytics/Crashlytics. Configurable event name, template |
| android_log_transport    | Android Logcat output. Configurable tag, template      |
| swift_log_transport      | Apple swift-log output. Configurable label, metadata, template |

---

## Details & Setup for Each Transporter

See each package's README.md for details and setup instructions.

---

## How to Extend

- Inherit from the `Transport` abstract class and implement `emitLog`
- Add your Transporter to the logger via `addTransport`

---

## Testing

- Run `flutter test` in each package to verify logger and Transporters.
