import 'package:flutter_test/flutter_test.dart';
import 'package:gestia/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GestiaApp());
    expect(find.byType(GestiaApp), findsOneWidget);
    // Settle flutter_animate timers (longest: 700ms delay + 400ms = 1100ms)
    // without reaching the 2400ms nav timer that requires Supabase.
    await tester.pump(const Duration(milliseconds: 1200));
    // Widget disposes here → _navTimer.cancel() → no pending timers.
  });
}
