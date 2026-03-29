# Revere File Transport

Transporters for file output and rolling file output.

---

## Overview

- FileTransport: Simple file append logging
- RollingFileTransport: Automatic log rotation by size and generations

---

## Usage

### FileTransport (simple file logging)
```dart
import 'package:file_transport/file_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(FileTransport('/tmp/mylog.log'));
// or with config:
logger.addTransport(FileTransport(null, config: {'filePath': '/tmp/mylog2.log'}));

await logger.info('Hello file!');
```

### RollingFileTransport (log rotation)
```dart
import 'package:file_transport/rolling_file.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(RollingFileTransport(
  '/tmp/rolling.log',
  maxBytes: 1024 * 10, // Rotate every 10KB
  maxFiles: 3,
));
// or with config:
logger.addTransport(RollingFileTransport(null, config: {
  'filePath': '/tmp/rolling2.log',
  'maxBytes': 2048,
  'maxFiles': 2,
}));

await logger.info('Rolling log!');
```

---

## App-side Setup

- Add dependency in pubspec.yaml:
```yaml
dependencies:
  file_transport:
    path: ../file_transport
```

- Ensure file write permissions if needed (especially on mobile/desktop; check path validity)

---

## Main Config Options

### FileTransport
- `filePath`: Output file path

### RollingFileTransport
- `filePath`: Output file path
- `maxBytes`: Max bytes per file
- `maxFiles`: Number of rotation generations

---

## Testing

Run tests in this package:
```
flutter test
```

---
See also: file_transport_test.dart, rolling_file_transport_test.dart for usage examples.
