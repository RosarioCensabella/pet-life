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
    this.prescribedBy,
    this.instructions,
    this.notes,
    this.reminderTimes = const [],
    this.automaticReminderIds = const [],
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
  final List<MedicationReminderTime> reminderTimes;
  final List<String> automaticReminderIds;

  MedicationEntry copyWith({
    String? id,
    String? petId,
    String? petName,
    String? name,
    MedicationStatus? status,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? endDate,
    String? prescribedBy,
    String? instructions,
    String? notes,
    List<MedicationReminderTime>? reminderTimes,
    List<String>? automaticReminderIds,
    bool clearEndDate = false,
    bool clearPrescribedBy = false,
    bool clearInstructions = false,
    bool clearNotes = false,
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
      prescribedBy:
          clearPrescribedBy ? null : prescribedBy ?? this.prescribedBy,
      instructions:
          clearInstructions ? null : instructions ?? this.instructions,
      notes: clearNotes ? null : notes ?? this.notes,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      automaticReminderIds:
          automaticReminderIds ?? this.automaticReminderIds,
    );
  }

  Map<String, dynamic> toJson() {
    final firstReminderTime =
        reminderTimes.isEmpty ? null : reminderTimes.first;

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
      'reminderTimes': reminderTimes
          .map((reminderTime) => reminderTime.toJson())
          .toList(growable: false),
      'automaticReminderIds': automaticReminderIds,
      'reminderId':
          automaticReminderIds.isEmpty ? null : automaticReminderIds.first,
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

    final reminderTimes = _parseReminderTimes(
      json: json,
      startDate: startDate,
    );

    final automaticReminderIds = _parseAutomaticReminderIds(json);

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
      prescribedBy: json['prescribedBy'] as String?,
      instructions: json['instructions'] as String?,
      notes: json['notes'] as String?,
      reminderTimes: reminderTimes,
      automaticReminderIds: automaticReminderIds,
    );
  }

  static List<MedicationReminderTime> _parseReminderTimes({
    required Map<String, dynamic> json,
    required DateTime startDate,
  }) {
    final rawReminderTimes = json['reminderTimes'];

    if (rawReminderTimes is List<dynamic> && rawReminderTimes.isNotEmpty) {
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

    if (rawAutomaticReminderIds is List<dynamic>) {
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