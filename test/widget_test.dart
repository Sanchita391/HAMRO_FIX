import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_fix/screens/auth/landing_page.dart';

void main() {
  testWidgets('Landing page shows HamroFix', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LandingPage()),
    );
    expect(find.text('HamroFix'), findsAtLeast(1));
  });
}
