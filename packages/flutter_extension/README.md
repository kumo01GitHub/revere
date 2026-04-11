# Revere Flutter Extension

Flutter integration for the revere logging core. Provides error tracking and Flutter error hooks for your app.

## Usage

```dart
import 'package:revere_flutter_extension/flutter_error_tracker.dart';

class AppErrorTracker with ErrorTrackerMixin {
  @override
  Logger get logger => MyApp.logger;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorTracker().setupFlutterErrorTracking();
  runApp(const MyApp());
}
```

## Features

- Installs global error handlers for Flutter and platform errors
- Forwards uncaught errors to your logger via ErrorTrackerMixin

## Additional Information

- Works with any logger using ErrorTrackerMixin from revere core
- Repository: [github.com/kumo01GitHub/revere](https://github.com/kumo01GitHub/revere)
