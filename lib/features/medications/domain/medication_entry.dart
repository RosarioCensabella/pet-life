enum MedicationStatus {
  active,
  completed,
  paused,
}

class MedicationReminderTime {
  const MedicationReminderTime({
    required this.id,
    required this.hour,
    required this.minute,
  });

  final String id;
  final int hour;
  final int minute;

  String get storageKey {
    final normalizedHour = hour.toString().padLeft(2, '0');
    final normalizedMinute = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$normalizedMinute';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
    };
  }

  factory MedicationReminderTime.fromJson(Map<String, dynamic> json) {
    return MedicationReminderTime(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }
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
    this.dosage,
    this.prescribedBy,
    this.instructions,
    this.notes,
    this.reminderTimes = const [],
    this.automaticReminderIds = const [],
    this.takenReminderIds = const [],
    this.suspendedAt,
    this.completedAt,
    this.updatedAt,
  });

  final String id;
  final String petId;
  final String petName;
  final String name;
  final MedicationStatus status;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime? endDate;
  final String? dosage;
  final String? prescribedBy;
  final String? instructions;
  final String? notes;
  final List<MedicationReminderTime> reminderTimes;
  final List<String> automaticReminderIds;
  final List<String> takenReminderIds;
  final DateTime? suspendedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  int get totalDoses => automaticReminderIds.length;

  int get takenDoses {
    final validTakenIds = takenReminderIds
        .where((id) => automaticReminderIds.contains(id))
        .toSet();

    return validTakenIds.length;
  }

  int get remainingDoses {
    final remaining = totalDoses - takenDoses;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isCompletedByProgress {
    return totalDoses > 0 && takenDoses >= totalDoses;
  }

  MedicationEntry copyWith({
    String? id,
    String? petId,
    String? petName,
    String? name,
    MedicationStatus? status,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? endDate,
    String? dosage,
    String? prescribedBy,
    String? instructions,
    String? notes,
    List<MedicationReminderTime>? reminderTimes,
    List<String>? automaticReminderIds,
    List<String>? takenReminderIds,
    DateTime? suspendedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    bool clearEndDate = false,
    bool clearDosage = false,
    bool clearPrescribedBy = false,
    bool clearInstructions = false,
    bool clearNotes = false,
    bool clearSuspendedAt = false,
    bool clearCompletedAt = false,
    bool clearUpdatedAt = false,
  }) {
    return MedicationEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      name: name ?? this.name,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      dosage: clearDosage ? null : dosage ?? this.dosage,
      prescribedBy: clearPrescribedBy ? null : prescribedBy ?? this.prescribedBy,
      instructions: clearInstructions ? null : instructions ?? this.instructions,
      notes: clearNotes ? null : notes ?? this.notes,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      automaticReminderIds: automaticReminderIds ?? this.automaticReminderIds,
      takenReminderIds: takenReminderIds ?? this.takenReminderIds,
      suspendedAt: clearSuspendedAt ? null : suspendedAt ?? this.suspendedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }

  MedicationEntry markReminderTaken(String reminderId, DateTime completedAt) {
    if (!automaticReminderIds.contains(reminderId)) {
      return this;
    }

    final nextTakenIds = {
      ...takenReminderIds,
      reminderId,
    }.toList(growable: false);

    final nextTakenCount = nextTakenIds
        .where((id) => automaticReminderIds.contains(id))
        .toSet()
        .length;

    final isNowCompleted =
        automaticReminderIds.isNotEmpty &&
        nextTakenCount >= automaticReminderIds.length;

    return copyWith(
      status: isNowCompleted ? MedicationStatus.completed : status,
      takenReminderIds: nextTakenIds,
      completedAt: isNowCompleted ? completedAt : this.completedAt,
      updatedAt: completedAt,
      clearSuspendedAt: status == MedicationStatus.paused,
    );
  }

  MedicationEntry markReminderNotTaken(String reminderId, DateTime updatedAt) {
    final nextTakenIds = takenReminderIds
        .where((id) => id != reminderId)
        .toList(growable: false);

    return copyWith(
      status: status == MedicationStatus.completed
          ? MedicationStatus.active
          : status,
      takenReminderIds: nextTakenIds,
      updatedAt: updatedAt,
      clearCompletedAt: true,
    );
  }

  Map<String, dynamic> toJson() {
    final firstReminderTime = reminderTimes.isEmpty ? null : reminderTimes.first;

    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'name': name,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dosage': dosage,
      'prescribedBy': prescribedBy,
      'instructions': instructions,
      'notes': notes,
      'reminderTimes': reminderTimes
          .map((reminderTime) => reminderTime.toJson())
          .toList(growable: false),
      'automaticReminderIds': automaticReminderIds,
      'takenReminderIds': takenReminderIds,
      'suspendedAt': suspendedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),

      // Legacy fields kept for older saved data.
      'reminderId': automaticReminderIds.isEmpty ? null : automaticReminderIds.first,
      'reminderScheduledAt': firstReminderTime == null
          ? null
          : DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
              firstReminderTime.hour,
              firstReminderTime.minute,
            ).toIso8601String(),
      'reminderTimeHour': firstReminderTime?.hour,
      'reminderTimeMinute': firstReminderTime?.minute,
    };
  }

  factory MedicationEntry.fromJson(Map<String, dynamic> json) {
    final startDate = DateTime.parse(json['startDate'] as String);
    final endDateRaw = json['endDate'] as String?;
    final suspendedAtRaw = json['suspendedAt'] as String?;
    final completedAtRaw = json['completedAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;

    final reminderTimes = _parseReminderTimes(
      json: json,
      startDate: startDate,
    );

    final automaticReminderIds = _parseAutomaticReminderIds(json);
    final takenReminderIds = _parseTakenReminderIds(json);

    return MedicationEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      name: json['name'] as String,
      status: MedicationStatus.values.byName(
        (json['status'] as String?) ?? MedicationStatus.active.name,
      ),
      startDate: startDate,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endDate: endDateRaw == null ? null : DateTime.parse(endDateRaw),
      dosage: json['dosage'] as String?,
      prescribedBy: json['prescribedBy'] as String?,
      instructions: json['instructions'] as String?,
      notes: json['notes'] as String?,
      reminderTimes: reminderTimes,
      automaticReminderIds: automaticReminderIds,
      takenReminderIds: takenReminderIds,
      suspendedAt: suspendedAtRaw == null ? null : DateTime.parse(suspendedAtRaw),
      completedAt: completedAtRaw == null ? null : DateTime.parse(completedAtRaw),
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
    );
  }

  static List<MedicationReminderTime> _parseReminderTimes({
    required Map<String, dynamic> json,
    required DateTime startDate,
  }) {
    final rawReminderTimes = json['reminderTimes'];

    if (rawReminderTimes is List && rawReminderTimes.isNotEmpty) {
      final parsed = rawReminderTimes
          .whereType<Map>()
          .map(
            (item) => MedicationReminderTime.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);

      if (parsed.isNotEmpty) {
        return _sortAndDeduplicateReminderTimes(parsed);
      }
    }

    final legacyHour = json['reminderTimeHour'];
    final legacyMinute = json['reminderTimeMinute'];

    if (legacyHour is int && legacyMinute is int) {
      return [
        MedicationReminderTime(
          id: 'legacy-$legacyHour-$legacyMinute',
          hour: legacyHour,
          minute: legacyMinute,
        ),
      ];
    }

    final fallbackHour = startDate.hour == 0 && startDate.minute == 0
        ? 9
        : startDate.hour;
    final fallbackMinute = startDate.hour == 0 && startDate.minute == 0
        ? 0
        : startDate.minute;

    return [
      MedicationReminderTime(
        id: 'fallback-$fallbackHour-$fallbackMinute',
        hour: fallbackHour,
        minute: fallbackMinute,
      ),
    ];
  }

  static List<String> _parseAutomaticReminderIds(Map<String, dynamic> json) {
    final rawAutomaticReminderIds = json['automaticReminderIds'];

    if (rawAutomaticReminderIds is List) {
      return rawAutomaticReminderIds
          .whereType<String>()
          .toList(growable: false);
    }

    final legacyReminderId = json['reminderId'];

    if (legacyReminderId is String && legacyReminderId.isNotEmpty) {
      return [legacyReminderId];
    }

    return const [];
  }

  static List<String> _parseTakenReminderIds(Map<String, dynamic> json) {
    final rawTakenReminderIds = json['takenReminderIds'];

    if (rawTakenReminderIds is List) {
      return rawTakenReminderIds
          .whereType<String>()
          .toList(growable: false);
    }

    return const [];
  }

  static List<MedicationReminderTime> _sortAndDeduplicateReminderTimes(
    List<MedicationReminderTime> reminderTimes,
  ) {
    final byStorageKey = <String, MedicationReminderTime>{};

    for (final reminderTime in reminderTimes) {
      byStorageKey[reminderTime.storageKey] = reminderTime;
    }

    final sorted = byStorageKey.values.toList(growable: false);

    sorted.sort((a, b) {
      final hourComparison = a.hour.compareTo(b.hour);

      if (hourComparison != 0) {
        return hourComparison;
      }

      return a.minute.compareTo(b.minute);
    });

    return sorted;
  }
}