# Revere Notification Transport

Transport for sending logs as push notifications (mobile) and to the notification center (desktop) using `flutter_local_notifications`.

---

## Overview

- Sends logs as notifications on Android, iOS, macOS, Linux, and Windows
- Configurable notification title and message template via config
- Uses the `flutter_local_notifications` package

---

## Usage

```dart
import 'package:notification_transport/notification_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(NotificationTransport(config: {
	// Title supports placeholders: {level}, {context}
	'title': '[{level}] {context}',
	// Body/message supports: {level}, {message}, {timestamp}, {error}, {stackTrace}, {context}
	'format': '[{level}] {message}',
	// Android only:
	'androidChannelId': 'myapp_logs',
	'androidChannelName': 'MyApp Logs',
	'androidChannelDescription': 'Log notifications',
}));

await logger.info('Hello notification!');
```

---

## Configuration

- `title`: Notification title (all platforms, supports `{level}` and `{context}` placeholders; default: `[{level}] {context}`)
- `format`: Message template (body, supports `{level}`, `{message}`, `{timestamp}`, `{error}`, `{stackTrace}`, `{context}`; default: `[{level}] {message}`)
- `androidChannelId`: Notification channel ID (Android)
- `androidChannelName`: Channel name (Android)
- `androidChannelDescription`: Channel description (Android)

---

## App-side Setup

- Add dependency in your app's `pubspec.yaml`:
```yaml
dependencies:
	notification_transport:
		path: ../notification_transport
```
- Follow the [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications) for platform-specific setup (Android/iOS/macos/linux/windows).

---

## Notes

- This transport only triggers notifications; ensure your app is configured to display them on each platform.
- For advanced notification features, refer to the `flutter_local_notifications` documentation.

## Features

- Cross-platform: Android, iOS, macOS, Linux, Windows
- Sends log messages as system notifications
- Customizable notification title and message format
- Supports all log levels and context

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Additional information

For more information, see:
- [flutter_local_notifications documentation](https://pub.dev/packages/flutter_local_notifications)
- [Revere logger documentation](https://github.com/your-org/revere) (replace with actual URL)

Contributions and issues are welcome! Please open an issue or pull request on the repository.
