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
    // Check for floating action button
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
