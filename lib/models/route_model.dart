class RouteModel {
  final String id;
  final String title;
  final double distanceKm;
  final int avgDurationMinutes;
  final String riskLevel; // 'Төмен', 'Орташа', 'Қатерлі'
  final bool isFavorite;
  final String notes;
  final DateTime createdAt;

  const RouteModel({
    required this.id,
    required this.title,
    required this.distanceKm,
    required this.avgDurationMinutes,
    required this.riskLevel,
    this.isFavorite = false,
    this.notes = '',
    required this.createdAt,
  });

  String get formattedDuration {
    final hours = avgDurationMinutes ~/ 60;
    final mins = avgDurationMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '$hours сағ $mins мин';
    } else if (hours > 0) {
      return '$hours сағ';
    } else {
      return '$mins мин';
    }
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(distanceKm.truncateToDouble() == distanceKm ? 0 : 1)} км';

  RouteModel copyWith({
    String? id,
    String? title,
    double? distanceKm,
    int? avgDurationMinutes,
    String? riskLevel,
    bool? isFavorite,
    String? notes,
    DateTime? createdAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      distanceKm: distanceKm ?? this.distanceKm,
      avgDurationMinutes: avgDurationMinutes ?? this.avgDurationMinutes,
      riskLevel: riskLevel ?? this.riskLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'distance_km': distanceKm,
      'avg_duration_minutes': avgDurationMinutes,
      'risk_level': riskLevel,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      avgDurationMinutes: (map['avg_duration_minutes'] as num).toInt(),
      riskLevel: map['risk_level'] as String,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  // ==========================================
  // REST API JSON сериализациясы (Практикалық жұмыс №5)
  // ==========================================

  /// Сервер JSON-ын Dart объектісіне түрлендіру.
  /// Мысал: {"id":"route-001","title":"...","distanceKm":75,"isFavorite":true,...}
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id == null || title == null) {
      throw const FormatException('JSON ішінде "id" немесе "title" жоқ');
    }
    return RouteModel(
      id: id.toString(),
      title: title as String,
      distanceKm: (json['distanceKm'] as num? ?? 0).toDouble(),
      avgDurationMinutes: (json['avgDurationMinutes'] as num? ?? 0).toInt(),
      riskLevel: (json['riskLevel'] as String?) ?? 'Төмен',
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      notes: (json['notes'] as String?) ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Dart объектісін серверге жіберілетін JSON-ға түрлендіру.
  /// [includeId] = false — POST сұрауында ID-ді сервер өзі береді.
  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      'title': title,
      'distanceKm': distanceKm,
      'avgDurationMinutes': avgDurationMinutes,
      'riskLevel': riskLevel,
      'isFavorite': isFavorite,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

