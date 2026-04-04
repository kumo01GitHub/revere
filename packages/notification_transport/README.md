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
	'groupKey': 'myapp_log_group',
	'androidOngoing': false,
	'darwinThreadIdentifier': 'myapp_logs',
	'linuxDefaultActionName': 'View Log',
}));
await logger.info('Hello notification!');
```

If you have already initialized `FlutterLocalNotificationsPlugin` in your app,
pass it directly and initialization will be skipped:
```dart
final plugin = FlutterLocalNotificationsPlugin();
// ... your own initialize() call ...
logger.addTransport(NotificationTransport(plugin: plugin));
```

## Configuration

### General
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `format` | `String` | `'[{level}] {message}'` | Notification body template. Tokens: `{level}`, `{message}`, `{timestamp}`, `{error}`, `{stackTrace}`, `{context}` |
| `title` | `String` | `'[{level}] {context}'` | Notification title template. Tokens: `{level}`, `{context}` |

### Android
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `androidChannelId` | `String` | `'revere_logs'` | Notification channel ID |
| `androidChannelName` | `String` | `'Revere Logs'` | Notification channel name |
| `androidChannelDescription` | `String` | `'Log notifications'` | Notification channel description |
| `androidIcon` | `String` | `'@mipmap/ic_launcher'` | Notification icon resource name (also used in initialization) |
| `groupKey` | `String?` | `null` | Notification group key |
| `androidGroupSummary` | `bool` | `false` | Whether this notification acts as the group summary |
| `androidAutoCancel` | `bool` | `true` | Dismiss notification when tapped |
| `androidOngoing` | `bool` | `false` | Whether the notification is ongoing (cannot be dismissed by the user) |
| `androidSilent` | `bool` | `false` | Post the notification silently (no sound, vibration, or visual interruption) |
| `androidPlaySound` | `bool` | `true` | Play sound with notification |
| `androidEnableVibration` | `bool` | `true` | Vibrate with notification |

### iOS / macOS (Darwin)
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `darwinPresentAlert` | `bool?` | `null` | Show alert when app is in foreground (null = use initialization default) |
| `darwinPresentBadge` | `bool?` | `null` | Update app badge when notification arrives |
| `darwinPresentSound` | `bool?` | `null` | Play sound when app is in foreground |
| `darwinPresentBanner` | `bool?` | `null` | Show banner when app is in foreground (iOS 14+ / macOS 11+) |
| `darwinBadgeNumber` | `int?` | `null` | Badge number to display on app icon |
| `darwinSubtitle` | `String?` | `null` | Notification subtitle |
| `darwinThreadIdentifier` | `String?` | `null` | Thread identifier for notification grouping |

### Linux
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `linuxDefaultActionName` | `String` | `'Open'` | Label for the default notification action (also used in initialization) |

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
