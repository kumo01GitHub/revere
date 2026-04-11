# revere_flutter_extension Example

This is a cross-platform example app demonstrating the features of `revere_flutter_extension`:
- Metrics logging (memory, etc.)
- Widget/state lifecycle logging
- Floating action button to launch a dialog

## Supported Platforms

- Windows
- Linux
- macOS
- iOS
- Android

## How to Run

1. `cd example`
2. `flutter pub get`
3. `flutter run -d <platform>`

Replace `<platform>` with your target (windows, linux, macos, ios, android, etc).

## Main Features

- See `main.dart` for usage of `MetricsTransport`, `WidgetLogTransport`, `WidgetLogMixin`, and `FloatingWidgetLauncher`.
- Open the floating action button to show a dialog (replace with your own metrics UI as needed).
