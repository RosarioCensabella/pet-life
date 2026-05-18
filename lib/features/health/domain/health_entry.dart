enum HealthEntryType {
  diary,
  symptom,
}

enum SymptomIntensity {
  mild,
  moderate,
  high,
}

class HealthEntry {
  const HealthEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.type,
    required this.title,
    required this.recordedAt,
    required this.createdAt,
    this.notes,
    this.symptomIntensity,
  });

  final String id;
  final String petId;
  final String petName;
  final HealthEntryType type;
  final String title;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? notes;
  final SymptomIntensity? symptomIntensity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'type': type.name,
      'title': title,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'symptomIntensity': symptomIntensity?.name,
    };
  }

  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      type: HealthEntryType.values.byName(
        (json['type'] as String?) ?? HealthEntryType.diary.name,
      ),
      title: json['title'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      symptomIntensity: json['symptomIntensity'] == null
          ? null
          : SymptomIntensity.values.byName(json['symptomIntensity'] as String),
    );
  }
}