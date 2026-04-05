import 'package:flutter/material.dart';
import 'package:revere/core.dart';
import 'package:revere/buffered_transport.dart';
import 'package:revere/console_transport.dart';
import 'package:revere/pretty_console_transport.dart';

// ---------------------------------------------------------------------------
// LoggerMixin example — a simple service that logs its own actions
// ---------------------------------------------------------------------------
class CounterService with LoggerMixin {
  int _count = 0;

  int get count => _count;

  Future<void> increment() async {
    _count++;
    await i('Counter incremented to $_count');
  }

  Future<void> reset() async {
    _count = 0;
    await w('Counter reset to 0');
  }

  /// Simulates a failure and logs it at error level.
  Future<void> simulateError() async {
    try {
      throw StateError('Something went wrong in CounterService');
    } catch (err, st) {
      await e('Operation failed', error: err, stackTrace: st);
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// App setup — configure the shared logger used by LoggerMixin
// ---------------------------------------------------------------------------
void main() {
  // PrettyConsoleTransport logs everything from trace upward
  LoggerMixin.logger.addTransport(
    PrettyConsoleTransport(level: LogLevel.trace),
  );

  // BufferedTransport wraps a second ConsoleTransport and flushes every 5 s
  LoggerMixin.logger.addTransport(
    ConsoleTransport(level: LogLevel.warn).withBuffer(
      maxSize: 10,
      flushInterval: const Duration(seconds: 5),
    ),
  );

  runApp(const RevereExampleApp());
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------
class RevereExampleApp extends StatelessWidget {
  const RevereExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revere Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _service = CounterService();
  String _status = 'Tap a button — watch the console for log output.';

  Future<void> _run(Future<void> Function() action, String label) async {
    try {
      await action();
      if (mounted) setState(() => _status = '$label → see console');
    } catch (_) {
      if (mounted) {
        setState(() => _status = '$label → error logged (see console)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revere Core Example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Counter: ${_service.count}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _Section(title: 'LoggerMixin', children: [
              _LogButton(
                label: 'Increment (info)',
                onPressed: () => _run(_service.increment, 'increment'),
              ),
              _LogButton(
                label: 'Reset (warn)',
                onPressed: () => _run(_service.reset, 'reset'),
              ),
              _LogButton(
                label: 'Simulate error',
                onPressed: () => _run(_service.simulateError, 'simulateError'),
              ),
            ]),
            const SizedBox(height: 24),
            _Section(title: 'Direct Logger', children: [
              _LogButton(
                label: 'logger.trace()',
                onPressed: () => _run(
                  () => LoggerMixin.logger
                      .trace('trace message', context: 'ExamplePage'),
                  'trace',
                ),
              ),
              _LogButton(
                label: 'logger.debug()',
                onPressed: () => _run(
                  () => LoggerMixin.logger
                      .debug('debug message', context: 'ExamplePage'),
                  'debug',
                ),
              ),
              _LogButton(
                label: 'logger.fatal()',
                onPressed: () => _run(
                  () => LoggerMixin.logger
                      .fatal('fatal message', context: 'ExamplePage'),
                  'fatal',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
