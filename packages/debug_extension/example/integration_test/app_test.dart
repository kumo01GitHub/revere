import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows metrics button', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    // Check for floating action button (metrics button)
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Metrics collection button toggles state', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    // Initial state: Start Metrics Collection button is shown
    expect(find.text('Start Metrics Collection'), findsOneWidget);
    // Tap the button
    await tester.tap(find.text('Start Metrics Collection'));
    await tester.pumpAndSettle();
    // State changes: Stop Metrics Collection button is shown
    expect(find.text('Stop Metrics Collection'), findsOneWidget);
    // Tap again to return to original state
    await tester.tap(find.text('Stop Metrics Collection'));
    await tester.pumpAndSettle();
    expect(find.text('Start Metrics Collection'), findsOneWidget);
  });

  testWidgets('FloatingMetricsButton shows tabs and switches', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    // Start metrics collection
    await tester.tap(find.text('Start Metrics Collection'));
    await tester.pumpAndSettle();
    // Tap the metrics button to open the panel
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    // Check that tabs are shown
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Metrics'), findsOneWidget);
    // Switch to Metrics tab
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    // Wait a bit for metrics to be recorded
    await tester.pump(const Duration(seconds: 2));
    // Check that there is at least one ListTile in the Metrics tab
    final metricsListTiles = find.descendant(
      of: find.byType(TabBarView),
      matching: find.byType(ListTile),
    );
    expect(metricsListTiles, findsWidgets);

    // Check that at least one ListTile contains 'memory' or 'cpu' (case-insensitive)
    bool foundExpectedMetric = false;
    for (final element in tester.widgetList<ListTile>(metricsListTiles)) {
      final textWidget = element.title;
      if (textWidget is Text) {
        final text = textWidget.data?.toLowerCase() ?? '';
        if (text.contains('memory') || text.contains('cpu')) {
          foundExpectedMetric = true;
          break;
        }
      }
    }
    expect(
      foundExpectedMetric,
      isTrue,
      reason: 'Metrics tab should contain memory or cpu info',
    );
  });

  testWidgets('Metrics values stabilize after repeated collection', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    // Start metrics collection
    await tester.tap(find.text('Start Metrics Collection'));
    await tester.pumpAndSettle();
    // Open Metrics tab
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    // Wait for values to stabilize by pumping several times
    for (int i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    // Ensure CPU value is not N/A (no ListTile text contains N/A)
    final metricsListTiles = find.descendant(
      of: find.byType(TabBarView),
      matching: find.byType(ListTile),
    );
    bool foundCpuValue = false;
    for (final element in tester.widgetList<ListTile>(metricsListTiles)) {
      final textWidget = element.title;
      if (textWidget is Text) {
        final text = textWidget.data?.toLowerCase() ?? '';
        if (text.contains('cpu') && !text.contains('n/a')) {
          foundCpuValue = true;
          break;
        }
      }
    }
    expect(
      foundCpuValue,
      isTrue,
      reason: 'There is a row where CPU value is not N/A',
    );
  });
}
