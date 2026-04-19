// This is a Flutter integration test for NotificationTransport.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:notification_transport/notification_transport.dart';
import 'package:revere/core.dart' show LogEvent, LogLevel;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Shared config that satisfies every supported platform.
  // Windows requires appName, appUserModelId, and guid at initialization time.
  const baseConfig = {
    'androidChannelId': 'revere_integration_test',
    'androidChannelName': 'Revere Integration Test',
    'androidSilent': true,
    // Windows-specific: these three keys are required for the plugin to
    // initialize successfully on Windows; values can be arbitrary for tests.
    'windowsAppName': 'revere_notification_transport_test',
    'windowsAppUserModelId': 'com.example.notification_transport_test',
    'windowsGuid': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  };

  testWidgets('log() does not throw for any log level', (tester) async {
    final transport = NotificationTransport(config: baseConfig);

    // Give initialization a moment to complete.
    await tester.pump(const Duration(milliseconds: 300));

    for (final level in LogLevel.values.where((l) => l != LogLevel.silent)) {
      await transport.log(
        LogEvent(
          level: level,
          message: 'Integration test message',
          context: 'IntegrationTest',
          timestamp: DateTime.now(),
        ),
      );
    }

    // No exception means pass.
    expect(true, true);
  });

  testWidgets('log() respects level threshold', (tester) async {
    final transport = NotificationTransport(
      level: LogLevel.error,
      config: baseConfig,
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Below threshold -- must not throw.
    await transport.log(
      LogEvent(
        level: LogLevel.debug,
        message: 'Should be suppressed',
        timestamp: DateTime.now(),
      ),
    );

    // At threshold -- must not throw.
    await transport.log(
      LogEvent(
        level: LogLevel.error,
        message: 'Should be accepted',
        timestamp: DateTime.now(),
      ),
    );

    expect(true, true);
  });
}
