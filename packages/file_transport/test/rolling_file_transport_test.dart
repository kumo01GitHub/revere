import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_transport/rolling_file.dart';
import 'package:revere/core.dart';

void main() {
  group('RollingFileTransport', () {
    late String tempFile;
    setUp(() {
      tempFile =
          '${Directory.systemTemp.path}/rolling_file_test_${DateTime.now().millisecondsSinceEpoch}.log';
      // Clean up any old files
      for (int i = 0; i < 3; i++) {
        final f = File('$tempFile.$i');
        if (f.existsSync()) f.deleteSync();
      }
    });
    tearDown(() async {
      final file = File(tempFile);
      if (await file.exists()) {
        await file.delete();
      }
      for (int i = 0; i < 3; i++) {
        final f = File('$tempFile.$i');
        if (await f.exists()) await f.delete();
      }
    });
    test('rolls files when maxBytes exceeded', () async {
      final transport =
          RollingFileTransport(tempFile, maxBytes: 50, maxFiles: 3);
      for (int i = 0; i < 10; i++) {
        await transport.log(LogEvent(level: LogLevel.info, message: 'msg $i'));
      }
      // At least .0 or .1 should exist
      final rolled = File('$tempFile.0');
      expect(await rolled.exists(), isTrue);
      final mainFile = File(tempFile);
      expect(await mainFile.exists(), isTrue);
    });
    test('can use config for filePath/maxBytes/maxFiles', () async {
      final transport = RollingFileTransport(null, config: {
        'filePath': tempFile,
        'maxBytes': 40,
        'maxFiles': 2,
      });
      for (int i = 0; i < 6; i++) {
        await transport.log(LogEvent(level: LogLevel.info, message: 'log $i'));
      }
      final rolled = File('$tempFile.0');
      expect(await rolled.exists(), isTrue);
      final mainFile = File(tempFile);
      expect(await mainFile.exists(), isTrue);
    });
  });
}
