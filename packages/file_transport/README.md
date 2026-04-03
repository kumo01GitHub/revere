# Revere File Transport

## Overview
Provides file-based logging for the revere logger, including simple file output and automatic log rotation.

## Usage
```dart
import 'package:file_transport/file_transport.dart';
import 'package:revere/core.dart';
final logger = Logger();
logger.addTransport(FileTransport('/tmp/mylog.log'));
// Rolling file example:
import 'package:file_transport/rolling_file.dart';
logger.addTransport(RollingFileTransport('/tmp/rolling.log', maxBytes: 10240, maxFiles: 3));
await logger.info('Hello file!');
```

## Configuration
- `filePath`: Output file path (required)
- `maxBytes`: Max file size before rotation (RollingFileTransport)
- `maxFiles`: Number of rotated files to keep (RollingFileTransport)

## App-side Setup
Add dependency in pubspec.yaml:
```yaml
dependencies:
  file_transport:
    path: ../file_transport
```

## Additional Information
- Works on all Dart/Flutter platforms supporting file I/O.
- For advanced log rotation, see RollingFileTransport options.
- See also: file_transport_test.dart, rolling_file_transport_test.dart for usage examples.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
