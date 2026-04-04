import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:swift_log_transport/swift_log_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('swift_log_transport');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('SwiftLogTransport can be instantiated with defaults', () {
    final transport = SwiftLogTransport();
    expect(transport, isA<SwiftLogTransport>());
  });

  test('SwiftLogTransport can be instantiated with config', () {
    final transport = SwiftLogTransport(config: {'custom': 'value'});
    expect(transport.config['custom'], 'value');
  });

  test('SwiftLogTransport log does not throw (default level)', () async {
    final transport = SwiftLogTransport();
    final event = LogEvent(
      level: LogLevel.info,
      message: 'Test message',
      context: 'TestLogger',
      timestamp: DateTime.now(),
    );
    await transport.log(event);
  });

  test('SwiftLogTransport log does not throw (custom config)', () async {
    final transport = SwiftLogTransport(config: {'label': 'CustomLabel'});
    final event = LogEvent(
      level: LogLevel.warn,
      message: 'Config test',
      context: 'TestLogger',
      timestamp: DateTime.now(),
    );
    await transport.log(event);
  });
}
