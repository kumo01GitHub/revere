import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere/core.dart';
import 'package:revere_debug_extension/src/ui/debug_widget.dart';
import 'package:revere_debug_extension/src/ui/floating_button.dart';
// (不要なimportを削除)
// import 'package:revere_debug_extension/src/logger/metrics_logger.dart';
// import 'package:revere_debug_extension/src/metrics/metrics_collector.dart';

void main() {
  testWidgets('DebugWidget displays logs', (WidgetTester tester) async {
    final logger = Logger();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DebugWidget(loggers: [logger])),
    ));
    // DebugWidget作成後にログ出力
    logger.info('test log');
    await tester.pump();
    expect(find.textContaining('test log'), findsOneWidget);
  });

  testWidgets('FloatingMetricsButton toggles debug panel',
      (WidgetTester tester) async {
    final logger = Logger();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      floatingActionButton: FloatingMetricsButton(loggers: [logger]),
    )));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(DebugWidget), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(DebugWidget), findsNothing);
  });
}
