import 'package:flutter/material.dart';

import 'package:revere_debug_extension/revere_debug_extension.dart';
import 'package:revere/pretty_console_transport.dart';

void main() {
  // Add StateTransport (UI) and PrettyConsoleTransport (console) to metrics logger
  final metricsTransport = StateTransport<MetricsData>(maxLength: 100);
  MetricsLogger().addTransport(metricsTransport);
  MetricsLogger().addTransport(PrettyConsoleTransport());
  runApp(MyApp(metricsTransport: metricsTransport));
}

class MyApp extends StatelessWidget {
  final StateTransport<MetricsData> metricsTransport;
  const MyApp({super.key, required this.metricsTransport});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        metricsTransport: metricsTransport,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final StateTransport<MetricsData> metricsTransport;
  const MyHomePage({
    Key? key,
    required this.title,
    required this.metricsTransport,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final StateTransport<MetricsData> _metricsTransport;

  @override
  void initState() {
    super.initState();
    _metricsTransport = widget.metricsTransport;
    MetricsLogger().start();
  }

  @override
  void dispose() {
    MetricsLogger().stop();
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
        children: [FloatingMetricsButton(transport: _metricsTransport)],
      ),
      // Remove default floatingActionButton to avoid overlap with custom metrics button
    );
  }
}
