import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:revere/core.dart';
import 'package:notification_transport/notification_transport.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall methodCall) async {
          if (methodCall.method == 'initialize') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

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
