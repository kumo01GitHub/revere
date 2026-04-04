import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:android_log_transport/android_log_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('android_log_transport');

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

  test('AndroidLogTransport can be instantiated with defaults', () {
    final transport = AndroidLogTransport();
    expect(transport, isA<AndroidLogTransport>());
  });

  test('AndroidLogTransport can be instantiated with config', () {
    final transport = AndroidLogTransport(config: {'custom': 'value'});
    expect(transport.config['custom'], 'value');
  });

  test('AndroidLogTransport log does not throw (default level)', () async {
    final transport = AndroidLogTransport();
    final event = LogEvent(
      level: LogLevel.info,
      message: 'Test message',
      context: 'TestLogger',
      timestamp: DateTime.now(),
    );
    await transport.log(event);
  });

  test('AndroidLogTransport log does not throw (custom config)', () async {
    final transport = AndroidLogTransport(config: {'tag': 'CustomTag'});
    final event = LogEvent(
      level: LogLevel.warn,
      message: 'Config test',
      context: 'TestLogger',
      timestamp: DateTime.now(),
    );
    await transport.log(event);
  });
}
