import 'package:flutter/material.dart';
import 'package:revere/core.dart';
import 'package:revere/pretty_console_transport.dart';
import 'package:revere_flutter_extension/flutter_error_tracker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Error tracking only (example):
  final tracker = AppErrorTracker();
  tracker.setupFlutterErrorTracking();
  runApp(const MyApp());
}

class AppErrorTracker with ErrorTrackerMixin {
  @override
  Logger get logger => MyApp.logger;
}

class MyApp extends StatelessWidget {
  static final Logger logger = Logger([PrettyConsoleTransport()]);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revere Flutter Extension Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revere Flutter Extension Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hello, world!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Intentionally throw an error
                throw Exception('This is a test error from HomeScreen!');
              },
              child: const Text('Throw Error'),
            ),
          ],
        ),
      ),
    );
  }
}

// (Removed dangling widget/metrics code)
