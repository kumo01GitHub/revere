import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/ui/metrics_widget.dart';
import 'package:revere_debug_extension/src/ui/floating_button.dart';
import 'package:revere_debug_extension/src/transport/metrics_transport.dart';
import 'package:revere_debug_extension/src/metrics/metrics_collector.dart';

void main() {
  testWidgets('MetricsWidget displays metrics', (WidgetTester tester) async {
    final transport = MetricsTransport();
    transport.add(MetricsData(
        cpuUsage: 1.23, memoryUsage: 456, timestamp: DateTime(2024, 1, 1)));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MetricsWidget(transport: transport)),
    ));
    expect(find.textContaining('CPU:'), findsOneWidget);
    expect(find.textContaining('Memory:'), findsOneWidget);
  });

  testWidgets('FloatingMetricsButton toggles metrics panel',
      (WidgetTester tester) async {
    final transport = MetricsTransport();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      floatingActionButton: FloatingMetricsButton(transport: transport),
    )));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(MetricsWidget), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.byType(MetricsWidget), findsNothing);
  });
}
