
# Revere Core

Core logging package. Provides multiple Transporters, async logging, flexible config, and extensibility.

---

## Overview

- Multiple Transporters per logger (Console/HTTP/custom)
- Per-Transporter config
- Log level threshold per Transporter
- Fully async, awaitable logging
- Easy extension via abstract base class

---

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

---

## Main Config Options

### ConsoleTransport
- `format`: Message template
- `colorize`: Enable color output

### HttpTransport
- `headers`: Additional HTTP headers
- `proxy`: Proxy setting
- `timeout`: Timeout (ms)

---

## How to Extend

- Inherit from the `Transport` abstract class and implement `emitLog`
- Add your Transporter to the logger via `addTransport`

---

## Testing

- Run
```
flutter test
```
in this package to verify logger and Transporters.
