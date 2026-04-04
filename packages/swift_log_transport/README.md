# Revere Swift Log Transport

## Overview
Outputs logs from the revere logger to Apple swift-log (iOS/macOS). Supports custom label, metadata, and message formatting.

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

## Configuration
- `label`: swift-log label (default: 'Revere')
- `metadata`: swift-log metadata (default: `{}`)
- `format`: Message format (default: `'{message}'`)

## App-side Setup
Add dependency in pubspec.yaml:
```yaml
dependencies:
  swift_log_transport:
    path: ../swift_log_transport
```

## Additional Information
- No special setup required for iOS/macOS projects (standard swift-log output)
- Uses Apple's swift-log under the hood.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
