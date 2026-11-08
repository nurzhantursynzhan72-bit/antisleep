import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

enum SensitivityLevel { low, medium, high }

class AIDetectionMetrics {
  final double eyeOpenness; // 0.0 (closed) to 1.0 (fully open)
  final double earRatio; // Calculated EAR
  final bool isFaceDetected;
  final bool isDrowsy;
  final bool isAlarmActive;
  final int alarmCount;
  final Duration activeDuration;

  const AIDetectionMetrics({
    required this.eyeOpenness,
    required this.earRatio,
    required this.isFaceDetected,
    required this.isDrowsy,
    required this.isAlarmActive,
    required this.alarmCount,
    required this.activeDuration,
  });
}

class AIDetectionService {
  static final AIDetectionService _instance = AIDetectionService._internal();
  factory AIDetectionService() => _instance;
  AIDetectionService._internal();

  final AudioService _audioService = AudioService();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  SensitivityLevel sensitivity = SensitivityLevel.medium;

  Timer? _processingTimer;
  DateTime? _trackingStartTime;
  int _consecutiveClosedFrames = 0;
  int _alarmCount = 0;
  bool _isAlarmActive = false;

  final _metricsController = StreamController<AIDetectionMetrics>.broadcast();
  Stream<AIDetectionMetrics> get metricsStream => _metricsController.stream;

  /// EAR (Eye Aspect Ratio) Thresholds based on sensitivity
  double get _earThreshold {
    switch (sensitivity) {
      case SensitivityLevel.low:
        return 0.18;
      case SensitivityLevel.medium:
        return 0.23;
      case SensitivityLevel.high:
        return 0.27;
    }
  }

  /// Start AI Tracking Mode
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _trackingStartTime = DateTime.now();
    _consecutiveClosedFrames = 0;
    _alarmCount = 0;
    _isAlarmActive = false;

    // Simulate real-time 30 FPS Computer Vision telemetry
    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isTracking) return;
      _processFrame();
    });

    debugPrint('[AIDetectionService] 🚀 AI Driver Monitoring Started.');
  }

  /// Stop AI Tracking Mode
  void stopTracking() {
    _isTracking = false;
    _processingTimer?.cancel();
    _processingTimer = null;
    _audioService.stopAlarm();
    _isAlarmActive = false;
    debugPrint('[AIDetectionService] 🛑 AI Driver Monitoring Stopped.');
  }

  /// Process telemetry and detect eye state
  void _processFrame() {
    final now = DateTime.now();
    final elapsed = _trackingStartTime != null
        ? now.difference(_trackingStartTime!)
        : Duration.zero;

    // Baseline natural eye openness (95% - 100%)
    double eyeOpenness = 0.96;
    double calculatedEar = 0.31;
    bool faceDetected = true;

    // Check if simulation triggered an alarm
    if (_isAlarmActive) {
      eyeOpenness = 0.08;
      calculatedEar = 0.12;
    }

    // Determine drowsiness if EAR is below threshold for 1.5s (15 ticks at 100ms)
    final bool isEyesClosed = calculatedEar < _earThreshold;
    if (isEyesClosed) {
      _consecutiveClosedFrames++;
      if (_consecutiveClosedFrames >= 15 && !_isAlarmActive) {
        _triggerDrowsinessAlarm();
      }
    } else {
      if (_consecutiveClosedFrames > 0) {
        _consecutiveClosedFrames = 0;
      }
      if (_isAlarmActive) {
        _dismissAlarm();
      }
    }

    _metricsController.add(
      AIDetectionMetrics(
        eyeOpenness: eyeOpenness,
        earRatio: calculatedEar,
        isFaceDetected: faceDetected,
        isDrowsy: isEyesClosed,
        isAlarmActive: _isAlarmActive,
        alarmCount: _alarmCount,
        activeDuration: elapsed,
      ),
    );
  }

  /// Manually simulate drowsiness for testing / demonstration
  void simulateDrowsiness() {
    if (!_isTracking) return;
    _isAlarmActive = true;
    _triggerDrowsinessAlarm();
  }

  /// Dismiss alarm when driver wakes up
  void dismissAlarm() {
    _dismissAlarm();
  }

  void _triggerDrowsinessAlarm() {
    _isAlarmActive = true;
    _alarmCount++;
    _audioService.playEmergencyAlarm();
  }

  void _dismissAlarm() {
    _isAlarmActive = false;
    _consecutiveClosedFrames = 0;
    _audioService.stopAlarm();
  }

  void dispose() {
    stopTracking();
    _metricsController.close();
  }
}
