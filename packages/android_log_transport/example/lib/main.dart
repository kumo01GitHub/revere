import 'package:flutter/material.dart';
import 'dart:async';

import 'package:android_log_transport/android_log_transport.dart';
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
  final _androidLogTransport = AndroidLogTransport();

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> logSample() async {
    try {
      final event = LogEvent(
        level: LogLevel.info,
        message: 'Hello from AndroidLogTransport!',
        context: 'ExampleApp',
        timestamp: DateTime.now(),
      );
      await _androidLogTransport.log(event);
      if (!mounted) return;
      setState(() {
        _logStatus = 'Log sent successfully!';
      });
    } catch (e) {
      setState(() {
        _logStatus = 'Log failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AndroidLogTransport Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_logStatus),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: logSample,
                child: const Text('Send Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
