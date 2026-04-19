# Revere Debug Extension

A Flutter plugin for the revere logger that enables in-app, real-time collection and visualization of app metrics (such as memory and CPU usage) and logs. Provides widgets for displaying metrics and logs, state management for log history, and a floating button to toggle the debug UI.

## Usage

```dart
import 'package:revere_debug_extension/revere_debug_extension.dart';
import 'package:revere/core.dart';

final metricsLogger = MetricsLogger();
metricsLogger.addTransport(PrettyConsoleTransport());
final normalLogger = Logger();
normalLogger.addTransport(PrettyConsoleTransport());

// Start metrics collection
metricsLogger.start();

// Stop metrics collection
metricsLogger.stop();
```

To display the debug UI in your app, add the floating button widget:

```dart
FloatingMetricsButton(
	loggers: [normalLogger, metricsLogger.logger],
	tabNames: ['Normal', 'Metrics'],
)
```

## Configuration

- You can set the metrics collection interval and customize the log message format via `metricsLogger.start(interval: ..., formatter: ...)`.
- The maximum number of log entries shown in the UI can be set with the `maxLength` property of `FloatingMetricsButton`.

## App-side Setup

1. Add `revere_debug_extension` and `revere` to your `pubspec.yaml`.
2. Initialize your loggers and add transports as shown above.
3. Place `FloatingMetricsButton` in your widget tree (typically in a `Stack`).

## Additional Information

- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
