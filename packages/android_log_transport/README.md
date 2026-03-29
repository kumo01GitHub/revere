a specialized package that includes platform-specific implementation code for
samples, guidance on mobile development, and a full API reference.
# Revere Android Log Transport

Transporter for outputting logs to Android Logcat from the revere logger.

---

## Overview

- Sends logs from Dart/Flutter directly to Android logcat
- Configurable tag and message template via config

---

## Usage

```dart
import 'package:android_log_transport/android_log_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(AndroidLogTransport(config: {
	'tag': 'MyApp',
	'format': '[{level}] {message}',
}));

await logger.info('Hello Android!');
```

---

## App-side Setup

- Add dependency in pubspec.yaml:
```yaml
dependencies:
	android_log_transport:
		path: ../android_log_transport
```

- No special permissions required in AndroidManifest.xml (standard logcat output)
- Output can be viewed on real devices or emulators via logcat

---

## Main Config Options

- `tag`: logcat tag (default if omitted)
- `format`: message template

---

See also comments in lib/android_log_transport.dart for details.

