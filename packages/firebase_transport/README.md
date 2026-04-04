# Revere Firebase Transport

## Overview
Provides transports for sending logs to Firebase Analytics and Crashlytics from the revere logger.

## Usage
```dart
import 'package:firebase_transport/analytics_transport.dart';
import 'package:firebase_transport/crashlytics_transport.dart';
import 'package:revere/core.dart';
final logger = Logger();
logger.addTransport(AnalyticsTransport(config: {
	'name': 'custom_event',
	'format': '[{level}] {message}',
}));
logger.addTransport(CrashlyticsTransport(config: {
	'format': '[{level}] {message} {context}',
}));
await logger.info('Hello Firebase!');
```

## Configuration
- `name`: Event name (AnalyticsTransport, default: `'revere'`)
- `format`: Message format (both transports, default: `'[{level}:{context}] {message}'`)
- `callOptions`: AnalyticsCallOptions (optional)

## App-side Setup
Add dependencies to pubspec.yaml:
```yaml
dependencies:
	firebase_transport:
		path: ../firebase_transport
	firebase_core: ^latest
	firebase_analytics: ^latest
	firebase_crashlytics: ^latest
```
Initialize Firebase in your app as per the official Firebase Flutter documentation.

## Additional Information
- Requires Firebase initialization in your app.
- See Firebase official docs for setup and configuration.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
