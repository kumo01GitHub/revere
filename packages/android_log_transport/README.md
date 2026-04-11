# Revere Android Log Transport

Outputs logs from the revere logger to Android Logcat. Useful for debugging and monitoring on Android devices.

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

## Configuration

- `tag`: Logcat tag (default: 'Revere')
- `format`: Message format (default: `'{message}'`)

## App-side Setup

N/A

## Additional Information

- No special permissions required in AndroidManifest.xml (standard logcat output)
- Output can be viewed on real devices or emulators via logcat.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
