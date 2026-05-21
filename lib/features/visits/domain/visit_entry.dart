enum VisitType {
  routine,
  vaccine,
  checkup,
  followUp,
  urgent,
  other,
}

enum VisitStatus {
  scheduled,
  completed,
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
    this.status = VisitStatus.scheduled,
    this.clinicName,
    this.doctorName,
    this.outcome,
    this.nextVisitDate,
    this.notes,
    this.amount,
    this.currency = 'EUR',
    this.expenseEntryId,
    this.reportDocumentId,
    this.completedAt,
    this.addToCalendar = false,
    this.automaticReminderIds = const [],
    this.updatedAt,
  });

  final String id;
  final String petId;
  final String petName;
  final VisitType visitType;
  final String reason;
  final DateTime visitDate;
  final DateTime createdAt;
  final VisitStatus status;
  final String? clinicName;
  final String? doctorName;
  final String? outcome;
  final DateTime? nextVisitDate;
  final String? notes;
  final double? amount;
  final String currency;
  final String? expenseEntryId;
  final String? reportDocumentId;
  final DateTime? completedAt;
  final bool addToCalendar;
  final List<String> automaticReminderIds;
  final DateTime? updatedAt;

  bool get isCompleted => status == VisitStatus.completed;
  bool get isScheduled => status == VisitStatus.scheduled;

  VisitEntry copyWith({
    String? id,
    String? petId,
    String? petName,
    VisitType? visitType,
    String? reason,
    DateTime? visitDate,
    DateTime? createdAt,
    VisitStatus? status,
    String? clinicName,
    String? doctorName,
    String? outcome,
    DateTime? nextVisitDate,
    String? notes,
    double? amount,
    String? currency,
    String? expenseEntryId,
    String? reportDocumentId,
    DateTime? completedAt,
    bool? addToCalendar,
    List<String>? automaticReminderIds,
    DateTime? updatedAt,
    bool clearClinicName = false,
    bool clearDoctorName = false,
    bool clearOutcome = false,
    bool clearNextVisitDate = false,
    bool clearNotes = false,
    bool clearAmount = false,
    bool clearExpenseEntryId = false,
    bool clearReportDocumentId = false,
    bool clearCompletedAt = false,
  }) {
    return VisitEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      visitType: visitType ?? this.visitType,
      reason: reason ?? this.reason,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      clinicName: clearClinicName ? null : clinicName ?? this.clinicName,
      doctorName: clearDoctorName ? null : doctorName ?? this.doctorName,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      nextVisitDate:
          clearNextVisitDate ? null : nextVisitDate ?? this.nextVisitDate,
      notes: clearNotes ? null : notes ?? this.notes,
      amount: clearAmount ? null : amount ?? this.amount,
      currency: currency ?? this.currency,
      expenseEntryId:
          clearExpenseEntryId ? null : expenseEntryId ?? this.expenseEntryId,
      reportDocumentId:
          clearReportDocumentId ? null : reportDocumentId ?? this.reportDocumentId,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      automaticReminderIds:
          automaticReminderIds ?? this.automaticReminderIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'visitType': visitType.name,
      'reason': reason,
      'visitDate': visitDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'clinicName': clinicName,
      'doctorName': doctorName,
      'outcome': outcome,
      'nextVisitDate': nextVisitDate?.toIso8601String(),
      'notes': notes,
      'amount': amount,
      'currency': currency,
      'expenseEntryId': expenseEntryId,
      'reportDocumentId': reportDocumentId,
      'completedAt': completedAt?.toIso8601String(),
      'addToCalendar': addToCalendar,
      'automaticReminderIds': automaticReminderIds,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VisitEntry.fromJson(Map<String, Object?> json) {
    final visitDate = DateTime.parse(json['visitDate'] as String);
    final nextVisitDateRaw = json['nextVisitDate'] as String?;
    final completedAtRaw = json['completedAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;
    final automaticReminderIdsRaw = json['automaticReminderIds'];

    final parsedAutomaticReminderIds =
        automaticReminderIdsRaw is List
            ? automaticReminderIdsRaw.whereType<String>().toList(growable: false)
            : const <String>[];

    final statusRaw = json['status'] as String?;

    return VisitEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      visitType: VisitType.values.byName(
        (json['visitType'] as String?) ?? VisitType.other.name,
      ),
      reason: json['reason'] as String,
      visitDate: visitDate,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: statusRaw == null
          ? (visitDate.isBefore(DateTime.now())
              ? VisitStatus.completed
              : VisitStatus.scheduled)
          : VisitStatus.values.byName(statusRaw),
      clinicName: json['clinicName'] as String?,
      doctorName: json['doctorName'] as String?,
      outcome: json['outcome'] as String?,
      nextVisitDate:
          nextVisitDateRaw == null ? null : DateTime.parse(nextVisitDateRaw),
      notes: json['notes'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'EUR',
      expenseEntryId: json['expenseEntryId'] as String?,
      reportDocumentId: json['reportDocumentId'] as String?,
      completedAt:
          completedAtRaw == null ? null : DateTime.parse(completedAtRaw),
      addToCalendar: (json['addToCalendar'] as bool?) ?? false,
      automaticReminderIds: parsedAutomaticReminderIds,
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
    );
  }
}