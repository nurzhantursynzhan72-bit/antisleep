class SessionModel {
  final String id;
  final String userId;
  final String vehicleId;
  final String? routeId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int drowsinessAlerts;
  final int yawnsDetected;
  final double safetyScore; // 0 to 100%
  final String status; // 'Қауіпсіз', 'Орташа', 'Қатерлі'
  final String notes;

  const SessionModel({
    required this.id,
    this.userId = 'usr-789',
    this.vehicleId = 'veh-001',
    this.routeId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.drowsinessAlerts,
    required this.yawnsDetected,
    required this.safetyScore,
    required this.status,
    this.notes = '',
  });

  SessionModel copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? routeId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    int? drowsinessAlerts,
    int? yawnsDetected,
    double? safetyScore,
    String? status,
    String? notes,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      routeId: routeId ?? this.routeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      drowsinessAlerts: drowsinessAlerts ?? this.drowsinessAlerts,
      yawnsDetected: yawnsDetected ?? this.yawnsDetected,
      safetyScore: safetyScore ?? this.safetyScore,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'route_id': routeId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'drowsiness_alerts': drowsinessAlerts,
      'yawns_detected': yawnsDetected,
      'safety_score': safetyScore,
      'status': status,
      'notes': notes,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? 'usr-789',
      vehicleId: (map['vehicle_id'] as String?) ?? 'veh-001',
      routeId: map['route_id'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      duration: Duration(seconds: (map['duration_seconds'] as num).toInt()),
      drowsinessAlerts: (map['drowsiness_alerts'] as num).toInt(),
      yawnsDetected: (map['yawns_detected'] as num).toInt(),
      safetyScore: (map['safety_score'] as num).toDouble(),
      status: map['status'] as String,
      notes: (map['notes'] as String?) ?? '',
    );
  }

  // Sample history data
  static List<SessionModel> getSampleHistory() {
    final now = DateTime.now();
    return [
      SessionModel(
        id: 'sess-001',
        userId: 'usr-789',
        vehicleId: 'veh-001',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 15)),
        duration: const Duration(hours: 1, minutes: 45),
        drowsinessAlerts: 0,
        yawnsDetected: 2,
        safetyScore: 98.0,
        status: 'Қауіпсіз',
        notes: 'Күндізгі қалыпты қалааралық сапар',
      ),
      SessionModel(
        id: 'sess-002',
        userId: 'usr-789',
        vehicleId: 'veh-001',
        startTime: now.subtract(const Duration(days: 1, hours: 4)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        duration: const Duration(hours: 3, minutes: 0),
        drowsinessAlerts: 2,
        yawnsDetected: 7,
        safetyScore: 84.5,
        status: 'Орташа',
        notes: 'Кешкі сапар, 2 рет жеңіл ескерту берілді',
      ),
      SessionModel(
        id: 'sess-003',
        userId: 'usr-789',
        vehicleId: 'veh-001',
        startTime: now.subtract(const Duration(days: 2, hours: 6)),
        endTime: now.subtract(const Duration(days: 2, hours: 2)),
        duration: const Duration(hours: 4, minutes: 10),
        drowsinessAlerts: 4,
        yawnsDetected: 12,
        safetyScore: 71.0,
        status: 'Қатерлі',
        notes: 'Түнгі қашық жол, дабыл сиренасы қосылды',
      ),
    ];
  }
}
