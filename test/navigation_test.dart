import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antisleep_ai/main.dart';
import 'package:antisleep_ai/screens/auth_screen.dart';
import 'package:antisleep_ai/screens/edit_vehicle_screen.dart';
import 'package:antisleep_ai/screens/home_screen.dart';
import 'package:antisleep_ai/services/database_service.dart';
import 'package:antisleep_ai/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DatabaseService.setupFfiIfNeeded();

  testWidgets('Full Navigation and Form Validation Test Flow',
      (WidgetTester tester) async {
    // 1. Launch App
    await tester.pumpWidget(const AntiSleepAIApp());
    expect(find.text('Нұсқасы 1.0.0 (MVP) • On-Device AI'), findsOneWidget);

    // 2. Let Splash finish and transition to Onboarding
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));

    // 3. Skip Onboarding to go to AuthScreen
    final skipBtn = find.text('Өткізіп жіберу');
    expect(skipBtn, findsOneWidget);
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    // 4. Verify AuthScreen is displayed
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Қайта оралуыңызбен!'), findsOneWidget);

    // 5. Test Guest Login to enter HomeScreen
    final guestBtn = find.text('Тіркелмей, қонақ ретінде сынау');
    expect(guestBtn, findsOneWidget);
    await tester.tap(guestBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 6. Verify HomeScreen & Dashboard
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    // 7. Test Bottom Navigation Tabs
    // Tap on Trips tab
    await tester.tap(find.text('Сапарлар'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Сапарлар тарихы'), findsOneWidget);

    // Tap on Routes / Search tab
    await tester.tap(find.text('Бағыттар'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Іздеу және Бағыттар'), findsOneWidget);

    // Tap on Profile tab
    await tester.tap(find.text('Профиль'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Жүргізуші профилі'), findsOneWidget);

    // 8. Open Edit Vehicle Screen from Profile
    final editVehicleBtn = find.byIcon(Icons.edit_outlined);
    expect(editVehicleBtn, findsOneWidget);
    await tester.tap(editVehicleBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(EditVehicleScreen), findsOneWidget);
    expect(find.text('Көлік және SOS баптаулары'), findsOneWidget);

    // Pop back to Profile
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 9. Open Settings Screen from Profile
    final settingsBtn = find.byIcon(Icons.settings_outlined);
    expect(settingsBtn, findsOneWidget);
    await tester.tap(settingsBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Баптаулар'), findsOneWidget);

    // Pop back
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Return to Home tab
    await tester.tap(find.text('Басты'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('START'), findsOneWidget);
  });
}
