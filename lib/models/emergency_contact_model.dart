class EmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String relationship; // 'Жұбайы', 'Әкесі', 'Анасы', 'Досы'
  final bool isPrimary;

  const EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = true,
  });

  EmergencyContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'is_primary': isPrimary ? 1 : 0,
    };
  }

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      relationship: map['relationship'] as String,
      isPrimary: (map['is_primary'] as int? ?? 1) == 1,
    );
  }
}

