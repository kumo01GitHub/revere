import 'package:flutter/material.dart';
import 'package:notification_transport/notification_transport.dart';
import 'package:revere/core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _logStatus = 'Not logged yet';
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final Logger _logger;

  @override
  void initState() {
    super.initState();
    _logger = Logger();
    _logger.addTransport(
      NotificationTransport(
        plugin: _plugin,
        config: {
          'androidChannelId': 'revere_example',
          'androidChannelName': 'Revere Example',
          'androidChannelDescription': 'Log notifications from the example app',
          'groupKey': 'revere_example_group',
          'darwinThreadIdentifier': 'revere_example',
          'linuxDefaultActionName': 'Open',
        },
      ),
    );
  }

  Future<void> _sendLog(LogLevel level) async {
    try {
      await _logger.log(
        level,
        'Hello from NotificationTransport! (level: ${level.name})',
        context: 'ExampleApp',
      );
      if (!mounted) return;
      setState(() => _logStatus = 'Log sent: ${level.name}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _logStatus = 'Log failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('NotificationTransport Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_logStatus),
              const SizedBox(height: 16),
              for (final level in LogLevel.values.where(
                (l) => l != LogLevel.silent,
              ))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () => _sendLog(level),
                    child: Text('Send ${level.name} log'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
