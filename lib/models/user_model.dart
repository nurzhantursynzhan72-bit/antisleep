class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleModel;
  final String plateNumber;
  final double totalSafeHours;
  final int totalTrips;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '+7 (707) 123-45-67',
    required this.vehicleModel,
    required this.plateNumber,
    required this.totalSafeHours,
    required this.totalTrips,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? vehicleModel,
    String? plateNumber,
    double? totalSafeHours,
    int? totalTrips,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      plateNumber: plateNumber ?? this.plateNumber,
      totalSafeHours: totalSafeHours ?? this.totalSafeHours,
      totalTrips: totalTrips ?? this.totalTrips,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'vehicle_model': vehicleModel,
      'plate_number': plateNumber,
      'total_safe_hours': totalSafeHours,
      'total_trips': totalTrips,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: (map['phone'] as String?) ?? '+7 (707) 123-45-67',
      vehicleModel: map['vehicle_model'] as String,
      plateNumber: map['plate_number'] as String,
      totalSafeHours: (map['total_safe_hours'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (map['total_trips'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  static UserModel current() {
    return UserModel(
      id: 'usr-789',
      fullName: 'Арман Жұмабаев',
      email: 'arman.driver@gmail.com',
      phone: '+7 (707) 123-45-67',
      vehicleModel: 'Toyota Camry 70',
      plateNumber: '02 KZ 777 AAA',
      totalSafeHours: 148.5,
      totalTrips: 62,
      createdAt: DateTime(2025, 1, 15),
    );
  }
}
