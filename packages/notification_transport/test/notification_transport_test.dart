import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:notification_transport/notification_transport.dart';

class _FakeNotificationTransport extends NotificationTransport {
  int initializeCalls = 0;
  final List<(int, String, String, NotificationDetails)> calls = [];

  _FakeNotificationTransport({super.level, super.config, super.plugin});

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> dispatchShow(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails,
  ) async {
    calls.add((id, title, body, notificationDetails));
  }
}

void main() {
  group('NotificationTransport', () {
    test('calls dispatchShow with formatted body and title', () async {
      final transport = _FakeNotificationTransport();

      await transport.emitLog(
        LogEvent(
          level: LogLevel.info,
          message: 'hello',
          context: 'auth',
          timestamp: DateTime.parse('2024-01-01T00:00:00.000Z'),
        ),
      );

      expect(transport.calls, hasLength(1));
      final (_, title, body, _) = transport.calls.first;
      expect(title, '[info] auth');
      expect(body, '[info] hello');
    });

    test('uses custom format and title templates', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{level}: {message}', 'title': 'App [{level}]'},
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.warn, message: 'watch out', context: 'app'),
      );

      final (_, title, body, _) = transport.calls.first;
      expect(title, 'App [warn]');
      expect(body, 'warn: watch out');
    });

    test('includes error in body when present', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{message} ({error})'},
      );

      final error = Exception('oops');
      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'failed', error: error),
      );

      final (_, _, body, _) = transport.calls.first;
      expect(body, 'failed (${error.toString()})');
    });

    test('includes stackTrace in body when format uses {stackTrace}', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{message}|{stackTrace}'},
      );

      final trace = StackTrace.fromString('frame0\nframe1');
      await transport.emitLog(
        LogEvent(level: LogLevel.error, message: 'crash', stackTrace: trace),
      );

      final (_, _, body, _) = transport.calls.first;
      expect(body, 'crash|${trace.toString()}');
    });

    test('{stackTrace} replaced with empty string when null', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{message}|{stackTrace}'},
      );

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));

      final (_, _, body, _) = transport.calls.first;
      expect(body, 'ok|');
    });

    test('{error} replaced with empty string when null', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{message}|{error}'},
      );

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'ok'));

      final (_, _, body, _) = transport.calls.first;
      expect(body, 'ok|');
    });

    test('{context} placeholder in body format is replaced', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '[{context}] {message}'},
      );

      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'ping', context: 'auth'),
      );

      final (_, _, body, _) = transport.calls.first;
      expect(body, '[auth] ping');
    });

    test('null context replaced with empty string in body and title', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '[{context}] {message}'},
      );

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'ping'));

      final (_, title, body, _) = transport.calls.first;
      expect(body, '[] ping');
      // Default title template is "[{level}] {context}"; context is empty.
      expect(title, '[info] ');
    });

    test('includes timestamp in body when format uses {timestamp}', () async {
      final transport = _FakeNotificationTransport(
        config: {'format': '{timestamp} {message}'},
      );
      final ts = DateTime.parse('2024-06-01T12:00:00.000Z');

      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'ping', timestamp: ts),
      );

      final (_, _, body, _) = transport.calls.first;
      expect(body, '${ts.toIso8601String()} ping');
    });

    test('notification id stays within 32-bit int range', () async {
      final transport = _FakeNotificationTransport();
      final ts = DateTime.parse('2024-01-01T00:00:00.000Z');

      await transport.emitLog(
        LogEvent(level: LogLevel.info, message: 'msg', timestamp: ts),
      );

      final (id, _, _, _) = transport.calls.first;
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('does not call dispatchShow below threshold', () async {
      final transport = _FakeNotificationTransport(level: LogLevel.error);

      await transport.log(LogEvent(level: LogLevel.info, message: 'ignored'));

      expect(transport.calls, isEmpty);
    });

    test('calls dispatchShow at or above threshold', () async {
      final transport = _FakeNotificationTransport(level: LogLevel.warn);

      await transport.log(LogEvent(level: LogLevel.warn, message: 'warn'));
      await transport.log(LogEvent(level: LogLevel.error, message: 'error'));

      expect(transport.calls, hasLength(2));
    });

    test(
      'uses configured android channel id and name in notificationDetails',
      () async {
        final transport = _FakeNotificationTransport(
          config: {
            'androidChannelId': 'my_channel',
            'androidChannelName': 'My Channel',
          },
        );

        await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));

        final (_, _, _, details) = transport.calls.first;
        final android = details.android!;
        expect(android.channelId, 'my_channel');
        expect(android.channelName, 'My Channel');
      },
    );

    test('androidChannelId defaults to revere_logs', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.channelId, 'revere_logs');
    });

    test('androidChannelName defaults to Revere Logs', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.channelName, 'Revere Logs');
    });

    test('androidChannelDescription defaults to Log notifications', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(
        transport.calls.first.$4.android!.channelDescription,
        'Log notifications',
      );
    });

    test('androidChannelDescription can be customised', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidChannelDescription': 'App debug logs'},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(
        transport.calls.first.$4.android!.channelDescription,
        'App debug logs',
      );
    });

    test('trace/debug use low importance and priority', () async {
      final transport = _FakeNotificationTransport();

      for (final level in [LogLevel.trace, LogLevel.debug]) {
        transport.calls.clear();
        await transport.emitLog(LogEvent(level: level, message: 'msg'));
        final android = transport.calls.first.$4.android!;
        expect(android.importance, Importance.low, reason: '$level');
        expect(android.priority, Priority.low, reason: '$level');
      }
    });

    test('info uses default importance and priority', () async {
      final transport = _FakeNotificationTransport();

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));

      final android = transport.calls.first.$4.android!;
      expect(android.importance, Importance.defaultImportance);
      expect(android.priority, Priority.defaultPriority);
    });

    test('warn uses high importance and priority', () async {
      final transport = _FakeNotificationTransport();

      await transport.emitLog(LogEvent(level: LogLevel.warn, message: 'msg'));

      final android = transport.calls.first.$4.android!;
      expect(android.importance, Importance.high);
      expect(android.priority, Priority.high);
    });

    test('error/fatal use max importance and priority', () async {
      final transport = _FakeNotificationTransport();

      for (final level in [LogLevel.error, LogLevel.fatal]) {
        transport.calls.clear();
        await transport.emitLog(LogEvent(level: level, message: 'msg'));
        final android = transport.calls.first.$4.android!;
        expect(android.importance, Importance.max, reason: '$level');
        expect(android.priority, Priority.max, reason: '$level');
      }
    });

    test('android ticker uses log level name', () async {
      final transport = _FakeNotificationTransport();

      await transport.emitLog(LogEvent(level: LogLevel.warn, message: 'msg'));

      final android = transport.calls.first.$4.android!;
      expect(android.ticker, 'warn');
    });

    test(
      'android styleInformation is BigTextStyleInformation with body',
      () async {
        final transport = _FakeNotificationTransport(
          config: {'format': '{level}: {message}'},
        );

        await transport.emitLog(
          LogEvent(level: LogLevel.error, message: 'something went wrong'),
        );

        final android = transport.calls.first.$4.android!;
        expect(android.styleInformation, isA<BigTextStyleInformation>());
        final style = android.styleInformation as BigTextStyleInformation;
        expect(style.bigText, 'error: something went wrong');
      },
    );

    test('groupKey is passed to android notification details', () async {
      final transport = _FakeNotificationTransport(
        config: {'groupKey': 'revere_group'},
      );

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));

      final android = transport.calls.first.$4.android!;
      expect(android.groupKey, 'revere_group');
    });

    test('groupKey defaults to null when not configured', () async {
      final transport = _FakeNotificationTransport();

      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));

      final android = transport.calls.first.$4.android!;
      expect(android.groupKey, isNull);
    });

    // --- plugin / initialize behavior ---

    test('calls initialize() once when plugin is not provided', () {
      final transport = _FakeNotificationTransport();
      expect(transport.initializeCalls, 1);
    });

    test('skips initialize() when plugin is provided externally', () {
      final plugin = FlutterLocalNotificationsPlugin();
      final transport = _FakeNotificationTransport(plugin: plugin);
      expect(transport.initializeCalls, 0);
    });

    // --- Android config ---

    test('androidAutoCancel defaults to true', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.autoCancel, isTrue);
    });

    test('androidAutoCancel can be set to false', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidAutoCancel': false},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.autoCancel, isFalse);
    });

    test('androidOngoing defaults to false', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.ongoing, isFalse);
    });

    test('androidOngoing can be set to true', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidOngoing': true},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.ongoing, isTrue);
    });

    test('androidSilent defaults to false', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.silent, isFalse);
    });

    test('androidSilent can be set to true', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidSilent': true},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.silent, isTrue);
    });

    test('androidPlaySound defaults to true', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.playSound, isTrue);
    });

    test('androidPlaySound can be set to false', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidPlaySound': false},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.playSound, isFalse);
    });

    test('androidEnableVibration defaults to true', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.enableVibration, isTrue);
    });

    test('androidEnableVibration can be set to false', () async {
      final transport = _FakeNotificationTransport(
        config: {'androidEnableVibration': false},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.enableVibration, isFalse);
    });

    test('androidGroupSummary defaults to false', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.setAsGroupSummary, isFalse);
    });

    test('androidGroupSummary can be set to true', () async {
      final transport = _FakeNotificationTransport(
        config: {'groupKey': 'g', 'androidGroupSummary': true},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.android!.setAsGroupSummary, isTrue);
    });

    // --- Darwin (iOS/macOS) config ---

    test('darwinPresentAlert is null by default', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.presentAlert, isNull);
    });

    test('darwinPresentAlert can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinPresentAlert': false},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.presentAlert, isFalse);
    });

    test('darwinPresentSound can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinPresentSound': false},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.presentSound, isFalse);
      expect(transport.calls.first.$4.macOS!.presentSound, isFalse);
    });

    test('darwinPresentBadge can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinPresentBadge': true},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.presentBadge, isTrue);
    });

    test('darwinPresentBanner can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinPresentBanner': true},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.presentBanner, isTrue);
    });

    test('darwinBadgeNumber can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinBadgeNumber': 5},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.badgeNumber, 5);
    });

    test('darwinSubtitle can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinSubtitle': 'sub'},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.subtitle, 'sub');
      expect(transport.calls.first.$4.macOS!.subtitle, 'sub');
    });

    test('darwinThreadIdentifier can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'darwinThreadIdentifier': 'thread_logs'},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.iOS!.threadIdentifier, 'thread_logs');
      expect(transport.calls.first.$4.macOS!.threadIdentifier, 'thread_logs');
    });

    // --- Linux config ---

    test('linuxDefaultActionName defaults to Open', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.linux!.defaultActionName, 'Open');
    });

    test('linuxDefaultActionName can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'linuxDefaultActionName': 'View Log'},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.linux!.defaultActionName, 'View Log');
    });

    // --- Windows config ---

    test('windows notificationDetails subtitle defaults to null', () async {
      final transport = _FakeNotificationTransport();
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.windows!.subtitle, isNull);
    });

    test('windowsSubtitle can be configured', () async {
      final transport = _FakeNotificationTransport(
        config: {'windowsSubtitle': 'system logs'},
      );
      await transport.emitLog(LogEvent(level: LogLevel.info, message: 'msg'));
      expect(transport.calls.first.$4.windows!.subtitle, 'system logs');
    });
  });
}
