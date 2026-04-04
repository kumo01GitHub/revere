# Revere Logger

Revere is a modular logging monorepo for Dart/Flutter applications.
It provides a core logger and multiple optional transport packages so you can route logs to different destinations with a consistent API.

Compared to other Dart/Flutter logger options, Revere is designed for practical production use with:

- **Diverse transports**: Freely combine and extend outputs such as console, file, Firebase, Android, notifications, and Swift.
- **Multi-platform coverage**: Keep a consistent logging model across Dart/Flutter, Android, iOS (Swift), and Firebase.
- **Extensibility and customization**: Add custom transports and control log levels/formats per transport.
- **Production-ready capabilities**: Use features such as file rotation, Crashlytics integration, and notification delivery.
- **Modular package design**: Adopt only what you need to keep dependencies and binary size lean.

## Design Philosophy

1. **Flexibility & Extensibility**
  - Architecture allows easy addition and switching of any transport (output backend).
  - Choose the optimal configuration for your use case.
2. **Consistent Multi-Platform Experience**
  - Provides a unified logging experience across Flutter apps, servers, Android/iOS native, and cloud integrations.
3. **Production-Oriented**
  - Focus on features truly needed in the field, such as log rotation, remote delivery, and failure notifications.
4. **Simple API & Easy Adoption**
  - Intuitive API design and modular structure allow you to adopt only what you need.

## Quick Start

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

## Packages

| Package | Role |
|---|---|
| `core` | Core logger primitives: `Logger`, `Transport`, `LogEvent`, `LogLevel`, built-in console and HTTP transports |
| `file_transport` | File output and rolling file output |
| `firebase_transport` | Firebase Analytics and Crashlytics transports |
| `android_log_transport` | Android Logcat transport |
| `notification_transport` | Local notification transport (mobile/desktop) |
| `swift_log_transport` | Apple swift-log transport for iOS/macOS |

## Directory Structure

```text
packages/
  core/                   # Core logger (Logger, Console/HTTP, base)
  file_transport/         # File and rolling file output
  firebase_transport/     # Firebase Analytics/Crashlytics output
  android_log_transport/  # Android Logcat output
  notification_transport/ # Notification output (push/desktop)
  swift_log_transport/    # Apple swift-log output
```

## Features

- Multiple transports per logger (e.g. file + Firebase + console)
- Per-transport config (format, color, headers, etc.)
- Log level threshold per transport
- Fully asynchronous, awaitable logging
- Easy extension via abstract base class

## Provided Transports

| Package Name            | Description / Features |
|--------------------------|-------------------------------------------------------|
| core (Console/HTTP)     | Console output and HTTP POST. Config: color, format, headers, etc. |
| file_transport          | File output and rolling file support |
| firebase_transport      | Firebase Analytics/Crashlytics. Configurable event name and format |
| android_log_transport   | Android Logcat output. Configurable tag and format |
| notification_transport  | Push/desktop notification output. Configurable title and format |
| swift_log_transport     | Apple swift-log output. Configurable label, metadata, and format |

## Package Documentation

See each package README for setup, configuration, and platform-specific notes.

## How to Extend

- Inherit from the `Transport` abstract class and implement `emitLog`
- Add your Transporter to the logger via `addTransport`

---

## Testing

- Run `flutter test` in each package to verify logger and transports.
