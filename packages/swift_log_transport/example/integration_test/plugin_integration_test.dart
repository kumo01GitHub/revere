// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:swift_log_transport/swift_log_transport.dart';
import 'package:revere/core.dart' show LogEvent, LogLevel;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('log() does not throw', (WidgetTester tester) async {
    final SwiftLogTransport plugin = SwiftLogTransport();
    final event = LogEvent(
      level: LogLevel.info,
      message: 'Integration test message',
      context: 'IntegrationTest',
      timestamp: DateTime.now(),
    );
    await plugin.log(event);
    // No exception means pass
    expect(true, true);
  });
}
