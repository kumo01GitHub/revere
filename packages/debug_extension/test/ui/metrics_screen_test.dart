import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/src/ui/metrics_screen.dart';

void main() {
  testWidgets('MetricsScreen displays AppBar and body', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MetricsScreen()));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Metrics data will be shown here.'), findsOneWidget);
  });
}
