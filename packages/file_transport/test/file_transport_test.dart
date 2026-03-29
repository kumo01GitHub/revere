import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_transport/file_transport.dart';
import 'package:revere/core.dart';

void main() {
  group('FileTransport', () {
    late String tempFile;
    setUp(() {
      tempFile =
          '${Directory.systemTemp.path}/file_transport_test_${DateTime.now().millisecondsSinceEpoch}.log';
    });
    tearDown(() async {
      final file = File(tempFile);
      if (await file.exists()) {
        await file.delete();
      }
    });
    test('writes log to file', () async {
      final transport = FileTransport(tempFile);
      final event = LogEvent(level: LogLevel.info, message: 'test message');
      await transport.log(event);
      final file = File(tempFile);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('test message'));
    });
    test('respects log level', () async {
      final transport = FileTransport(tempFile, level: LogLevel.error);
      final event = LogEvent(level: LogLevel.info, message: 'should not log');
      await transport.log(event);
      final file = File(tempFile);
      final exists = await file.exists();
      if (exists) {
        final content = await file.readAsString();
        expect(content.trim(), isEmpty);
      } else {
        expect(exists, isFalse);
      }
    });
    test('can use config for filePath', () async {
      final transport = FileTransport(null, config: {'filePath': tempFile});
      final event = LogEvent(level: LogLevel.info, message: 'config path');
      await transport.log(event);
      final file = File(tempFile);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('config path'));
    });
  });
}
