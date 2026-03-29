import 'package:flutter_test/flutter_test.dart';

import 'package:revere/core.dart';
import 'package:notification_transport/notification_transport.dart';

void main() {
  test('NotificationTransport emits log', () async {
    final transport = NotificationTransport();
    final event = LogEvent(
      level: LogLevel.info,
      message: 'Test notification',
      timestamp: DateTime.now(),
    );
    // This will show a notification if run in a supported environment.
    await transport.emitLog(event);
    // No assertion: just ensure no error thrown.
  });
}
