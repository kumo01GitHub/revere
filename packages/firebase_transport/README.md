
# Revere Firebase Transport

Transporters for sending logs to Firebase Analytics and Crashlytics from the revere logger.

---

## Overview

- Firebase Analytics: Custom event name, message template, and callOptions supported
- Firebase Crashlytics: Custom message template supported

---

## Usage

```dart
import 'package:firebase_transport/analytics_transport.dart';
import 'package:firebase_transport/crashlytics_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(AnalyticsTransport(config: {
	'name': 'custom_event',
	'template': '[{level}] {message}',
	// 'callOptions': AnalyticsCallOptions(...),
}));
logger.addTransport(CrashlyticsTransport(config: {
	'template': '[{level}] {message} {context}',
}));

await logger.info('Hello Firebase!');
```

---

## App-side Setup

1. Add dependencies to pubspec.yaml
```yaml
dependencies:
	firebase_core: ^2.0.0
	firebase_crashlytics: ^3.4.0
	firebase_analytics: ^10.8.0
```

2. Initialize Firebase in your app
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	await Firebase.initializeApp();
	runApp(MyApp());
}
```

3. (Optional) Enable Crashlytics in debug
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
	// ...
	await Firebase.initializeApp();
	await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
	// ...
}
```

4. Register your app in the Firebase Console and add config files
	- Android: google-services.json
	- iOS: GoogleService-Info.plist
	- See: https://firebase.google.com/docs/flutter/setup

---

## Main Config Options

### AnalyticsTransport
- `name`: Event name (default: log_{level})
- `template`: Message template
- `callOptions`: AnalyticsCallOptions instance

### CrashlyticsTransport
- `template`: Message template

---

See the official Firebase Flutter documentation for more details.
