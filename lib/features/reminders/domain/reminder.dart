enum ReminderCategory {
  vaccine,
  antiparasitic,
  vetVisit,
  checkup,
  medication,
  insurance,
  grooming,
  custom,
}

enum ReminderStatus {
  active,
  completed,
  postponed,
  skipped,
}

class Reminder {
  const Reminder({
    required this.id,
    required this.petId,
    required this.category,
    required this.title,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.notes,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String petId;
  final ReminderCategory category;
  final String title;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final DateTime createdAt;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  Reminder copyWith({
    String? id,
    String? petId,
    ReminderCategory? category,
    String? title,
    DateTime? scheduledAt,
    ReminderStatus? status,
    DateTime? createdAt,
    String? notes,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool clearNotes = false,
    bool clearCompletedAt = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      category: category ?? this.category,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: clearNotes ? null : notes ?? this.notes,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'category': category.name,
      'title': title,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final completedAtRaw = json['completedAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;

    return Reminder(
      id: json['id'] as String,
      petId: json['petId'] as String,
      category: ReminderCategory.values.byName(json['category'] as String),
      title: json['title'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: ReminderStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      completedAt:
          completedAtRaw == null ? null : DateTime.parse(completedAtRaw),
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
    );
  }
}