import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import 'database_service.dart';

/// Аутентификация нәтижесі
class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.ok(UserModel user) => AuthResult(success: true, user: user);
  factory AuthResult.error(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Пайдаланушы сессиясын, тіркелуін және жүйеге кіруін басқаратын сервис.
/// (Практикалық жұмыс №6: Тапсырмалар 1-7)
class AuthService {
  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUsersAccounts = 'auth_registered_accounts';

  final DatabaseService _db;

  AuthService({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  /// Сессияны инициализациялау: қосымшаны қосқанда сақталған сессияны тексеру
  Future<UserModel?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final userId = prefs.getString(_keyUserId);

      if (!isLoggedIn || userId == null || userId.isEmpty) {
        return null;
      }

      // SQLite базасынан пайдаланушыны іздеу
      final user = await _db.getUser(userId);
      if (user != null) {
        return user;
      }

      // Егер стандартты қолданушы болса
      if (userId == 'usr-789') {
        final defaultUser = UserModel.current();
        await _db.updateUser(defaultUser);
        return defaultUser;
      }

      return null;
    } catch (e) {
      debugPrint('[AuthService] Сессияны тексеру қатесі: $e');
      return null;
    }
  }

  /// Жүйеге кіру (Login)
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return AuthResult.error('Email және құпиясөзді енгізіңіз');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_keyUsersAccounts);
      Map<String, dynamic> accounts = {};
      if (accountsJson != null) {
        try {
          accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      // 1. Алдын ала орнатылған стандартты аккаунтты тексеру
      // (driver@antisleep.kz / 123456)
      if ((cleanEmail == 'driver@antisleep.kz' || cleanEmail == 'arman.driver@gmail.com') &&
          cleanPass == '123456') {
        final user = UserModel.current();
        await _db.updateUser(user);
        await _saveSession(user);
        return AuthResult.ok(user);
      }

      // 2. Жаңадан тіркелген аккаунттар базасын тексеру
      if (accounts.containsKey(cleanEmail)) {
        final accountData = accounts[cleanEmail] as Map<String, dynamic>;
        final storedPassword = accountData['password'] as String?;
        final userId = accountData['userId'] as String;

        if (storedPassword == cleanPass) {
          final user = await _db.getUser(userId);
          if (user != null) {
            await _saveSession(user);
            return AuthResult.ok(user);
          }
        }
      }

      // Егер сәйкестік табылмаса — қате логин немесе пароль
      return AuthResult.error('Қате email немесе құпиясөз енгізілді!');
    } catch (e) {
      return AuthResult.error('Жүйеге кіру кезінде қате орын алды: $e');
    }
  }

  /// Пайдаланушыны тіркеу (Registration)
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String vehicleModel,
    required String plateNumber,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();
    final cleanVehicle = vehicleModel.trim();
    final cleanPlate = plateNumber.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_keyUsersAccounts);
      Map<String, dynamic> accounts = {};
      if (accountsJson != null) {
        try {
          accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (accounts.containsKey(cleanEmail) ||
          cleanEmail == 'driver@antisleep.kz' ||
          cleanEmail == 'arman.driver@gmail.com') {
        return AuthResult.error('Бұл электрондық пошта жүйеде тіркелген!');
      }

      // Жаңа пайдаланушы жасау
      final newUserId = 'usr-${DateTime.now().millisecondsSinceEpoch}';
      final newUser = UserModel(
        id: newUserId,
        fullName: cleanName,
        email: cleanEmail,
        phone: cleanPhone.isEmpty ? '+7 (707) 123-45-67' : cleanPhone,
        vehicleModel: cleanVehicle.isEmpty ? 'Көлік көрсетілмеген' : cleanVehicle,
        plateNumber: cleanPlate.isEmpty ? '01 KZ 000 AAA' : cleanPlate,
        totalSafeHours: 0.0,
        totalTrips: 0,
        createdAt: DateTime.now(),
      );

      // SQLite-қа сақтау
      final db = await _db.database;
      if (db != null) {
        await db.insert('users', newUser.toMap());
        if (cleanVehicle.isNotEmpty) {
          final newVehicle = VehicleModel(
            id: 'veh-${DateTime.now().millisecondsSinceEpoch}',
            userId: newUserId,
            brand: cleanVehicle.split(' ').first,
            model: cleanVehicle,
            plateNumber: cleanPlate.isEmpty ? '01 KZ 000 AAA' : cleanPlate,
            year: DateTime.now().year,
            isDefault: true,
          );
          await _db.saveVehicle(newVehicle);
        }
      } else {
        await _db.updateUser(newUser);
      }

      // Тіркелген аккаунттар тізіміне қосу
      accounts[cleanEmail] = {
        'userId': newUserId,
        'password': cleanPass,
      };
      await prefs.setString(_keyUsersAccounts, jsonEncode(accounts));

      // Сессияны автоматты сақтау
      await _saveSession(newUser);
      return AuthResult.ok(newUser);
    } catch (e) {
      return AuthResult.error('Тіркелу кезінде қате туындады: $e');
    }
  }

  /// Жүйеден шығу (Logout)
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
    } catch (e) {
      debugPrint('[AuthService] Logout қатесі: $e');
    }
  }

  /// Сессияны SharedPreferences-ке сақтау
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserEmail, user.email);
  }
}

