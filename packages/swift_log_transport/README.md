a specialized package that includes platform-specific implementation code for
samples, guidance on mobile development, and a full API reference.
# Revere Swift Log Transport

Transporter for outputting logs to Apple swift-log from the revere logger (iOS/macOS).

---

## Overview

- Sends logs from Dart/Flutter directly to Apple swift-log
- Configurable label, metadata, and message template via config

---

## Usage

```dart
import 'package:swift_log_transport/swift_log_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(SwiftLogTransport(config: {
	'label': 'MyApp',
	'metadata': {'env': 'prod'},
	'format': '[{level}] {message}',
}));

await logger.info('Hello iOS/macOS!');
```

---

## App-side Setup

- Add dependency in pubspec.yaml:
```yaml
dependencies:
	swift_log_transport:
		path: ../swift_log_transport
```

- No special setup required for iOS/macOS projects (standard swift-log output)

---

## Main Config Options

- `label`: swift-log label
- `metadata`: Additional metadata (Map<String, String>)
- `format`: Message template

---

See also comments in lib/swift_log_transport.dart for details.

