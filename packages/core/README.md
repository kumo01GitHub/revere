# Revere Core

## Overview
The core logging package for the Revere ecosystem. Provides the main `Logger` class, log levels, event structure, and the extensible transport (output) system. Designed for high flexibility, async logging, and easy integration with multiple output backends.

## Usage
```dart
import 'package:core/core.dart';

final logger = Logger();
logger.addTransport(ConsoleTransport(
  level: LogLevel.info,
  config: {'format': '[{level}] {message}', 'colorize': true},
));
logger.addTransport(HttpTransport(
  'https://example.com/logs',
  level: LogLevel.error,
  config: {'headers': {'Authorization': 'Bearer ...'}, 'timeout': 2000},
));

await logger.info('Hello');
await logger.error('Oops', error: Exception('fail'));
```

## Features
- Multiple transports per logger (console, HTTP, file, etc.)
- Per-transport configuration and log level threshold
- Fully async, awaitable logging
- Extensible via abstract base class for custom transports
- Simple, intuitive API

## Transports
- **ConsoleTransport**: Output to stdout/stderr, supports color and format customization
- **HttpTransport**: Send logs as JSON to a remote HTTP endpoint (configurable headers, proxy, timeout)
- **Custom**: You can implement your own by extending `Transport`

## How to Extend
- Inherit from the `Transport` abstract class and implement `emitLog(LogEvent event)`
- Add your custom transport to the logger via `addTransport()`

## Additional information
- This is the foundation for all other Revere logging packages (file, firebase, android, etc.)
- See the source code for more details and advanced usage patterns
- Run `flutter test` in this package to verify logger and transports
- For more information, see [revere](https://github.com/kumo01GitHub/revere/).
