import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_fix/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We changed "MyApp()" to "HamroFixApp()" to match your code.
    await tester.pumpWidget(const HamroFixApp());

    // Verify that the app title or a specific text exists
    expect(find.text('HamroFix'), findsAtLeast(1));
  });
}
