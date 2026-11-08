class AlertEventModel {
  final String id;
  final String sessionId;
  final DateTime timestamp;
  final String alertType; // 'microsleep', 'yawn', 'distraction'
  final double earValue;
  final bool isResolved;
  final String actionTaken;

  const AlertEventModel({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.alertType,
    required this.earValue,
    this.isResolved = true,
    this.actionTaken = 'Сирена ойнатылды және жүргізуші оянды',
  });

  AlertEventModel copyWith({
    String? id,
    String? sessionId,
    DateTime? timestamp,
    String? alertType,
    double? earValue,
    bool? isResolved,
    String? actionTaken,
  }) {
    return AlertEventModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      alertType: alertType ?? this.alertType,
      earValue: earValue ?? this.earValue,
      isResolved: isResolved ?? this.isResolved,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'alert_type': alertType,
      'ear_value': earValue,
      'is_resolved': isResolved ? 1 : 0,
      'action_taken': actionTaken,
    };
  }

  factory AlertEventModel.fromMap(Map<String, dynamic> map) {
    return AlertEventModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      alertType: map['alert_type'] as String,
      earValue: (map['ear_value'] as num).toDouble(),
      isResolved: (map['is_resolved'] as int? ?? 1) == 1,
      actionTaken: (map['action_taken'] as String?) ?? '',
    );
  }
}

