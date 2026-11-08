import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:antisleep_ai/providers/auth_provider.dart';
import 'package:antisleep_ai/providers/camera_provider.dart';
import 'package:antisleep_ai/services/auth_service.dart';
import 'package:antisleep_ai/widgets/auth_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Практикалық жұмыс №6: Тіркелу, Кіру және Сессия (Tasks 1-7)', () {
    test('1. Тіркелу (Registration) сәтті өтіп, пайдаланушы сессиясы сақталады', () async {
      final authService = AuthService();
      final result = await authService.register(
        fullName: 'Берік Сәрсенов',
        email: 'berik@gmail.com',
        phone: '+7 (705) 555-44-33',
        password: 'password123',
        vehicleModel: 'Kia K5',
        plateNumber: '02 KZ 111 BBB',
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
      expect(result.user!.fullName, 'Берік Сәрсенов');
      expect(result.user!.email, 'berik@gmail.com');

      // Сақталған сессияны тексеру
      final savedUser = await authService.getSavedSession();
      expect(savedUser, isNotNull);
      expect(savedUser!.email, 'berik@gmail.com');
    });

    test('2. Қате логин немесе пароль енгізілгенде қате хабарламасы қайтарылады', () async {
      final authService = AuthService();

      // Дұрыс емес құпиясөз
      final failResult = await authService.login(
        email: 'driver@antisleep.kz',
        password: 'wrong_password_999',
      );

      expect(failResult.success, isFalse);
      expect(failResult.errorMessage, isNotNull);
      expect(failResult.errorMessage, contains('Қате email немесе құпиясөз'));
    });

    test('3. Дұрыс мәліметтермен жүйеге кіру (Login) сәтті орындалады', () async {
      final authService = AuthService();
      final loginResult = await authService.login(
        email: 'driver@antisleep.kz',
        password: '123456',
      );

      expect(loginResult.success, isTrue);
      expect(loginResult.user, isNotNull);
      expect(loginResult.user!.email, 'arman.driver@gmail.com');

      // Сессия SharedPreferences-ке сақталды
      final session = await authService.getSavedSession();
      expect(session, isNotNull);
    });

    test('4. Logout сессияны тазартады', () async {
      final authService = AuthService();

      // Алдымен жүйеге кіру
      await authService.login(
        email: 'driver@antisleep.kz',
        password: '123456',
      );
      expect(await authService.getSavedSession(), isNotNull);

      // Жүйеден шығу (Logout)
      await authService.logout();

      // Шыққаннан кейін сақталған сессия жоқ
      final sessionAfterLogout = await authService.getSavedSession();
      expect(sessionAfterLogout, isNull);
    });
  });

  group('Практикалық жұмыс №6: State Management - Provider (Tasks 9-10)', () {
    test('AuthProvider сессияны басқарады және listener-лерге хабарлайды', () async {
      final provider = AuthProvider();
      expect(provider.isAuthenticated, isFalse);

      var notified = false;
      provider.addListener(() => notified = true);

      final ok = await provider.login(
        email: 'driver@antisleep.kz',
        password: '123456',
      );

      expect(ok, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser?.fullName, 'Арман Жұмабаев');
      expect(notified, isTrue);

      // Logout
      await provider.logout();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });
  });

  group('Практикалық жұмыс №6: Камера және Permission (Tasks 11-15)', () {
    test('CameraProvider: рұқсат берілген (Granted) күйін өңдеу', () {
      final cam = CameraProvider();
      expect(cam.isPermissionGranted, isFalse);

      cam.simulatePermissionGranted();
      expect(cam.isPermissionGranted, isTrue);
      expect(cam.isPermissionDenied, isFalse);
      expect(cam.isCameraReady, isTrue);
      expect(cam.errorMessage, isNull);
    });

    test('CameraProvider: рұқсат берілмеген (Denied) күйін өңдеу', () {
      final cam = CameraProvider();

      cam.simulatePermissionDenied();
      expect(cam.isPermissionDenied, isTrue);
      expect(cam.isPermissionGranted, isFalse);
      expect(cam.isCameraReady, isFalse);
      expect(cam.errorMessage, contains('Камераға рұқсат берілмеді'));
    });
  });

  group('Практикалық жұмыс №6: Қорғалған маршруттар (AuthGuard - Task 16)', () {
    testWidgets('Авторизацияланбаған пайдаланушыға қорғалған контент көрсетілмейді', (tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const AuthGuard(
              child: Text('Құпия контент'),
            ),
          ),
        ),
      );

      // 'Құпия контент' көрінбейді, AuthScreen (Кіру) экраны шығады
      expect(find.text('Құпия контент'), findsNothing);
      expect(find.text('Жүйеге кіру'), findsOneWidget);
    });
  });
}
