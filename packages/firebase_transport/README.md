# Revere Firebase Transport

## Overview
Provides transports for sending logs to Firebase Analytics and Crashlytics from the revere logger.

Three classes are available:

| Class | Description |
|-------|-------------|
| `AnalyticsTransport` | Sends every log event to Firebase Analytics only. |
| `CrashlyticsTransport` | Sends every log event to Firebase Crashlytics only. |
| `FirebaseTransport` | Combined transport — all events go to Analytics, errors also go to Crashlytics. |

A `FirebaseTrackerMixin` is also provided for action tracking and automatic error forwarding without boilerplate.

## Usage

### `FirebaseTransport` (combined, recommended)
```dart
import 'package:firebase_transport/firebase_transport.dart';
import 'package:revere/core.dart';

final logger = Logger();
logger.addTransport(FirebaseTransport(config: {
  'name': 'my_app_{level}',
  'format': '[{level}:{context}] {message}',
}));

await logger.info('User signed in');   // → Analytics only
await logger.error('Payment failed');  // → Analytics + Crashlytics (log)
await logger.error(                    // → Analytics + Crashlytics (recordError)
  'Unhandled exception',
  error: exception,
  stackTrace: stackTrace,
);
```

### `AnalyticsTransport` / `CrashlyticsTransport` (standalone)
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

### `FirebaseTrackerMixin`
Add `with FirebaseTrackerMixin` to any class for action tracking and error reporting with no boilerplate.

```dart
import 'package:firebase_transport/firebase_tracker_mixin.dart';

class CheckoutService with FirebaseTrackerMixin {
  // Optional: inject a custom transport instead of the default singleton.
  // @override
  // FirebaseTransport get firebaseTransport => _myTransport;

  Future<void> purchase(Item item) async {
    // Record a named action to Analytics.
    await trackAction('purchase', params: {'item_id': item.id});

    // Wrap a block — action is logged on entry, errors are auto-forwarded to Crashlytics.
    await withTracking('confirm_payment', () async {
      await paymentApi.confirm(item);
    });

    // Minimal error guard with no action name.
    await guarded(() async {
      await inventory.reserve(item);
    });
  }

  Future<void> refund(Item item) async {
    try {
      await paymentApi.refund(item);
    } catch (e, st) {
      // Manually record an error to Crashlytics.
      await trackError(e, stackTrace: st, message: 'Refund failed');
      rethrow;
    }
  }
}
```

#### Global error tracking (in `main()`)
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hooks FlutterError.onError and PlatformDispatcher.instance.onError.
  // All uncaught errors are forwarded to Crashlytics automatically.
  MyService().setupFlutterErrorTracking();
  runApp(const MyApp());
}
```

## Configuration
- `name`: Analytics event name template (`{context}`, `{level}` placeholders). Default: `'revere'`. (`AnalyticsTransport`, `FirebaseTransport`)
- `format`: Message body template (`{level}`, `{message}`, `{context}`, `{timestamp}`, `{error}`, `{stackTrace}`). Default: `'[{level}:{context}] {message}'`. (all transports)
- `callOptions`: `AnalyticsCallOptions` forwarded to the Analytics SDK. (`AnalyticsTransport`, `FirebaseTransport`)

### `FirebaseTransport` Crashlytics routing rules
| Condition | Crashlytics call |
|-----------|-----------------|
| `LogLevel.error` or `fatal`, **no** `event.error` | `log(message)` |
| `LogLevel.error` or `fatal`, **with** `event.error` | `recordError(error, stackTrace, fatal: false)` |
| `LogLevel.fatal` **with** `event.error` | `recordError(error, stackTrace, fatal: true)` |
| Any level where `event.error != null` | `recordError(error, stackTrace, fatal: false)` |

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
