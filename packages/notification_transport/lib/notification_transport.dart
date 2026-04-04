import 'package:flutter/foundation.dart';
import 'package:revere/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Transport that sends logs to mobile push notifications and PC notification center.
///
/// Supports per-level importance/priority, BigText style for long messages,
/// notification grouping, and tap callbacks.
///
/// When [plugin] is provided it is used as-is (assumed already initialized).
/// When omitted, a new [FlutterLocalNotificationsPlugin] is created and
/// initialized automatically using [InitializationSettings] built from [config].
class NotificationTransport extends Transport {
  final FlutterLocalNotificationsPlugin _plugin;
  final String format;
  final String title;
  final String? _groupKey;
  final DidReceiveNotificationResponseCallback? onNotificationResponse;

  NotificationTransport({
    super.level,
    super.config,
    FlutterLocalNotificationsPlugin? plugin,
    this.onNotificationResponse,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       format = (config['format'] as String?) ?? '[{level}] {message}',
       title = (config['title'] as String?) ?? '[{level}] {context}',
       _groupKey = config['groupKey'] as String? {
    if (plugin == null) initialize();
  }

  @protected
  Future<void> initialize() async {
    final androidIcon =
        (config['androidIcon'] as String?) ?? '@mipmap/ic_launcher';
    final linuxDefaultActionName =
        (config['linuxDefaultActionName'] as String?) ?? 'Open';
    await _plugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        iOS: const DarwinInitializationSettings(),
        macOS: const DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(
          defaultActionName: linuxDefaultActionName,
        ),
      ),
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
  }

  static (Importance, Priority) _importanceForLevel(LogLevel level) {
    return switch (level) {
      LogLevel.trace || LogLevel.debug => (Importance.low, Priority.low),
      LogLevel.info => (Importance.defaultImportance, Priority.defaultPriority),
      LogLevel.warn => (Importance.high, Priority.high),
      LogLevel.error || LogLevel.fatal => (Importance.max, Priority.max),
    };
  }

  NotificationDetails _buildEventNotificationDetails(
    LogEvent event,
    String body,
  ) {
    final (importance, priority) = _importanceForLevel(event.level);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        (config['androidChannelId'] as String?) ?? 'revere_logs',
        (config['androidChannelName'] as String?) ?? 'Revere Logs',
        channelDescription:
            (config['androidChannelDescription'] as String?) ??
            'Log notifications',
        importance: importance,
        priority: priority,
        ticker: event.level.name,
        styleInformation: BigTextStyleInformation(body),
        groupKey: _groupKey,
        autoCancel: (config['androidAutoCancel'] as bool?) ?? true,
        ongoing: (config['androidOngoing'] as bool?) ?? false,
        silent: (config['androidSilent'] as bool?) ?? false,
        playSound: (config['androidPlaySound'] as bool?) ?? true,
        enableVibration: (config['androidEnableVibration'] as bool?) ?? true,
        setAsGroupSummary: (config['androidGroupSummary'] as bool?) ?? false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: config['darwinPresentAlert'] as bool?,
        presentBadge: config['darwinPresentBadge'] as bool?,
        presentSound: config['darwinPresentSound'] as bool?,
        presentBanner: config['darwinPresentBanner'] as bool?,
        badgeNumber: config['darwinBadgeNumber'] as int?,
        subtitle: config['darwinSubtitle'] as String?,
        threadIdentifier: config['darwinThreadIdentifier'] as String?,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: config['darwinPresentAlert'] as bool?,
        presentBadge: config['darwinPresentBadge'] as bool?,
        presentSound: config['darwinPresentSound'] as bool?,
        presentBanner: config['darwinPresentBanner'] as bool?,
        badgeNumber: config['darwinBadgeNumber'] as int?,
        subtitle: config['darwinSubtitle'] as String?,
        threadIdentifier: config['darwinThreadIdentifier'] as String?,
      ),
      linux: LinuxNotificationDetails(
        defaultActionName:
            (config['linuxDefaultActionName'] as String?) ?? 'Open',
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
    // Use & 0x7FFFFFFF to keep the ID within Android's 32-bit int range.
    final id = event.timestamp.millisecondsSinceEpoch & 0x7FFFFFFF;
    final details = _buildEventNotificationDetails(event, body);
    await dispatchShow(id, resolvedTitle, body, details);
  }

  @protected
  Future<void> dispatchShow(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails,
  ) async {
    await _plugin.show(id, title, body, notificationDetails);
  }
}
