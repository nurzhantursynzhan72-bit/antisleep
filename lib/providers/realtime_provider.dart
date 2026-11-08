import 'dart:async';
import 'package:flutter/material.dart';
import '../models/realtime_message_model.dart';
import '../services/realtime_telemetry_service.dart';
import '../utils/app_logger.dart';

/// Нақты уақыттағы WebSocket байланысы мен деректер ағынын басқаратын Provider
/// (Практикалық жұмыс №7: Тапсырмалар 3-9)
class RealtimeProvider extends ChangeNotifier {
  final RealtimeTelemetryService _service;
  StreamSubscription<RealtimeMessage>? _msgSub;
  StreamSubscription<RealtimeConnectionStatus>? _statusSub;
  Timer? _telemetryTicker;

  final List<RealtimeMessage> _messages = [];
  DriverTelemetry? _latestSentTelemetry;
  int _packetsSent = 0;
  int _packetsReceived = 0;
  String? _activeDispatcherWarning;

  RealtimeProvider({RealtimeTelemetryService? service})
      : _service = service ?? RealtimeTelemetryService() {
    _initListeners();
  }

  RealtimeConnectionStatus get status => _service.status;
  bool get isConnected => _service.status == RealtimeConnectionStatus.connected;
  bool get isConnecting => _service.status == RealtimeConnectionStatus.connecting;
  bool get isReconnecting => _service.status == RealtimeConnectionStatus.reconnecting;
  bool get isDisconnected => _service.status == RealtimeConnectionStatus.disconnected;
  bool get isError => _service.status == RealtimeConnectionStatus.error;

  List<RealtimeMessage> get messages => List.unmodifiable(_messages);
  DriverTelemetry? get latestSentTelemetry => _latestSentTelemetry;
  int get packetsSent => _packetsSent;
  int get packetsReceived => _packetsReceived;
  String? get activeDispatcherWarning => _activeDispatcherWarning;
  bool get isStreaming => _telemetryTicker != null && _telemetryTicker!.isActive;

  void _initListeners() {
    _statusSub = _service.statusStream.listen((status) {
      notifyListeners();
    });

    _msgSub = _service.messageStream.listen((msg) {
      _packetsReceived++;
      _messages.insert(0, msg);
      if (_messages.length > 50) {
        _messages.removeLast();
      }

      if (msg.type == 'dispatcher_alert' || msg.isAlert) {
        _activeDispatcherWarning = msg.message;
      }
      notifyListeners();
    });
  }

  /// Серверге қосылу (Task 4)
  Future<void> connect() async {
    await _service.connect();
    notifyListeners();
  }

  /// Байланысты үзу (Task 7)
  void disconnect() {
    stopAutoTelemetry();
    _service.disconnect();
    notifyListeners();
  }

  /// Байланыстың үзілуін тестілеу үшін симуляция жасау (Tasks 7, 8, 9)
  void simulateConnectionDrop() {
    AppLogger.warning('Тест: байланыстың үзілуі қолмен симуляцияланды', tag: 'Realtime');
    _service.disconnect();
    notifyListeners();
  }

  /// Телеметрияны нақты уақытта жіберу (Task 5)
  bool sendTelemetry({
    required double ear,
    required double eyeOpenness,
    double speed = 80.0,
    required bool isDrowsy,
  }) {
    final telemetry = DriverTelemetry(
      ear: ear,
      eyeOpenness: eyeOpenness,
      speed: speed,
      isDrowsy: isDrowsy,
      timestamp: DateTime.now(),
    );

    _latestSentTelemetry = telemetry;
    final sent = _service.sendTelemetry(telemetry);
    if (sent) {
      _packetsSent++;
    }
    notifyListeners();
    return sent;
  }

  /// Шұғыл SOS дабылы
  bool sendSos() {
    final sent = _service.sendEmergencySos();
    if (sent) {
      _packetsSent++;
      notifyListeners();
    }
    return sent;
  }

  /// Сапар кезінде телеметрияны әр 2 секунд сайын автоматты жіберу
  void startAutoTelemetry({
    required double Function() getEar,
    required double Function() getEyeOpenness,
    required bool Function() getIsDrowsy,
  }) {
    stopAutoTelemetry();
    _telemetryTicker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isConnected) {
        sendTelemetry(
          ear: getEar(),
          eyeOpenness: getEyeOpenness(),
          isDrowsy: getIsDrowsy(),
        );
      }
    });
    notifyListeners();
  }

  void stopAutoTelemetry() {
    _telemetryTicker?.cancel();
    _telemetryTicker = null;
    notifyListeners();
  }

  void dismissDispatcherWarning() {
    _activeDispatcherWarning = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoTelemetry();
    _msgSub?.cancel();
    _statusSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
