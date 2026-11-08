import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// Қосымшаның пайдаланушы сессиясы мен аутентификациясын басқаратын Provider.
/// (Практикалық жұмыс №6: Тапсырмалар 9-10 - State Management: Provider)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _db;

  AuthProvider({AuthService? authService, DatabaseService? db})
      : _authService = authService ?? AuthService(),
        _db = db ?? DatabaseService.instance;

  UserModel? _currentUser;
  VehicleModel? _currentVehicle;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  VehicleModel? get currentVehicle => _currentVehicle;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Қосымша қосылғанда сақталған сессияны тексеру
  Future<bool> initSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedUser = await _authService.getSavedSession();
      if (savedUser != null) {
        _currentUser = savedUser;
        await _loadVehicleForUser(savedUser.id);
      }
    } catch (e) {
      _errorMessage = 'Сессияны қалпына келтіру мүмкін болмады: $e';
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
    return isAuthenticated;
  }

  /// Жүйеге кіру (Login)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);
    _isLoading = false;

    if (result.success && result.user != null) {
      _currentUser = result.user;
      await _loadVehicleForUser(result.user!.id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage ?? 'Қате логин немесе құпиясөз!';
      notifyListeners();
      return false;
    }
  }

  /// Тіркелу (Registration)
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String vehicleModel,
    required String plateNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      vehicleModel: vehicleModel,
      plateNumber: plateNumber,
    );

    _isLoading = false;

    if (result.success && result.user != null) {
      _currentUser = result.user;
      await _loadVehicleForUser(result.user!.id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage ?? 'Тіркелу кезінде қате туындады!';
      notifyListeners();
      return false;
    }
  }

  /// Профильді өзгерту / жаңарту
  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _errorMessage = 'Профильді жаңарту қатесі: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Жүйеден шығу (Logout)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    _currentVehicle = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadVehicleForUser(String userId) async {
    try {
      final veh = await _db.getDefaultVehicle(userId);
      _currentVehicle = veh;
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

