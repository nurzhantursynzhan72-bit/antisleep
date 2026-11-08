import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isAlarmPlaying = false;
  bool get isAlarmPlaying => _isAlarmPlaying;

  final _alarmStateController = StreamController<bool>.broadcast();
  Stream<bool> get alarmStateStream => _alarmStateController.stream;

  /// Trigger emergency loud wake-up siren
  Future<void> playEmergencyAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    _alarmStateController.add(true);
    debugPrint('[AudioService] 🚨 ALARM TRIGGERED: Loud Wakeup Siren Playing!');
  }

  /// Stop emergency alarm when driver opens eyes or taps screen
  Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;
    _isAlarmPlaying = false;
    _alarmStateController.add(false);
    debugPrint('[AudioService] ✅ ALARM STOPPED: Driver alerted.');
  }

  void dispose() {
    _alarmStateController.close();
  }
}
