import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// Камераға берілген рұқсат күйі (Task 13, 15)
enum CameraPermissionState {
  initial,
  requesting,
  granted,
  denied,
}

/// Күрделі мобильді функция: Камера және Permission басқарушы Provider
/// (Практикалық жұмыс №6: Тапсырмалар 11-15)
class CameraProvider extends ChangeNotifier {
  CameraPermissionState _permissionState = CameraPermissionState.initial;
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraReady = false;
  String? _errorMessage;
  bool _isSimulationMode = false;

  CameraPermissionState get permissionState => _permissionState;
  CameraController? get cameraController => _cameraController;
  bool get isCameraReady => _isCameraReady;
  String? get errorMessage => _errorMessage;
  bool get isSimulationMode => _isSimulationMode;
  bool get isPermissionGranted => _permissionState == CameraPermissionState.granted;
  bool get isPermissionDenied => _permissionState == CameraPermissionState.denied;

  /// Құрылғыдан камераға рұқсат сұрау (Task 13)
  Future<bool> requestCameraPermission() async {
    _permissionState = CameraPermissionState.requesting;
    _errorMessage = null;
    notifyListeners();

    try {
      // Құрылғыда қолжетімді камераларды сұрау
      _availableCameras = await availableCameras();

      if (_availableCameras.isNotEmpty) {
        _permissionState = CameraPermissionState.granted;
        _isSimulationMode = false;
        await _setupController(_availableCameras.first);
        notifyListeners();
        return true;
      } else {
        // Камера физикалық түрде табылмаған жағдайда (эмулятор/ноутбук)
        _permissionState = CameraPermissionState.granted;
        _isSimulationMode = true;
        _isCameraReady = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[CameraProvider] Камера рұқсаты немесе құрылғы қатесі: $e');
      _permissionState = CameraPermissionState.denied;
      _errorMessage = 'Камераға қолжетімділік берілмеді немесе құрылғыда анықталмады.';
      _isCameraReady = false;
      notifyListeners();
      return false;
    }
  }

  /// Камера контроллерін іске қосу
  Future<void> _setupController(CameraDescription camera) async {
    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _cameraController = controller;
      _isCameraReady = true;
      _isSimulationMode = false;
    } catch (e) {
      debugPrint('[CameraProvider] Камера инициализация қатесі: $e');
      // Егер контроллер іске қосылмаса, AI симуляциялық камера режиміне көшеді
      _isSimulationMode = true;
      _isCameraReady = true;
    }
  }

  /// Task 15 үшін: Рұқсат берілмеген (Denied) күйін сынау
  void simulatePermissionDenied() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraReady = false;
    _permissionState = CameraPermissionState.denied;
    _errorMessage = 'Камераға рұқсат берілмеді. Қосымшаның толық жұмыс істеуі үшін параметрлерден рұқсат беріңіз.';
    notifyListeners();
  }

  /// Task 15 үшін: Рұқсат берілген (Granted) күйін қайтару
  void simulatePermissionGranted() {
    _permissionState = CameraPermissionState.granted;
    _isSimulationMode = true;
    _isCameraReady = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Симуляциялық режимге еркін ауысу
  void toggleSimulationMode() {
    _isSimulationMode = !_isSimulationMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

