# Revere Sentry Transport

## Overview
Provides a transport for sending logs to [Sentry](https://sentry.io/) from the revere logger.

Log events are routed as follows:

| Event | Sentry action |
|-------|---------------|
| `trace`, `debug`, `info`, `warn` | `Sentry.addBreadcrumb` |
| `error`, `fatal` | `Sentry.captureException` |
| Any level where `LogEvent.error` is non-null | `Sentry.captureException` |

## Usage

### `SentryTransport`
```dart
import 'package:sentry_transport/sentry_transport.dart';
import 'package:revere/core.dart';
final logger = Logger();
logger.addTransport(SentryTransport(level: LogLevel.info));

await logger.info('User signed in');          // → breadcrumb
await logger.error('Payment failed');         // → captureException
await logger.fatal(                           // → captureException (fatal=true)
  'Unhandled exception',
  error: exception,
  stackTrace: stackTrace,
);
```

### `SentryTrackerMixin`
Add `with SentryTrackerMixin` to any class for breadcrumb tracking and error reporting with no boilerplate.

```dart
import 'package:sentry_transport/sentry_tracker_mixin.dart';

class CheckoutService with SentryTrackerMixin {
  // Optional: inject a custom transport instead of the default singleton.
  // @override
  // SentryTransport get sentryTransport => _myTransport;

  Future<void> purchase(Item item) async {
    // Record a named breadcrumb.
    await trackAction('purchase', params: {'item_id': item.id});

    // Wrap a block — breadcrumb on entry, errors auto-forwarded to Sentry.
    await withTracking('confirm_payment', () async {
      await paymentApi.confirm(item);
    });

    // Minimal error guard with no action name.
    await guarded(() async {
      await inventory.reserve(item);
    });
  }
}
```

Install uncaught error handlers in `main()` to automatically send all
unhandled Flutter and Dart async errors to Sentry:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MyService().setupFlutterErrorTracking();
  runApp(const MyApp());
}
```

## Configuration
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `format` | `String` | `'[{level}:{context}] {message}'` | Breadcrumb message template. Tokens: `{level}`, `{message}`, `{timestamp}`, `{context}`, `{error}`, `{stackTrace}` |

## App-side Setup
Add dependency in your app's `pubspec.yaml`:
```yaml
dependencies:
  sentry_transport:
    path: ../sentry_transport
  sentry_flutter: ^8.0.0
```

Initialise Sentry before using the transport (see [sentry_flutter docs](https://docs.sentry.io/platforms/flutter/)).

## Additional Information
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
