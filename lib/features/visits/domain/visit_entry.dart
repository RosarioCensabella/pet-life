enum VisitType {
  routine,
  vaccine,
  checkup,
  followUp,
  urgent,
  other,
}

class VisitEntry {
  const VisitEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.visitType,
    required this.reason,
    required this.visitDate,
    required this.createdAt,
    this.clinicName,
    this.outcome,
    this.nextVisitDate,
    this.notes,
  });

  final String id;
  final String petId;
  final String petName;
  final VisitType visitType;
  final String reason;
  final DateTime visitDate;
  final DateTime createdAt;
  final String? clinicName;
  final String? outcome;
  final DateTime? nextVisitDate;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'visitType': visitType.name,
      'reason': reason,
      'visitDate': visitDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'clinicName': clinicName,
      'outcome': outcome,
      'nextVisitDate': nextVisitDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory VisitEntry.fromJson(Map<String, dynamic> json) {
    return VisitEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      visitType: VisitType.values.byName(
        (json['visitType'] as String?) ?? VisitType.other.name,
      ),
      reason: json['reason'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      clinicName: json['clinicName'] as String?,
      outcome: json['outcome'] as String?,
      nextVisitDate: json['nextVisitDate'] == null
          ? null
          : DateTime.parse(json['nextVisitDate'] as String),
      notes: json['notes'] as String?,
    );
  }
}