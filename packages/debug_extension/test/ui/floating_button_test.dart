import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/ui/floating_button.dart';
import 'package:revere_debug_extension/src/ui/debug_widget.dart';
import 'package:revere/core.dart';

class DummyLogger extends Logger {
  DummyLogger() : super([]);
  @override
  Future<void> log(LogLevel level, Object message,
      {Object? error, StackTrace? stackTrace, String? context}) async {}
}

void main() {
  testWidgets('FloatingMetricsButton toggles debug panel', (tester) async {
    final logger = DummyLogger();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingMetricsButton(loggers: [logger]),
        ),
      ),
    );
    // Initially: panel is hidden
    expect(find.byType(DebugWidget), findsNothing);
    // Show panel by tapping button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(DebugWidget), findsOneWidget);
    // Hide panel by tapping again
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(DebugWidget), findsNothing);
  });
}
