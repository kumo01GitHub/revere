import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_log_transport/swift_log_transport_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSwiftLogTransport platform = MethodChannelSwiftLogTransport();
  const MethodChannel channel = MethodChannel('swift_log_transport');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('log() calls method channel', () async {
    final testEvent = {
      'level': 'info',
      'message': 'test',
      'loggerName': 'test',
      'timestamp': DateTime.now().toIso8601String()
    };
    bool called = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      expect(methodCall.method, 'log');
      expect(methodCall.arguments, testEvent);
      called = true;
      return null;
    });
    await platform.log(testEvent);
    expect(called, isTrue);
  });
}
