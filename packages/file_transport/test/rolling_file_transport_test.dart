import 'dart:io';
import 'package:test/test.dart';
import 'package:file_transport/rolling_file.dart';
import 'package:revere/core.dart';

String _tempPath() =>
    '${Directory.systemTemp.path}/rft_${DateTime.now().microsecondsSinceEpoch}.log';

Future<void> _cleanAll(String base, int n) async {
  for (final f in [File(base), ...List.generate(n, (i) => File('$base.$i'))]) {
    if (await f.exists()) await f.delete();
  }
}

void main() {
  group('RollingFileTransport', () {
    late String path;

    setUp(() => path = _tempPath());
    tearDown(() => _cleanAll(path, 5));

    // --- constructor ---

    test('accepts filePath as positional argument', () {
      expect(() => RollingFileTransport(path), returnsNormally);
    });

    test('accepts config-based filePath/maxBytes/maxFiles', () {
      expect(
        () => RollingFileTransport(null, config: {
          'filePath': path,
          'maxBytes': 512,
          'maxFiles': 3,
        }),
        returnsNormally,
      );
    });

    test('throws ArgumentError when filePath is not provided', () {
      expect(() => RollingFileTransport(null), throwsArgumentError);
    });

    test('throws ArgumentError when filePath is empty string', () {
      expect(() => RollingFileTransport(''), throwsArgumentError);
    });

    // --- level threshold ---

    test('does not write below threshold', () async {
      final t = RollingFileTransport(path, level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.debug, message: 'nope'));
      expect(await File(path).exists(), isFalse);
    });

    test('writes at and above threshold', () async {
      final t = RollingFileTransport(path, level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await t.log(LogEvent(level: LogLevel.error, message: 'error'));
      final content = await File(path).readAsString();
      expect(content, contains('warn'));
      expect(content, contains('error'));
    });

    // --- log format ---

    test('line contains ISO-8601 timestamp', () async {
      final ts = DateTime.parse('2024-03-01T12:00:00.000Z');
      final t = RollingFileTransport(path);
      await t.emitLog(
          LogEvent(level: LogLevel.info, message: 'ts', timestamp: ts));
      expect(await File(path).readAsString(), contains(ts.toIso8601String()));
    });

    test('line contains level name', () async {
      final t = RollingFileTransport(path);
      await t.emitLog(LogEvent(level: LogLevel.warn, message: 'msg'));
      expect(await File(path).readAsString(), contains('[warn]'));
    });

    test('line contains message', () async {
      final t = RollingFileTransport(path);
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'hello'));
      expect(await File(path).readAsString(), contains('hello'));
    });

    test('line contains context when provided', () async {
      final t = RollingFileTransport(path);
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'MyCtx'),
      );
      expect(await File(path).readAsString(), contains('[MyCtx]'));
    });

    test('line contains error when provided', () async {
      final t = RollingFileTransport(path);
      final err = Exception('boom');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', error: err),
      );
      expect(await File(path).readAsString(), contains('boom'));
    });

    test('line contains stackTrace when provided', () async {
      final t = RollingFileTransport(path);
      final trace = StackTrace.fromString('#0 foo (foo.dart:1:1)');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(await File(path).readAsString(), contains('#0 foo'));
    });

    // --- rolling behaviour ---

    test('file exists after first write', () async {
      final t = RollingFileTransport(path, maxBytes: 1024);
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'first'));
      expect(await File(path).exists(), isTrue);
    });

    test('creates .0 archive when maxBytes exceeded', () async {
      final t = RollingFileTransport(path, maxBytes: 10);
      await t.emitLog(
          LogEvent(level: LogLevel.info, message: 'first line that is long'));
      await t.emitLog(
          LogEvent(level: LogLevel.info, message: 'second line that is long'));
      expect(await File('$path.0').exists(), isTrue);
    });

    test('active file stays under maxBytes after roll', () async {
      const max = 50;
      final t = RollingFileTransport(path, maxBytes: max);
      for (var i = 0; i < 10; i++) {
        await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg $i'));
      }
      final size = await File(path).length();
      expect(size, lessThanOrEqualTo(max + 120)); // one freshly written line
    });

    test('oldest archive deleted when maxFiles exceeded', () async {
      final t = RollingFileTransport(path, maxBytes: 20, maxFiles: 2);
      // Write enough to roll more than maxFiles times
      for (var i = 0; i < 20; i++) {
        await t.emitLog(LogEvent(level: LogLevel.info, message: 'x' * 10));
      }
      // The index beyond maxFiles-1 should not exist
      expect(await File('$path.2').exists(), isFalse);
    });

    test('multiple rolls produce ordered archives', () async {
      final t = RollingFileTransport(path, maxBytes: 30, maxFiles: 3);
      for (var i = 0; i < 15; i++) {
        await t.emitLog(LogEvent(level: LogLevel.info, message: 'roll $i'));
      }
      // .0 should exist (most recent archived)
      expect(await File('$path.0').exists(), isTrue);
    });

    // --- config-path shortcut ---

    test('config maxBytes and maxFiles are respected', () async {
      final t = RollingFileTransport(
        null,
        config: {'filePath': path, 'maxBytes': 20, 'maxFiles': 2},
      );
      for (var i = 0; i < 10; i++) {
        await t.emitLog(LogEvent(level: LogLevel.info, message: 'y' * 10));
      }
      expect(await File(path).exists(), isTrue);
      expect(await File('$path.2').exists(), isFalse);
    });
  });

  group('RollingFile', () {
    late String path;

    setUp(() => path = _tempPath());
    tearDown(() => _cleanAll(path, 5));

    test('write creates file if absent', () async {
      final rf = RollingFile(path);
      await rf.write('hello');
      expect(await File(path).exists(), isTrue);
    });

    test('write appends multiple lines', () async {
      final rf = RollingFile(path, maxBytes: 10000);
      await rf.write('line1');
      await rf.write('line2');
      final content = await File(path).readAsString();
      expect(content, contains('line1'));
      expect(content, contains('line2'));
    });

    test('rolls to .0 when size exceeds maxBytes', () async {
      final rf = RollingFile(path, maxBytes: 10);
      await rf.write('a' * 20);
      await rf.write('b' * 20);
      expect(await File('$path.0').exists(), isTrue);
    });

    test('shifts .0 → .1 on second roll', () async {
      final rf = RollingFile(path, maxBytes: 10);
      await rf.write('a' * 20);
      await rf.write('b' * 20); // triggers first roll: current → .0
      await rf.write('c' * 20); // triggers second roll: .0 → .1, current → .0
      expect(await File('$path.1').exists(), isTrue);
    });

    test('oldest file deleted when maxFiles reached', () async {
      final rf = RollingFile(path, maxBytes: 5, maxFiles: 2);
      for (var i = 0; i < 10; i++) {
        await rf.write('x' * 10);
      }
      expect(await File('$path.2').exists(), isFalse);
    });
  });
}
