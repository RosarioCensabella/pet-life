enum MedicationStatus {
  active,
  completed,
  paused,
}

class MedicationEntry {
  const MedicationEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.name,
    required this.status,
    required this.startDate,
    required this.createdAt,
    this.endDate,
    this.prescribedBy,
    this.instructions,
    this.notes,
  });

  final String id;
  final String petId;
  final String petName;
  final String name;
  final MedicationStatus status;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? instructions;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'name': name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'prescribedBy': prescribedBy,
      'instructions': instructions,
      'notes': notes,
    };
  }

  factory MedicationEntry.fromJson(Map<String, dynamic> json) {
    return MedicationEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      name: json['name'] as String,
      status: MedicationStatus.values.byName(
        (json['status'] as String?) ?? MedicationStatus.active.name,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      prescribedBy: json['prescribedBy'] as String?,
      instructions: json['instructions'] as String?,
      notes: json['notes'] as String?,
    );
  }
}