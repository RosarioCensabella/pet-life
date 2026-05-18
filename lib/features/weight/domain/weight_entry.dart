class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.weightKg,
    required this.recordedAt,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String petId;
  final String petName;
  final double weightKg;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'weightKg': weightKg,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      weightKg: (json['weightKg'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}