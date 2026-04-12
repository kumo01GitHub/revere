import 'package:flutter/material.dart';
import 'package:revere_debug_extension/revere_debug_extension.dart';
import 'package:revere/pretty_console_transport.dart';

import 'package:revere/core.dart';

void main() {
  final metricsLogger = MetricsLogger();
  metricsLogger.addTransport(PrettyConsoleTransport());
  final normalLogger = Logger();
  normalLogger.addTransport(PrettyConsoleTransport());
  runApp(MyApp(metricsLogger: metricsLogger, normalLogger: normalLogger));
}

class MyApp extends StatelessWidget {
  final MetricsLogger metricsLogger;
  final Logger normalLogger;
  const MyApp({
    super.key,
    required this.metricsLogger,
    required this.normalLogger,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        metricsLogger: metricsLogger,
        normalLogger: normalLogger,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final MetricsLogger metricsLogger;
  final Logger normalLogger;
  const MyHomePage({
    super.key,
    required this.title,
    required this.metricsLogger,
    required this.normalLogger,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _collecting = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleMetricsCollection() {
    setState(() {
      if (_collecting) {
        widget.metricsLogger.stop();
        widget.normalLogger.info(
          'Metrics collection stopped at ${DateTime.now()}',
        );
        _collecting = false;
      } else {
        widget.metricsLogger.start();
        widget.normalLogger.info(
          'Metrics collection started at ${DateTime.now()}',
        );
        _collecting = true;
      }
    });
  }

  @override
  void dispose() {
    if (_collecting) widget.metricsLogger.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _toggleMetricsCollection,
                  child: Text(
                    _collecting
                        ? 'Stop Metrics Collection'
                        : 'Start Metrics Collection',
                  ),
                ),
              ],
            ),
          ),
          // Place DebugWidget at the very front of the Stack
          FloatingMetricsButton(
            loggers: [widget.normalLogger, widget.metricsLogger.logger],
            tabNames: ['Normal', 'Metrics'],
          ),
        ],
      ),
    );
  }
}
