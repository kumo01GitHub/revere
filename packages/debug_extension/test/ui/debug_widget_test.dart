import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/ui/debug_widget.dart';
import 'package:revere/core.dart';
import 'package:revere_debug_extension/src/transport/state_transport.dart';

class DummyLogger extends Logger {
  DummyLogger() : super([]);
  @override
  Future<void> log(LogLevel level, Object message,
      {Object? error, StackTrace? stackTrace, String? context}) async {}
}

void main() {
  testWidgets('DebugWidget displays tabs and list', (tester) async {
    final logger = DummyLogger();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugWidget(loggers: [logger], tabNames: const ['Tab1']),
        ),
      ),
    );
    // Tab is displayed
    expect(find.text('Tab1'), findsOneWidget);
    // ListView is displayed
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('DebugWidget enforces maxLength', (tester) async {
    final logger = DummyLogger();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugWidget(loggers: [logger], maxLength: 2),
        ),
      ),
    );
    // Add values via StateTransport
    final stateTransport = logger.transports
        .firstWhere((t) => t is StateTransport) as StateTransport;
    stateTransport.state.value = ['a', 'b', 'c'];
    await tester.pumpAndSettle();
    // Wait a bit to avoid Timer exception after dispose
    await tester.pump(const Duration(seconds: 1));
    // Only 2 items should be displayed due to maxLength=2
    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(2));
  });
}
