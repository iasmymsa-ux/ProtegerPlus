import 'package:flutter_test/flutter_test.dart';

import 'package:proteger_plus/main.dart';

void main() {
  testWidgets('ProtegerPlus smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProtegerPlusApp());

    // Verify that the title or initial elements are on screen.
    expect(find.text('Proteger+'), findsWidgets);
  });
}
