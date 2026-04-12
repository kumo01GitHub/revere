import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_log_transport/swift_log_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSwiftLogTransport();
  const channel = MethodChannel('swift_log_transport');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('log() invokes "log" method with the supplied event map', () async {
    final event = {
      'level': 'info',
      'message': 'test message',
      'timestamp': '2024-01-01T00:00:00.000Z',
      'context': 'TestService',
      'label': 'com.example',
      'metadata': {'env': 'test'},
      'error': null,
      'stackTrace': null,
    };

    MethodCall? captured;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });

    await platform.log(event);

    expect(captured, isNotNull);
    expect(captured!.method, 'log');
    expect(captured!.arguments, event);
  });

  test('log() completes without error on null return', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);

    await expectLater(
      platform.log({'level': 'debug', 'message': 'msg', 'timestamp': ''}),
      completes,
    );
  });
}
