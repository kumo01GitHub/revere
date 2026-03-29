import 'package:revere/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Transport that sends logs to mobile push notifications and PC notification center.
class NotificationTransport extends Transport {
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationDetails notificationDetails;
  final String format;
  final String title;

  NotificationTransport({
    super.level,
    super.config,
    FlutterLocalNotificationsPlugin? plugin,
  })  : format = (config['format'] as String?) ?? '[{level}] {message}',
        title = (config['title'] as String?) ?? '[{level}] {context}',
        _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            config['androidChannelId'] ?? 'revere_logs',
            config['androidChannelName'] ?? 'Revere Logs',
            channelDescription: config['androidChannelDescription'] ?? 'Log notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
          linux: const LinuxNotificationDetails(),
          windows: const WindowsNotificationDetails(),
        ) {
    _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: config['winAppName'] ?? 'Revere Logs',
          appUserModelId: config['winAppUserModelId'] ?? 'app.kumo01.revere',
          guid: config['winGuid'] ?? ''),
      ),
    );
  }

  @override
  Future<void> emitLog(LogEvent event) async {
    final String body = format
        .replaceAll('{level}', event.level.name)
        .replaceAll('{message}', event.message)
        .replaceAll('{timestamp}', event.timestamp.toIso8601String())
        .replaceAll('{error}', event.error?.toString() ?? '')
        .replaceAll('{stackTrace}', event.stackTrace?.toString() ?? '')
        .replaceAll('{context}', event.context ?? '');
    final resolvedTitle = title
        .replaceAll('{level}', event.level.name)
        .replaceAll('{context}', event.context ?? '');
    await _plugin.show(
      event.timestamp.millisecondsSinceEpoch ~/ 1000,
      resolvedTitle,
      body,
      notificationDetails,
    );
  }
}
