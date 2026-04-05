import 'package:flutter/material.dart';
import 'package:revere/core.dart';
import 'package:revere/pretty_console_transport.dart';

// ===========================================================================
// Example 1: LoggerMixin
//
// Mix LoggerMixin into any class to get concise, context-aware logging.
// The class name is automatically attached as the log context.
// Override loggerContext to customise the label.
// ===========================================================================
class UserRepository with LoggerMixin {
  final _users = <String>['alice', 'bob', 'carol'];

  @override
  String get loggerContext => 'UserRepository';

  Future<List<String>> fetchAll() async {
    await d('Fetching all users');
    await Future.delayed(const Duration(milliseconds: 100));
    await i('Fetched ${_users.length} users');
    return List.unmodifiable(_users);
  }

  Future<void> addUser(String name) async {
    if (name.isEmpty) {
      await w('addUser called with empty name — skipping');
      return;
    }
    _users.add(name);
    await i('User added: $name');
  }

  Future<void> deleteUser(String name) async {
    if (!_users.contains(name)) {
      await e(
        'deleteUser: user not found: $name',
        error: ArgumentError('unknown user: $name'),
      );
      return;
    }
    _users.remove(name);
    await i('User deleted: $name');
  }
}

// ===========================================================================
// Example 2: ErrorTrackerMixin
//
// ErrorTrackerMixin adds trackError, withTracking, guarded, and
// setupFlutterErrorTracking for global Flutter/Dart error capture.
// ===========================================================================
class PaymentService with ErrorTrackerMixin {
  // Share the same logger as LoggerMixin rather than using a separate instance.
  @override
  Logger get logger => LoggerMixin.logger;

  @override
  String get trackerContext => 'PaymentService';

  /// withTracking: logs action entry at info level, records any thrown error.
  Future<void> purchase(String itemId, double price) => withTracking(
        'purchase',
        () async {
          await Future.delayed(const Duration(milliseconds: 200));
          if (price <= 0) throw ArgumentError('price must be positive');
        },
        params: {'item_id': itemId, 'price': price},
      );

  /// guarded: wraps body in try/catch; records error and re-throws.
  Future<void> refund(String orderId) => guarded(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw StateError('refund service unavailable for order $orderId');
      });

  /// trackError: records an arbitrary caught error directly.
  Future<void> reportManualError() => trackError(
        Exception('manual payment error'),
        stackTrace: StackTrace.current,
        message: 'Manually reported payment error',
      );
}

// ===========================================================================
// App entry-point
// ===========================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Single PrettyConsoleTransport — sufficient for this demo.
  LoggerMixin.logger.addTransport(
    PrettyConsoleTransport(level: LogLevel.trace),
  );

  // setupFlutterErrorTracking installs FlutterError.onError and
  // PlatformDispatcher.instance.onError so uncaught errors are automatically
  // recorded. Call this once after WidgetsFlutterBinding.ensureInitialized().
  PaymentService().setupFlutterErrorTracking();

  runApp(const RevereExampleApp());
}

// ===========================================================================
// UI
// ===========================================================================
class RevereExampleApp extends StatelessWidget {
  const RevereExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revere Core Example',
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

class _ExamplePageState extends State<ExamplePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revere Core Example'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'LoggerMixin'),
            Tab(text: 'ErrorTrackerMixin'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _LoggerMixinTab(),
          _ErrorTrackerTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: LoggerMixin
// ---------------------------------------------------------------------------
class _LoggerMixinTab extends StatefulWidget {
  const _LoggerMixinTab();

  @override
  State<_LoggerMixinTab> createState() => _LoggerMixinTabState();
}

class _LoggerMixinTabState extends State<_LoggerMixinTab> {
  final _repo = UserRepository();
  String _status = '';

  Future<void> _run(Future<void> Function() fn, String label) async {
    try {
      await fn();
      if (mounted) setState(() => _status = '$label → OK (see console)');
    } catch (_) {
      if (mounted) setState(() => _status = '$label → error (see console)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      description:
          'LoggerMixin provides shorthand methods d/i/w/e/f/t that auto-attach '
          'the class name as the log context. Override loggerContext for a '
          'custom label.',
      status: _status,
      children: [
        _ActionButton(
          label: 'fetchAll()  →  d() + i()',
          onPressed: () => _run(_repo.fetchAll, 'fetchAll'),
        ),
        _ActionButton(
          label: 'addUser("")  →  w()',
          onPressed: () => _run(() => _repo.addUser(''), 'addUser empty'),
        ),
        _ActionButton(
          label: 'addUser("dave")  →  i()',
          onPressed: () => _run(() => _repo.addUser('dave'), 'addUser'),
        ),
        _ActionButton(
          label: 'deleteUser("nobody")  →  e()',
          onPressed: () =>
              _run(() => _repo.deleteUser('nobody'), 'deleteUser unknown'),
        ),
        _ActionButton(
          label: 'deleteUser("alice")  →  i()',
          onPressed: () =>
              _run(() => _repo.deleteUser('alice'), 'deleteUser'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: ErrorTrackerMixin
// ---------------------------------------------------------------------------
class _ErrorTrackerTab extends StatefulWidget {
  const _ErrorTrackerTab();

  @override
  State<_ErrorTrackerTab> createState() => _ErrorTrackerTabState();
}

class _ErrorTrackerTabState extends State<_ErrorTrackerTab> {
  final _svc = PaymentService();
  String _status = '';

  Future<void> _run(Future<void> Function() fn, String label) async {
    try {
      await fn();
      if (mounted) setState(() => _status = '$label → OK (see console)');
    } catch (_) {
      if (mounted) setState(() => _status = '$label → error (see console)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      description:
          'ErrorTrackerMixin adds withTracking (action + error logging), '
          'guarded (error-only), trackError (manual), and '
          'setupFlutterErrorTracking (global handlers).',
      status: _status,
      children: [
        _ActionButton(
          label: 'withTracking  →  purchase ok',
          onPressed: () =>
              _run(() => _svc.purchase('item_001', 9.99), 'purchase ok'),
        ),
        _ActionButton(
          label: 'withTracking  →  purchase error (price ≤ 0)',
          onPressed: () =>
              _run(() => _svc.purchase('item_002', -1), 'purchase error'),
        ),
        _ActionButton(
          label: 'guarded  →  refund (always throws)',
          onPressed: () => _run(() => _svc.refund('order_123'), 'refund'),
        ),
        _ActionButton(
          label: 'trackError  →  manual report',
          onPressed: () => _run(_svc.reportManualError, 'trackError'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------
class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.description,
    required this.children,
    required this.status,
  });

  final String description;
  final List<Widget> children;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Watch the debug console for output.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const Divider(height: 32),
          ...children,
          if (status.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(status, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

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
