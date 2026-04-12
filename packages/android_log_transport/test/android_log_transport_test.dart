import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:android_log_transport/android_log_transport.dart';

/// Fake platform that records all calls without invoking a method channel.
class _FakePlatform extends AndroidLogTransportPlatform {
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<void> log(Map<String, dynamic> event) async {
    calls.add(Map<String, dynamic>.from(event));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // setUpAll runs before any setUp — reading .instance here triggers the lazy
  // initialiser on platform_interface.dart line 16 (MethodChannelAndroidLogTransport()).
  setUpAll(() {
    expect(
      AndroidLogTransportPlatform.instance,
      isA<MethodChannelAndroidLogTransport>(),
    );
  });

  late _FakePlatform fake;

  setUp(() {
    fake = _FakePlatform();
    AndroidLogTransportPlatform.instance = fake;
  });

  group('AndroidLogTransport', () {
    // --- constructor ---

    test('can be instantiated with default config', () {
      expect(() => AndroidLogTransport(), returnsNormally);
    });

    test('tag defaults to null', () {
      expect(AndroidLogTransport().tag, isNull);
    });

    test('tag read from config', () {
      expect(AndroidLogTransport(config: {'tag': 'MyTag'}).tag, 'MyTag');
    });

    test('format defaults to {message}', () {
      expect(AndroidLogTransport().format, '{message}');
    });

    test('format read from config', () {
      expect(
        AndroidLogTransport(config: {'format': '[{level}] {message}'}).format,
        '[{level}] {message}',
      );
    });

    // --- level threshold ---

    test('does not forward event below threshold', () async {
      final t = AndroidLogTransport(level: LogLevel.error);
      await t.log(LogEvent(level: LogLevel.info, message: 'nope'));
      expect(fake.calls, isEmpty);
    });

    test('forwards event at threshold level', () async {
      final t = AndroidLogTransport(level: LogLevel.warn);
      await t.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      expect(fake.calls, hasLength(1));
    });

    test('forwards event above threshold level', () async {
      final t = AndroidLogTransport(level: LogLevel.info);
      await t.log(LogEvent(level: LogLevel.error, message: 'err'));
      expect(fake.calls, hasLength(1));
    });

    // --- payload fields ---

    test('level field matches event level name', () async {
      final t = AndroidLogTransport();
      for (final level in LogLevel.values) {
        fake.calls.clear();
        await t.emitLog(LogEvent(level: level, message: 'msg'));
        expect(fake.calls.first['level'], level.name, reason: '$level');
      }
    });

    test('timestamp field is ISO-8601', () async {
      final ts = DateTime.parse('2024-06-01T00:00:00.000Z');
      final t = AndroidLogTransport();
      await t.emitLog(
          LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts));
      expect(fake.calls.first['timestamp'], ts.toIso8601String());
    });

    test('context field matches event context', () async {
      final t = AndroidLogTransport();
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', context: 'AuthService'),
      );
      expect(fake.calls.first['context'], 'AuthService');
    });

    test('context field is null when not provided', () async {
      final t = AndroidLogTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(fake.calls.first['context'], isNull);
    });

    test('tag field matches configured tag', () async {
      final t = AndroidLogTransport(config: {'tag': 'AppTag'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(fake.calls.first['tag'], 'AppTag');
    });

    test('tag field is null when not configured', () async {
      final t = AndroidLogTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(fake.calls.first['tag'], isNull);
    });

    test('error field contains exception string when present', () async {
      final t = AndroidLogTransport();
      final err = Exception('disk full');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'write failed', error: err),
      );
      expect(fake.calls.first['error'], err.toString());
    });

    test('error field is null when not provided', () async {
      final t = AndroidLogTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(fake.calls.first['error'], isNull);
    });

    test('stackTrace field contains string when present', () async {
      final t = AndroidLogTransport();
      final trace = StackTrace.fromString('#0 main (file.dart:1:1)');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(fake.calls.first['stackTrace'], trace.toString());
    });

    test('stackTrace field is null when not provided', () async {
      final t = AndroidLogTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(fake.calls.first['stackTrace'], isNull);
    });

    // --- message format ---

    test('default format sends raw message', () async {
      final t = AndroidLogTransport();
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'hello'));
      expect(fake.calls.first['message'], 'hello');
    });

    test('format replaces {level}', () async {
      final t = AndroidLogTransport(config: {'format': '[{level}] {message}'});
      await t.emitLog(LogEvent(level: LogLevel.warn, message: 'bad'));
      expect(fake.calls.first['message'], '[warn] bad');
    });

    test('format replaces {context}', () async {
      final t = AndroidLogTransport(config: {'format': '{context}: {message}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'ping', context: 'auth'),
      );
      expect(fake.calls.first['message'], 'auth: ping');
    });

    test('null context in format replaced with empty string', () async {
      final t = AndroidLogTransport(config: {'format': '{context}: {message}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ping'));
      expect(fake.calls.first['message'], ': ping');
    });

    test('format replaces {timestamp}', () async {
      final ts = DateTime.parse('2024-01-01T00:00:00.000Z');
      final t = AndroidLogTransport(config: {'format': '{timestamp}'});
      await t.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );
      expect(fake.calls.first['message'], ts.toIso8601String());
    });

    test('format replaces {error} when present', () async {
      final t = AndroidLogTransport(config: {'format': '{message} ({error})'});
      final err = Exception('oops');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'fail', error: err),
      );
      expect(fake.calls.first['message'], 'fail (${err.toString()})');
    });

    test('format replaces {error} with empty string when null', () async {
      final t = AndroidLogTransport(config: {'format': '{message}|{error}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(fake.calls.first['message'], 'ok|');
    });

    test('format replaces {stackTrace} when present', () async {
      final t =
          AndroidLogTransport(config: {'format': '{message}|{stackTrace}'});
      final trace = StackTrace.fromString('frame0');
      await t.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );
      expect(fake.calls.first['message'], 'crash|${trace.toString()}');
    });

    test('format replaces {stackTrace} with empty string when null', () async {
      final t =
          AndroidLogTransport(config: {'format': '{message}|{stackTrace}'});
      await t.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));
      expect(fake.calls.first['message'], 'ok|');
    });
  });
}
