import 'package:flutter_test/flutter_test.dart';
import 'package:antisleep_ai/main.dart';
import 'package:antisleep_ai/screens/splash_screen.dart';

void main() {
  testWidgets('AntiSleep AI app starts and renders SplashScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AntiSleepAIApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Нұсқасы 1.0.0 (MVP) • On-Device AI'), findsOneWidget);

    // Pump until splash animation completes and timer fires
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
  });
}
