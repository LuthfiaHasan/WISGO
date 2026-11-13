import 'package:flutter_test/flutter_test.dart';
import 'package:rancakin_mobile/main.dart';

void main() {
  testWidgets('WisgoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WisgoApp());
    expect(find.byType(WisgoApp), findsOneWidget);
    // Pump frames to verify splash screen transitions cleanly without infinite loop
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
