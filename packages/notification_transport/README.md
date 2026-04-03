# Revere Notification Transport

## Overview
Sends logs as push notifications (mobile) and to the notification center (desktop) using `flutter_local_notifications`.

## Usage
```dart
import 'package:notification_transport/notification_transport.dart';
import 'package:revere/core.dart';
final logger = Logger();
logger.addTransport(NotificationTransport(config: {
	'title': '[{level}] {context}',
	'format': '[{level}] {message}',
	'androidChannelId': 'myapp_logs',
	'androidChannelName': 'MyApp Logs',
	'androidChannelDescription': 'Log notifications',
}));
await logger.info('Hello notification!');
```

## Configuration
- `title`: Notification title (all platforms, supports `{level}` and `{context}`; default: `[{level}] {context}`)
- `format`: Notification body/message (supports `{level}`, `{message}`, `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`; default: `[{level}] {message}`)
- `androidChannelId`: Android channel ID (default: 'revere_logs')
- `androidChannelName`: Android channel name (default: 'Revere Logs')
- `androidChannelDescription`: Android channel description (default: 'Log notifications')

## App-side Setup
Add dependency in your app's `pubspec.yaml`:
```yaml
dependencies:
	notification_transport:
		path: ../notification_transport
	flutter_local_notifications: ^latest
```

## Additional Information
- Works on Android, iOS, macOS, Linux, and Windows.
- Uses flutter_local_notifications for cross-platform support.
- For advanced notification features, refer to the flutter_local_notifications documentation.
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
