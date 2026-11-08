import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/realtime_message_model.dart';
import '../utils/app_logger.dart';

/// Байланыс күйі (Tasks 7, 8, 9)
enum RealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket арқылы нақты уақыттағы телеметрия мен хабарламаларды басқаратын сервис.
/// (Практикалық жұмыс №7: Тапсырмалар 3-9)
class RealtimeTelemetryService {
  final String _wsUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  RealtimeConnectionStatus _status = RealtimeConnectionStatus.disconnected;
  RealtimeConnectionStatus get status => _status;

  final _messageController = StreamController<RealtimeMessage>.broadcast();
  Stream<RealtimeMessage> get messageStream => _messageController.stream;

  final _statusController = StreamController<RealtimeConnectionStatus>.broadcast();
  Stream<RealtimeConnectionStatus> get statusStream => _statusController.stream;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _manualDisconnect = false;

  RealtimeTelemetryService({String? wsUrl})
      : _wsUrl = wsUrl ?? _defaultWsUrl();

  static String _defaultWsUrl() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:${ApiConfig.port}/ws/telemetry';
    }
    return 'ws://localhost:${ApiConfig.port}/ws/telemetry';
  }

  /// Сервермен нақты уақыттағы байланысты орнату (Task 4)
  Future<void> connect() async {
    if (_status == RealtimeConnectionStatus.connected ||
        _status == RealtimeConnectionStatus.connecting) {
      return;
    }

    _manualDisconnect = false;
    _updateStatus(RealtimeConnectionStatus.connecting);
    AppLogger.info('WebSocket серверіне қосылуда: $_wsUrl', tag: 'Realtime');

    try {
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(uri);

      // Байланысты күту
      await _channel!.ready.timeout(const Duration(seconds: 5));

      _updateStatus(RealtimeConnectionStatus.connected);
      _reconnectAttempts = 0;
      AppLogger.info('WebSocket байланысы сәтті орнатылды!', tag: 'Realtime');

      _channelSubscription = _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onDisconnected,
        onError: _onError,
      );
    } catch (e) {
      AppLogger.warning('WebSocket қосылу қатесі: $e', tag: 'Realtime', error: e);
      _updateStatus(RealtimeConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  /// Серверден келген деректерді автоматты қабылдау (Task 6)
  void _onMessageReceived(dynamic rawData) {
    try {
      final text = rawData.toString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final msg = RealtimeMessage.fromJson(json);

      AppLogger.debug('WebSocket хабарлама қабылданды: ${msg.type}', tag: 'Realtime');
      _messageController.add(msg);
    } catch (e) {
      AppLogger.error('Хабарламаны өңдеу қатесі: $e', tag: 'Realtime', error: e);
    }
  }

  /// Байланыс үзілгенде өңдеу (Task 7)
  void _onDisconnected() {
    AppLogger.warning('WebSocket байланысы үзілді!', tag: 'Realtime');
    _cleanChannel();
    if (!_manualDisconnect) {
      _updateStatus(RealtimeConnectionStatus.disconnected);
      _scheduleReconnect();
    } else {
      _updateStatus(RealtimeConnectionStatus.disconnected);
    }
  }

  /// Қате туындағанда өңдеу (Task 9)
  void _onError(Object error) {
    AppLogger.error('WebSocket қатесі: $error', tag: 'Realtime', error: error);
    _cleanChannel();
    _updateStatus(RealtimeConnectionStatus.error);
    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Интернет қайта қосылған кездегі байланысты қалпына келтіру (Task 8)
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_manualDisconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        AppLogger.warning('Қайта қосылу лимиті таусылды ($_maxReconnectAttempts рет).', tag: 'Realtime');
      }
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 10);
    _updateStatus(RealtimeConnectionStatus.reconnecting);
    AppLogger.info('Байланысты қалпына келтіру әрекеті ($_reconnectAttempts/$_maxReconnectAttempts) $delaySeconds сек кейін...', tag: 'Realtime');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  /// Деректерді нақты уақытта жіберу функциясы (Task 5)
  bool sendTelemetry(DriverTelemetry data) {
    if (_status != RealtimeConnectionStatus.connected || _channel == null) {
      AppLogger.warning('Телеметрия жіберілмеді: байланыс жоқ (Offline)', tag: 'Realtime');
      return false;
    }

    try {
      final jsonString = jsonEncode(data.toJson());
      _channel!.sink.add(jsonString);
      AppLogger.debug('Телеметрия жіберілді (EAR: ${data.ear.toStringAsFixed(2)})', tag: 'Realtime');
      return true;
    } catch (e) {
      AppLogger.error('Телеметрия жіберу кезіндегі қате: $e', tag: 'Realtime', error: e);
      return false;
    }
  }

  /// Шұғыл SOS дабылын нақты уақытта жіберу (Task 5)
  bool sendEmergencySos({String reason = 'Driver SOS button pressed'}) {
    if (_status != RealtimeConnectionStatus.connected || _channel == null) {
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'sos',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      AppLogger.warning('🚨 Диспетчерге ШҰҒЫЛ SOS дабылы жіберілді!', tag: 'Realtime');
      return true;
    } catch (e) {
      AppLogger.error('SOS жіберу қатесі: $e', tag: 'Realtime', error: e);
      return false;
    }
  }

  /// Байланысты қолмен үзу (Logout немесе баптаулар үшін)
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _cleanChannel();
    _updateStatus(RealtimeConnectionStatus.disconnected);
    AppLogger.info('WebSocket қолмен ажыратылды.', tag: 'Realtime');
  }

  void _cleanChannel() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _updateStatus(RealtimeConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}

