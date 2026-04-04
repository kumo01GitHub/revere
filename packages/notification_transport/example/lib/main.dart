import 'package:flutter/material.dart';
import 'package:notification_transport/notification_transport.dart';
import 'package:revere/core.dart' show LogEvent, LogLevel;

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
  final _transport = NotificationTransport(
    config: {
      'androidChannelId': 'revere_example',
      'androidChannelName': 'Revere Example',
      'androidChannelDescription': 'Log notifications from the example app',
      'groupKey': 'revere_example_group',
      'darwinThreadIdentifier': 'revere_example',
      'linuxDefaultActionName': 'Open',
    },
  );

  Future<void> _sendLog(LogLevel level) async {
    try {
      final event = LogEvent(
        level: level,
        message: 'Hello from NotificationTransport! (level: ${level.name})',
        context: 'ExampleApp',
        timestamp: DateTime.now(),
      );
      await _transport.log(event);
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
        appBar: AppBar(
          title: const Text('NotificationTransport Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_logStatus),
              const SizedBox(height: 16),
              for (final level in LogLevel.values)
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
