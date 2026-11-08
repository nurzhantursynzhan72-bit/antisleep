/// Серверден нақты уақытта келетін хабарламалар моделі (Task 6)
class RealtimeMessage {
  final String type;
  final String level; // 'info', 'warning', 'danger', 'emergency'
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> raw;

  const RealtimeMessage({
    required this.type,
    required this.level,
    required this.message,
    required this.timestamp,
    this.raw = const {},
  });

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      type: (json['type'] as String?) ?? 'message',
      level: (json['level'] as String?) ?? 'info',
      message: (json['message'] as String?) ?? (json['type'] == 'telemetry_ack' ? 'Телеметрия қабылданды' : ''),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      raw: json,
    );
  }

  bool get isAlert => level == 'danger' || level == 'emergency' || type == 'dispatcher_alert';
}

/// Жүргізушінің нақты уақытта серверге жіберетін телеметрия деректері (Task 5)
class DriverTelemetry {
  final double ear;
  final double eyeOpenness;
  final double speed;
  final bool isDrowsy;
  final int yawnsDetected;
  final double safetyScore;
  final DateTime timestamp;

  const DriverTelemetry({
    required this.ear,
    required this.eyeOpenness,
    this.speed = 85.0,
    required this.isDrowsy,
    this.yawnsDetected = 0,
    this.safetyScore = 95.0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'telemetry',
      'ear': ear,
      'eyeOpenness': eyeOpenness,
      'speed': speed,
      'drowsy': isDrowsy,
      'yawns': yawnsDetected,
      'safetyScore': safetyScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

