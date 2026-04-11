import 'dart:io';
import 'package:test/test.dart';
import 'package:file_transport/file_transport.dart';
import 'package:revere/core.dart';

String _tempPath() =>
    '${Directory.systemTemp.path}/ft_${DateTime.now().microsecondsSinceEpoch}.log';

Future<void> _deleteIfExists(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}

void main() {
  group('FileTransport', () {
    late String path;

    setUp(() => path = _tempPath());
    tearDown(() => _deleteIfExists(path));

    // --- constructor ---

    test('accepts filePath as positional argument', () {
      expect(() => FileTransport(path), returnsNormally);
    });

    test('accepts filePath via config map', () {
      expect(
        () => FileTransport(null, config: {'filePath': path}),
        returnsNormally,
      );
    });

    test('throws ArgumentError when filePath is not provided', () {
      expect(() => FileTransport(null), throwsArgumentError);
    });

    test('throws ArgumentError when filePath is empty string', () {
      expect(() => FileTransport(''), throwsArgumentError);
    });

    // --- level threshold ---

    test('does not write below threshold', () async {
      final transport = FileTransport(path, level: LogLevel.error);
      await transport.log(LogEvent(level: LogLevel.info, message: 'nope'));
      expect(await File(path).exists(), isFalse);
    });

    test('writes at threshold level', () async {
      final transport = FileTransport(path, level: LogLevel.warn);
      await transport.log(LogEvent(level: LogLevel.warn, message: 'yep'));
      expect(await File(path).readAsString(), contains('yep'));
    });

    test('writes above threshold level', () async {
      final transport = FileTransport(path, level: LogLevel.info);
      await transport.log(LogEvent(level: LogLevel.error, message: 'also'));
      expect(await File(path).readAsString(), contains('also'));
    });

    // --- log format ---

    test('line contains ISO-8601 timestamp', () async {
      final ts = DateTime.parse('2024-06-01T09:00:00.000Z');
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(
        await File(path).readAsString(),
        contains(ts.toIso8601String()),
      );
    });

    test('line contains level name', () async {
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.warn, message: 'msg'),
      );
      expect(await File(path).readAsString(), contains('[warn]'));
    });

    test('line contains message', () async {
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'hello world'),
      );
      expect(await File(path).readAsString(), contains('hello world'));
    });

    test('line contains context when provided', () async {
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'AuthService'),
      );
      expect(await File(path).readAsString(), contains('[AuthService]'));
    });

    test('line omits context bracket when context is null', () async {
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg'),
      );
      // Should not contain a bare context bracket
      final content = await File(path).readAsString();
      expect(content, isNot(contains('null')));
    });

    test('line contains error when provided', () async {
      final transport = FileTransport(path);
      final err = Exception('disk full');
      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'write failed', error: err),
      );
      expect(await File(path).readAsString(), contains('disk full'));
    });

    test('line contains stackTrace when provided', () async {
      final transport = FileTransport(path);
      final trace = StackTrace.fromString('#0 main (file.dart:1:1)');
      await transport.emitLog(
        LogEvent(
          level: LogLevel.error,
          message: 'crash',
          stackTrace: trace,
        ),
      );
      expect(await File(path).readAsString(), contains('#0 main'));
    });

    test('line omits error and stackTrace when absent', () async {
      final transport = FileTransport(path);
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'clean'),
      );
      final content = await File(path).readAsString();
      expect(content, isNot(contains('error:')));
      expect(content, isNot(contains('null')));
    });

    // --- append behaviour ---

    test('each log is on its own line', () async {
      final transport = FileTransport(path);
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'first'));
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'second'),
      );
      final lines = (await File(path).readAsString())
          .split('\n')
          .where((l) => l.isNotEmpty)
          .toList();
      expect(lines.length, 2);
    });

    test('multiple writes append in order', () async {
      final transport = FileTransport(path);
      for (final msg in ['a', 'b', 'c']) {
        await transport.emitLog(LogEvent(level: LogLevel.info, message: msg));
      }
      final content = await File(path).readAsString();
      final aIdx = content.indexOf('] a\n');
      final bIdx = content.indexOf('] b\n');
      final cIdx = content.indexOf('] c\n');
      expect(aIdx, lessThan(bIdx));
      expect(bIdx, lessThan(cIdx));
    });

    // --- config-path shortcut ---

    test('config filePath is used when positional arg is null', () async {
      final transport = FileTransport(null, config: {'filePath': path});
      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'via config'),
      );
      expect(await File(path).readAsString(), contains('via config'));
    });
  });
}
