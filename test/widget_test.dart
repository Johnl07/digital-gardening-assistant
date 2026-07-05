import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_gardening_assistant/main.dart';

void main() {
  testWidgets('Digital Gardening Assistant UI Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify Onboarding / Introduction Page is visible first
    expect(find.text('Digital Gardening\nAssistant'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap "Get Started" to navigate to main app
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify bottom navigation tabs are now visible
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Add Plant'), findsOneWidget);
    expect(find.text('My Garden'), findsOneWidget);

    // Navigate to Add Plant tab
    await tester.tap(find.text('Add Plant'));
    await tester.pumpAndSettle();

    // Verify form elements on the Add Plant page
    expect(find.text('Current Stage'), findsOneWidget);
    expect(find.text('Add to Garden'), findsOneWidget);
  });
}
