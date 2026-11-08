class VehicleModel {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final String plateNumber;
  final int year;
  final bool isDefault;

  const VehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.year,
    this.isDefault = true,
  });

  String get displayName => '$brand $model ($year)';

  VehicleModel copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    String? plateNumber,
    int? year,
    bool? isDefault,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      year: year ?? this.year,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'model': model,
      'plate_number': plateNumber,
      'year': year,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      plateNumber: map['plate_number'] as String,
      year: (map['year'] as num).toInt(),
      isDefault: (map['is_default'] as int? ?? 1) == 1,
    );
  }
}

