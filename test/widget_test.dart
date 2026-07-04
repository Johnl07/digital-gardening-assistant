 import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_gardening_assistant/main.dart';

void main() {
  testWidgets('Digital Gardening Assistant UI Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify title and tabs
    expect(find.text('My Digital Garden'), findsOneWidget);
    expect(find.text('MAGDAGDAG'), findsOneWidget);
    expect(find.text('MGA HALAMAN'), findsOneWidget);

    // Verify form elements
    expect(find.text('Kasalukuyang Stage'), findsOneWidget);
    expect(find.text('I-tanim sa Garden'), findsOneWidget);
  });
}
