# Revere Logger

[![CI](https://github.com/kumo01GitHub/revere/actions/workflows/ci.yml/badge.svg)](https://github.com/kumo01GitHub/revere/actions/workflows/ci.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/cff5937f521e4cd684bb435f410fd202)](https://app.codacy.com/gh/kumo01GitHub/revere/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/cff5937f521e4cd684bb435f410fd202)](https://app.codacy.com/gh/kumo01GitHub/revere/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/kumo01GitHub/revere/pulls)

Revere is a modular logging package for Dart/Flutter. Plug in only the transports you need — console, file, Firebase, notifications, and more — and get consistent log routing across mobile, desktop, and server with a single API.

Ideal if you want a logger that's ready to use in minutes, stays lean by including only the transports you need, and already covers the practical production scenarios — file rotation, Crashlytics, native platform logging, and more — without extra glue code.

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

final logger = Logger();
logger.addTransport(ConsoleTransport(level: LogLevel.info));
logger.addTransport(FileTransport('/var/log/app.log'));

await logger.info('Server started');
await logger.error('Something failed', error: e, stackTrace: st);
```

For advanced usage — `LoggerMixin`, `ErrorTrackerMixin`, buffered transport, and per-transport config — see the [revere package README](packages/core/README.md).

## Packages

| Package | Status | Role |
|---|---|---|
| `revere` | [![pub package](https://img.shields.io/pub/v/revere.svg)](https://pub.dev/packages/revere) [![pub points](https://img.shields.io/pub/points/revere)](https://pub.dev/packages/revere/score) | Core logger primitives: `Logger`, `Transport`, `LogEvent`, `LogLevel`, built-in console and HTTP transports |
| `file_transport` | [![pub package](https://img.shields.io/pub/v/file_transport.svg)](https://pub.dev/packages/file_transport) [![pub points](https://img.shields.io/pub/points/file_transport)](https://pub.dev/packages/file_transport/score) | File output and rolling file output |
| `firebase_transport` | [![pub package](https://img.shields.io/pub/v/firebase_transport.svg)](https://pub.dev/packages/firebase_transport) [![pub points](https://img.shields.io/pub/points/firebase_transport)](https://pub.dev/packages/firebase_transport/score) | Firebase Analytics and Crashlytics transports |
| `android_log_transport` | [![pub package](https://img.shields.io/pub/v/android_log_transport.svg)](https://pub.dev/packages/android_log_transport) [![pub points](https://img.shields.io/pub/points/android_log_transport)](https://pub.dev/packages/android_log_transport/score) | Android Logcat transport |
| `swift_log_transport` | [![pub package](https://img.shields.io/pub/v/swift_log_transport.svg)](https://pub.dev/packages/swift_log_transport) [![pub points](https://img.shields.io/pub/points/swift_log_transport)](https://pub.dev/packages/swift_log_transport/score) | Apple swift-log transport for iOS/macOS |
| `notification_transport` | [![pub package](https://img.shields.io/pub/v/notification_transport.svg)](https://pub.dev/packages/notification_transport) [![pub points](https://img.shields.io/pub/points/notification_transport)](https://pub.dev/packages/notification_transport/score) | Local notification transport (mobile/desktop) |

## Directory Structure

```text
packages/
  core/                   # Core logger (Logger, Console/HTTP, base)
  file_transport/         # File and rolling file output
  firebase_transport/     # Firebase Analytics/Crashlytics output
  android_log_transport/  # Android Logcat output
  swift_log_transport/    # Apple swift-log output
  notification_transport/ # Notification output (push/desktop)
```

## Features

- Multiple transports per logger (e.g. file + Firebase + console)
- Per-transport config (format, color, headers, etc.)
- Log level threshold per transport
- Fully asynchronous, awaitable logging
- Easy extension via abstract base class

## Package Documentation

See each package README for setup, configuration, and platform-specific notes.

## How to Extend

Implement the `Transport` abstract class and add it via `logger.addTransport()`.
Details and a worked example are in the [revere package README](packages/core/README.md).

## Testing

Run `flutter test` in each package to verify logger and transports.
