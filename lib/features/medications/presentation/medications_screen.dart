import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../application/medication_controller.dart';
import '../domain/medication_entry.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  static const _notificationSchedulingWindowDays = 90;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();

  MedicationStatus _selectedStatus = MedicationStatus.active;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<TimeOfDay> _reminderTimes;

  MedicationEntry? _editingEntry;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final initialDateTime = DateTime.now().add(const Duration(hours: 1));

    _startDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );

    _reminderTimes = [
      TimeOfDay.fromDateTime(initialDateTime),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prescribedByController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = _MedicationStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final medicationState = ref.watch(medicationControllerProvider);

    return Scaffold(
      backgroundColor: _MedicationPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return _PetNotFoundState(strings: strings);
            }

            return medicationState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) {
                    final statusCompare = _statusWeight(a.status)
                        .compareTo(_statusWeight(b.status));

                    if (statusCompare != 0) {
                      return statusCompare;
                    }

                    return b.startDate.compareTo(a.startDate);
                  });

                final activeEntries = petEntries
                    .where((entry) => entry.status == MedicationStatus.active)
                    .toList(growable: false);

                final historyEntries = petEntries
                    .where((entry) => entry.status != MedicationStatus.active)
                    .toList(growable: false);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        title: strings.medicationsTitle,
                        subtitle: strings.medicationsSubtitle,
                        onBack: () => context.go('/pets/${pet.id}'),
                        onAdd: _scrollToForm,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        strings.inProgress,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              color: _MedicationPalette.darkText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (activeEntries.isEmpty)
                        _EmptyMedicationCard(strings: strings)
                      else
                        ...activeEntries.map(
                          (entry) => _MedicationTherapyCard(
                            entry: entry,
                            pet: pet,
                            strings: strings,
                            onSkip: () => _setStatus(
                              entry,
                              MedicationStatus.paused,
                            ),
                            onMarkTaken: () => _setStatus(
                              entry,
                              MedicationStatus.completed,
                            ),
                            onEdit: () => _startEditing(entry),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _DisclaimerCard(strings: strings),
                      if (historyEntries.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: strings.history,
                          count: historyEntries.length,
                        ),
                        const SizedBox(height: 8),
                        ...historyEntries.map(
                          (entry) => _MedicationTherapyCard(
                            entry: entry,
                            pet: pet,
                            strings: strings,
                            onSkip: () => _setStatus(
                              entry,
                              MedicationStatus.paused,
                            ),
                            onMarkTaken: () => _setStatus(
                              entry,
                              MedicationStatus.completed,
                            ),
                            onEdit: () => _startEditing(entry),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _MedicationFormCard(
                        formKey: _formKey,
                        nameController: _nameController,
                        prescribedByController: _prescribedByController,
                        instructionsController: _instructionsController,
                        notesController: _notesController,
                        selectedStatus: _selectedStatus,
                        startDate: _startDate,
                        endDate: _endDate,
                        reminderTimes: _reminderTimes,
                        strings: strings,
                        isSaving: _isSaving,
                        isEditing: _editingEntry != null,
                        onStatusChanged: (status) {
                          if (status == null) {
                            return;
                          }

                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                        onSelectStartDate: _selectStartDate,
                        onSelectEndDate: _selectEndDate,
                        onClearEndDate: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        onAddReminderTime: _addReminderTime,
                        onEditReminderTime: _editReminderTime,
                        onRemoveReminderTime: _removeReminderTime,
                        onSave: () => _saveEntry(pet, strings),
                        onCancelEditing: _cancelEditing,
                      ),
                      const SizedBox(height: 20),
                      if (petEntries.isNotEmpty)
                        _DangerDeleteArea(
                          entries: petEntries,
                          strings: strings,
                          onDelete: (entry) => _confirmDelete(entry, strings),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _statusWeight(MedicationStatus status) {
    return switch (status) {
      MedicationStatus.active => 0,
      MedicationStatus.paused => 1,
      MedicationStatus.completed => 2,
    };
  }

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      ),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  Future<void> _addReminderTime() async {
    final initialTime =
        _reminderTimes.isEmpty ? TimeOfDay.now() : _reminderTimes.last;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _reminderTimes = _sortAndDeduplicateTimes(
        [..._reminderTimes, pickedTime],
      );
    });
  }

  Future<void> _editReminderTime(int index) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final updatedTimes = [..._reminderTimes];
    updatedTimes[index] = pickedTime;

    setState(() {
      _reminderTimes = _sortAndDeduplicateTimes(updatedTimes);
    });
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length == 1) {
      return;
    }

    final updatedTimes = [..._reminderTimes]..removeAt(index);

    setState(() {
      _reminderTimes = _sortAndDeduplicateTimes(updatedTimes);
    });
  }

  Future<void> _saveEntry(Pet pet, _MedicationStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.reminderTimesRequired)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final wasEditing = _editingEntry != null;
      final medicationId =
          _editingEntry?.id ?? 'medication-${now.microsecondsSinceEpoch}';

      final medicationName = _nameController.text.trim();
      final prescribedBy = _prescribedByController.text.trim();
      final instructions = _instructionsController.text.trim();
      final notes = _notesController.text.trim();

      final reminderTimes = _reminderTimes.map((time) {
        return MedicationReminderTime(
          id: _reminderTimeId(time),
          hour: time.hour,
          minute: time.minute,
        );
      }).toList(growable: false);

      final reminders = _buildAutomaticReminders(
        medicationId: medicationId,
        medicationName: medicationName,
        pet: pet,
        strings: strings,
        reminderTimes: reminderTimes,
        prescribedBy: prescribedBy,
        instructions: instructions,
        notes: notes,
      );

      if (reminders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.reminderMustHaveFutureOccurrence)),
        );
        return;
      }

      final entry = MedicationEntry(
        id: medicationId,
        petId: pet.id,
        petName: pet.name,
        name: medicationName,
        status: _selectedStatus,
        startDate: _dateOnly(_startDate),
        endDate: _endDate == null ? null : _dateOnly(_endDate!),
        createdAt: _editingEntry?.createdAt ?? now,
        prescribedBy: prescribedBy.isEmpty ? null : prescribedBy,
        instructions: instructions.isEmpty ? null : instructions,
        notes: notes.isEmpty ? null : notes,
        reminderTimes: reminderTimes,
        automaticReminderIds:
            reminders.map((reminder) => reminder.id).toList(growable: false),
      );

      if (_editingEntry == null) {
        await ref.read(medicationControllerProvider.notifier).addEntry(entry);
      } else {
        for (final reminderId in _editingEntry!.automaticReminderIds) {
          await ref
              .read(reminderControllerProvider.notifier)
              .deleteReminder(reminderId);
        }

        await ref.read(medicationControllerProvider.notifier).updateEntry(entry);
      }

      for (final reminder in reminders) {
        await ref
            .read(reminderControllerProvider.notifier)
            .addReminder(reminder);
      }

      if (!mounted) {
        return;
      }

      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? strings.entryUpdatedWithReminders
                : strings.entrySavedWithReminders,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Reminder> _buildAutomaticReminders({
    required String medicationId,
    required String medicationName,
    required Pet pet,
    required _MedicationStrings strings,
    required List<MedicationReminderTime> reminderTimes,
    required String prescribedBy,
    required String instructions,
    required String notes,
  }) {
    final now = DateTime.now();
    final startDay = _dateOnly(_startDate);
    final maxScheduleEndDate = _dateOnly(
      now.add(const Duration(days: _notificationSchedulingWindowDays)),
    );

    final requestedEndDay =
        _endDate == null ? maxScheduleEndDate : _dateOnly(_endDate!);

    final scheduleEndDay = requestedEndDay.isAfter(maxScheduleEndDate)
        ? maxScheduleEndDate
        : requestedEndDay;

    final reminders = <Reminder>[];
    var currentDay = startDay;

    while (!currentDay.isAfter(scheduleEndDay)) {
      for (final reminderTime in reminderTimes) {
        final scheduledAt = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (!scheduledAt.isAfter(now)) {
          continue;
        }

        reminders.add(
          Reminder(
            id: _automaticReminderId(
              medicationId: medicationId,
              scheduledAt: scheduledAt,
              reminderTime: reminderTime,
            ),
            petId: pet.id,
            petName: pet.name,
            category: ReminderCategory.medication,
            title: strings.reminderTitleFor(medicationName),
            scheduledAt: scheduledAt,
            status: ReminderStatus.active,
            createdAt: now,
            notes: _buildReminderNotes(
              strings: strings,
              prescribedBy: prescribedBy,
              instructions: instructions,
              notes: notes,
            ),
          ),
        );
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  String _automaticReminderId({
    required String medicationId,
    required DateTime scheduledAt,
    required MedicationReminderTime reminderTime,
  }) {
    final dateKey =
        '${scheduledAt.year}${scheduledAt.month.toString().padLeft(2, '0')}${scheduledAt.day.toString().padLeft(2, '0')}';

    return '$medicationId-reminder-$dateKey-${reminderTime.storageKey}';
  }

  String? _buildReminderNotes({
    required _MedicationStrings strings,
    required String prescribedBy,
    required String instructions,
    required String notes,
  }) {
    final lines = [
      strings.reminderNoteHeader,
    ];

    if (prescribedBy.isNotEmpty) {
      lines.add('${strings.prescribedByShort}: $prescribedBy');
    }

    if (instructions.isNotEmpty) {
      lines.add('${strings.instructionsShort}: $instructions');
    }

    if (notes.isNotEmpty) {
      lines.add(notes);
    }

    return lines.join('\n');
  }

  void _startEditing(MedicationEntry entry) {
    setState(() {
      _editingEntry = entry;
      _nameController.text = entry.name;
      _selectedStatus = entry.status;
      _startDate = _dateOnly(entry.startDate);
      _endDate = entry.endDate == null ? null : _dateOnly(entry.endDate!);
      _prescribedByController.text = entry.prescribedBy ?? '';
      _instructionsController.text = entry.instructions ?? '';
      _notesController.text = entry.notes ?? '';

      _reminderTimes = _sortAndDeduplicateTimes(
        entry.reminderTimes
            .map(
              (reminderTime) => TimeOfDay(
                hour: reminderTime.hour,
                minute: reminderTime.minute,
              ),
            )
            .toList(growable: false),
      );

      if (_reminderTimes.isEmpty) {
        _reminderTimes = [TimeOfDay.now()];
      }
    });
  }

  void _cancelEditing() {
    setState(_clearForm);
  }

  void _clearForm() {
    _editingEntry = null;
    _nameController.clear();
    _prescribedByController.clear();
    _instructionsController.clear();
    _notesController.clear();

    final nextDefaultDateTime = DateTime.now().add(const Duration(hours: 1));

    _selectedStatus = MedicationStatus.active;

    _startDate = DateTime(
      nextDefaultDateTime.year,
      nextDefaultDateTime.month,
      nextDefaultDateTime.day,
    );

    _endDate = null;

    _reminderTimes = [
      TimeOfDay.fromDateTime(nextDefaultDateTime),
    ];
  }

  Future<void> _setStatus(
    MedicationEntry entry,
    MedicationStatus status,
  ) async {
    final updated = entry.copyWith(status: status);

    await ref.read(medicationControllerProvider.notifier).updateEntry(updated);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_MedicationStrings.of(context).entryUpdated)),
    );
  }

  Future<void> _confirmDelete(
    MedicationEntry entry,
    _MedicationStrings strings,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteEntryTitle),
          content: Text(strings.deleteEntryMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref.read(medicationControllerProvider.notifier).deleteEntry(entry.id);

    for (final reminderId in entry.automaticReminderIds) {
      await ref
          .read(reminderControllerProvider.notifier)
          .deleteReminder(reminderId);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  List<TimeOfDay> _sortAndDeduplicateTimes(List<TimeOfDay> times) {
    final byKey = <String, TimeOfDay>{};

    for (final time in times) {
      byKey[_timeKey(time)] = time;
    }

    final deduplicated = byKey.values.toList(growable: false)
      ..sort((a, b) {
        final first = a.hour * 60 + a.minute;
        final second = b.hour * 60 + b.minute;

        return first.compareTo(second);
      });

    return deduplicated;
  }

  String _timeKey(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _reminderTimeId(TimeOfDay time) {
    return 'time-${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToForm() {
    final contextToReveal = _formKey.currentContext;

    if (contextToReveal == null) {
      return;
    }

    Scrollable.ensureVisible(
      contextToReveal,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.chevron_left_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: _MedicationPalette.darkText,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MedicationPalette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.add_rounded,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MedicationPalette.chip,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: _MedicationPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _MedicationTherapyCard extends StatelessWidget {
  const _MedicationTherapyCard({
    required this.entry,
    required this.pet,
    required this.strings,
    required this.onSkip,
    required this.onMarkTaken,
    required this.onEdit,
  });

  final MedicationEntry entry;
  final Pet pet;
  final _MedicationStrings strings;
  final VoidCallback onSkip;
  final VoidCallback onMarkTaken;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final petColor = Color(pet.colorValue);
    final accent = _accentForPet(petColor);
    final progress = _therapyProgress(entry);
    final isActive = entry.status == MedicationStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _MedicationPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MedicationPalette.outline),
        boxShadow: [
          BoxShadow(
            color: _MedicationPalette.darkText.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TherapyHeader(
                    entry: entry,
                    pet: pet,
                    petColor: petColor,
                    strings: strings,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: _MedicationPalette.darkText,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _scheduleLine(context, entry, strings),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _MedicationPalette.secondaryText,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (entry.instructions != null &&
                      entry.instructions!.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      entry.instructions!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _MedicationPalette.mutedText,
                            height: 1.25,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (entry.notes != null &&
                      entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.notes!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _MedicationPalette.secondaryText,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.value,
                      minHeight: 5,
                      color: accent,
                      backgroundColor: _MedicationPalette.progressBackground,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        progress.leftLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _MedicationPalette.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        progress.rightLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _MedicationPalette.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _MedicationPalette.outline),
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  Expanded(
                    child: _TherapyActionButton(
                      label: strings.skip,
                      onTap: isActive ? onSkip : null,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: _MedicationPalette.outline,
                  ),
                  Expanded(
                    child: _TherapyActionButton(
                      label: strings.edit,
                      icon: Icons.edit_outlined,
                      onTap: onEdit,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: _MedicationPalette.outline,
                  ),
                  Expanded(
                    child: _TherapyActionButton(
                      label: strings.markTaken,
                      icon: Icons.check_rounded,
                      accent: accent,
                      onTap: isActive ? onMarkTaken : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentForPet(Color petColor) {
    if (petColor.computeLuminance() > 0.70) {
      return const Color(0xFFF3A83B);
    }

    return petColor;
  }

  String _scheduleLine(
    BuildContext context,
    MedicationEntry entry,
    _MedicationStrings strings,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final times = entry.reminderTimes.isEmpty
        ? strings.noReminderTimes
        : entry.reminderTimes
            .map(
              (time) => _formatHourMinute(time.hour, time.minute),
            )
            .join(', ');

    final start = DateFormat('d MMM', locale).format(entry.startDate);
    final end = entry.endDate == null
        ? strings.noEndDateShort
        : DateFormat('d MMM', locale).format(entry.endDate!);

    return '$times · ${strings.fromDate} $start ${strings.toDate} $end';
  }

  _TherapyProgress _therapyProgress(MedicationEntry entry) {
    final start = _dateOnly(entry.startDate);
    final today = _dateOnly(DateTime.now());

    if (entry.endDate == null) {
      final days = today.difference(start).inDays + 1;
      final normalized = (days / 30).clamp(0.08, 1.0);

      return _TherapyProgress(
        value: normalized,
        leftLabel: '${strings.day} ${days < 1 ? 1 : days}',
        rightLabel: strings.activeTherapy,
      );
    }

    final end = _dateOnly(entry.endDate!);
    final totalDays = end.difference(start).inDays + 1;
    final elapsedDays = today.difference(start).inDays + 1;
    final remainingDays = end.difference(today).inDays.clamp(0, totalDays);

    final safeTotal = totalDays <= 0 ? 1 : totalDays;
    final safeElapsed = elapsedDays.clamp(1, safeTotal);

    return _TherapyProgress(
      value: safeElapsed / safeTotal,
      leftLabel: '${strings.day} $safeElapsed ${strings.ofText} $safeTotal',
      rightLabel: '$remainingDays ${strings.daysRemaining}',
    );
  }
}

class _TherapyHeader extends StatelessWidget {
  const _TherapyHeader({
    required this.entry,
    required this.pet,
    required this.petColor,
    required this.strings,
  });

  final MedicationEntry entry;
  final Pet pet;
  final Color petColor;
  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    final prescribedBy = entry.prescribedBy?.trim();

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: petColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: petColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                pet.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: petColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        if (prescribedBy != null && prescribedBy.isNotEmpty) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              prescribedBy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _MedicationPalette.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
        const Spacer(),
        if (entry.status != MedicationStatus.active)
          Text(
            strings.statusLabelFor(entry.status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _MedicationPalette.mutedText,
                  fontWeight: FontWeight.w900,
                ),
          ),
      ],
    );
  }
}

class _TherapyActionButton extends StatelessWidget {
  const _TherapyActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final foreground = onTap == null
        ? _MedicationPalette.mutedText
        : accent ?? _MedicationPalette.secondaryText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: foreground,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedicationPalette.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MedicationPalette.warningBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: _MedicationPalette.warningIcon,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MedicationPalette.warningText,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationFormCard extends StatelessWidget {
  const _MedicationFormCard({
    required this.formKey,
    required this.nameController,
    required this.prescribedByController,
    required this.instructionsController,
    required this.notesController,
    required this.selectedStatus,
    required this.startDate,
    required this.endDate,
    required this.reminderTimes,
    required this.strings,
    required this.isSaving,
    required this.isEditing,
    required this.onStatusChanged,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.onClearEndDate,
    required this.onAddReminderTime,
    required this.onEditReminderTime,
    required this.onRemoveReminderTime,
    required this.onSave,
    required this.onCancelEditing,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController prescribedByController;
  final TextEditingController instructionsController;
  final TextEditingController notesController;
  final MedicationStatus selectedStatus;
  final DateTime startDate;
  final DateTime? endDate;
  final List<TimeOfDay> reminderTimes;
  final _MedicationStrings strings;
  final bool isSaving;
  final bool isEditing;
  final ValueChanged<MedicationStatus?> onStatusChanged;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onAddReminderTime;
  final ValueChanged<int> onEditReminderTime;
  final ValueChanged<int> onRemoveReminderTime;
  final VoidCallback onSave;
  final VoidCallback onCancelEditing;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startDateLabel = DateFormat.yMMMd(locale).format(startDate);
    final endDateLabel =
        endDate == null ? strings.noEndDate : DateFormat.yMMMd(locale).format(endDate!);

    return Container(
      decoration: BoxDecoration(
        color: _MedicationPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MedicationPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? strings.editEntry : strings.addEntry,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _MedicationPalette.darkText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.automaticReminderNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MedicationPalette.secondaryText,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.medicationNameLabel,
                  hintText: strings.medicationNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.medicationNameRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prescribedByController,
                decoration: InputDecoration(
                  labelText: strings.prescribedByLabel,
                  hintText: strings.prescribedByHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: instructionsController,
                decoration: InputDecoration(
                  labelText: strings.instructionsLabel,
                  hintText: strings.instructionsHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: strings.notesLabel,
                  hintText: strings.notesHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MedicationStatus>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: strings.statusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: MedicationStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(strings.statusLabelFor(status)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onStatusChanged,
              ),
              const SizedBox(height: 12),
              _DateButton(
                label: '${strings.startDate}: $startDateLabel',
                icon: Icons.event_outlined,
                onTap: onSelectStartDate,
              ),
              const SizedBox(height: 10),
              _DateButton(
                label: '${strings.endDate}: $endDateLabel',
                icon: Icons.event_available_outlined,
                onTap: onSelectEndDate,
              ),
              if (endDate != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onClearEndDate,
                    icon: const Icon(Icons.close_outlined),
                    label: Text(strings.clearEndDate),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _ReminderTimesEditor(
                reminderTimes: reminderTimes,
                strings: strings,
                onAdd: onAddReminderTime,
                onEdit: onEditReminderTime,
                onRemove: onRemoveReminderTime,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isEditing ? strings.updateEntry : strings.saveEntry,
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onCancelEditing,
                  child: Text(strings.cancelEditing),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ReminderTimesEditor extends StatelessWidget {
  const _ReminderTimesEditor({
    required this.reminderTimes,
    required this.strings,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<TimeOfDay> reminderTimes;
  final _MedicationStrings strings;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedicationPalette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _MedicationPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.reminderTimesTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _MedicationPalette.darkText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.reminderTimesDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MedicationPalette.secondaryText,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < reminderTimes.length; index++)
                  _ReminderTimeChip(
                    label: reminderTimes[index].format(context),
                    canRemove: reminderTimes.length > 1,
                    onTap: () => onEdit(index),
                    onRemove: () => onRemove(index),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(strings.addTime),
                  onPressed: onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTimeChip extends StatelessWidget {
  const _ReminderTimeChip({
    required this.label,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      avatar: const Icon(Icons.notifications_active_outlined, size: 18),
      onPressed: onTap,
      onDeleted: canRemove ? onRemove : null,
    );
  }
}

class _EmptyMedicationCard extends StatelessWidget {
  const _EmptyMedicationCard({
    required this.strings,
  });

  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedicationPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MedicationPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 42,
              color: _MedicationPalette.secondaryText,
            ),
            const SizedBox(height: 14),
            Text(
              strings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _MedicationPalette.darkText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              strings.emptyDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MedicationPalette.secondaryText,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerDeleteArea extends StatelessWidget {
  const _DangerDeleteArea({
    required this.entries,
    required this.strings,
    required this.onDelete,
  });

  final List<MedicationEntry> entries;
  final _MedicationStrings strings;
  final ValueChanged<MedicationEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedicationPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MedicationPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.manageEntries,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _MedicationPalette.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            ...entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${entry.name} · ${strings.statusLabelFor(entry.status)}',
                ),
                trailing: IconButton(
                  tooltip: strings.delete,
                  onPressed: () => onDelete(entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _MedicationPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _MedicationPalette.secondaryText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _PetNotFoundState extends StatelessWidget {
  const _PetNotFoundState({
    required this.strings,
  });

  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          strings.petNotFound,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _MedicationPalette.darkText),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _MedicationPalette.darkText),
        ),
      ),
    );
  }
}

class _TherapyProgress {
  const _TherapyProgress({
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
  });

  final double value;
  final String leftLabel;
  final String rightLabel;
}

class _MedicationPalette {
  const _MedicationPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF3E8D1);
  static const outline = Color(0xFFE3D2B4);
  static const progressBackground = Color(0xFFF1E4C9);

  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);
  static const mutedText = Color(0xFFAD9D87);

  static const warningBackground = Color(0xFFFFEBD8);
  static const warningBorder = Color(0xFFF2C7A4);
  static const warningIcon = Color(0xFFE4773D);
  static const warningText = Color(0xFF8A5E41);
}

class _MedicationStrings {
  const _MedicationStrings({
    required this.medicationsTitle,
    required this.medicationsSubtitle,
    required this.inProgress,
    required this.history,
    required this.addEntry,
    required this.editEntry,
    required this.medicationNameLabel,
    required this.medicationNameHint,
    required this.medicationNameRequired,
    required this.statusLabel,
    required this.statusActive,
    required this.statusCompleted,
    required this.statusPaused,
    required this.startDate,
    required this.endDate,
    required this.fromDate,
    required this.toDate,
    required this.noEndDate,
    required this.noEndDateShort,
    required this.clearEndDate,
    required this.prescribedByLabel,
    required this.prescribedByHint,
    required this.prescribedByShort,
    required this.instructionsLabel,
    required this.instructionsHint,
    required this.instructionsShort,
    required this.notesLabel,
    required this.notesHint,
    required this.reminderTimesTitle,
    required this.reminderTimesDescription,
    required this.addTime,
    required this.noReminderTimes,
    required this.reminderTimesRequired,
    required this.reminderMustHaveFutureOccurrence,
    required this.automaticReminderNote,
    required this.saveEntry,
    required this.updateEntry,
    required this.cancelEditing,
    required this.entrySavedWithReminders,
    required this.entryUpdatedWithReminders,
    required this.entryUpdated,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.manageEntries,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
    required this.reminderNoteHeader,
    required this.skip,
    required this.edit,
    required this.markTaken,
    required this.day,
    required this.ofText,
    required this.daysRemaining,
    required this.activeTherapy,
  });

  final String medicationsTitle;
  final String medicationsSubtitle;
  final String inProgress;
  final String history;
  final String addEntry;
  final String editEntry;
  final String medicationNameLabel;
  final String medicationNameHint;
  final String medicationNameRequired;
  final String statusLabel;
  final String statusActive;
  final String statusCompleted;
  final String statusPaused;
  final String startDate;
  final String endDate;
  final String fromDate;
  final String toDate;
  final String noEndDate;
  final String noEndDateShort;
  final String clearEndDate;
  final String prescribedByLabel;
  final String prescribedByHint;
  final String prescribedByShort;
  final String instructionsLabel;
  final String instructionsHint;
  final String instructionsShort;
  final String notesLabel;
  final String notesHint;
  final String reminderTimesTitle;
  final String reminderTimesDescription;
  final String addTime;
  final String noReminderTimes;
  final String reminderTimesRequired;
  final String reminderMustHaveFutureOccurrence;
  final String automaticReminderNote;
  final String saveEntry;
  final String updateEntry;
  final String cancelEditing;
  final String entrySavedWithReminders;
  final String entryUpdatedWithReminders;
  final String entryUpdated;
  final String emptyTitle;
  final String emptyDescription;
  final String manageEntries;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;
  final String reminderNoteHeader;
  final String skip;
  final String edit;
  final String markTaken;
  final String day;
  final String ofText;
  final String daysRemaining;
  final String activeTherapy;

  String statusLabelFor(MedicationStatus status) {
    return switch (status) {
      MedicationStatus.active => statusActive,
      MedicationStatus.completed => statusCompleted,
      MedicationStatus.paused => statusPaused,
    };
  }

  String reminderTitleFor(String medicationName) {
    return 'Farmaco: $medicationName';
  }

  static _MedicationStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _MedicationStrings(
        medicationsTitle: 'Medications',
        medicationsSubtitle: 'Active therapies and history',
        inProgress: 'In progress',
        history: 'History',
        addEntry: 'Add medication',
        editEntry: 'Edit medication',
        medicationNameLabel: 'Medication name',
        medicationNameHint: 'E.g. antibiotic',
        medicationNameRequired: 'Enter the medication name',
        statusLabel: 'Status',
        statusActive: 'Active',
        statusCompleted: 'Completed',
        statusPaused: 'Paused',
        startDate: 'Start date',
        endDate: 'End date',
        fromDate: 'from',
        toDate: 'to',
        noEndDate: 'Not set',
        noEndDateShort: 'not set',
        clearEndDate: 'Clear end date',
        prescribedByLabel: 'Veterinarian / prescriber',
        prescribedByHint: 'Optional',
        prescribedByShort: 'Vet',
        instructionsLabel: 'Veterinarian instructions',
        instructionsHint:
            'Optional. Enter only instructions provided by your veterinarian.',
        instructionsShort: 'Instructions',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        reminderTimesTitle: 'Daily reminder times',
        reminderTimesDescription:
            'Set one or more daily times for personal alerts.',
        addTime: 'Add time',
        noReminderTimes: 'No times',
        reminderTimesRequired: 'Add at least one reminder time',
        reminderMustHaveFutureOccurrence:
            'Set at least one future reminder occurrence',
        automaticReminderNote:
            'Pet Life crea promemoria giornalieri automatici per questi orari. Serve solo a ricordare informazioni inserite da te.',
        saveEntry: 'Save medication',
        updateEntry: 'Update medication',
        cancelEditing: 'Cancel editing',
        entrySavedWithReminders: 'Medication saved and reminders created',
        entryUpdatedWithReminders: 'Medication updated and reminders recreated',
        entryUpdated: 'Medication updated',
        emptyTitle: 'No medications',
        emptyDescription:
            'Add medications only as a personal record of information provided by your veterinarian.',
        manageEntries: 'Manage entries',
        deleteEntryTitle: 'Delete this medication?',
        deleteEntryMessage:
            'This removes the medication entry and its automatic reminders.',
        entryDeleted: 'Medication deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Pet Life helps you remember therapies. Dosage, duration and medication are decided only by your veterinarian. Pet Life does not prescribe medications, suggest treatments or calculate dosages.',
        reminderNoteHeader:
            'Automatic reminder generated from a medication therapy.',
        skip: 'Skip',
        edit: 'Edit',
        markTaken: 'Mark taken',
        day: 'Day',
        ofText: 'of',
        daysRemaining: 'days left',
        activeTherapy: 'active therapy',
      );
    }

    return const _MedicationStrings(
      medicationsTitle: 'Farmaci',
      medicationsSubtitle: 'Terapie attive e storico',
      inProgress: 'In corso',
      history: 'Storico',
      addEntry: 'Aggiungi farmaco',
      editEntry: 'Modifica farmaco',
      medicationNameLabel: 'Nome farmaco',
      medicationNameHint: 'Es. Antibiotico',
      medicationNameRequired: 'Inserisci il nome del farmaco',
      statusLabel: 'Stato',
      statusActive: 'Attivo',
      statusCompleted: 'Completato',
      statusPaused: 'Sospeso',
      startDate: 'Data inizio',
      endDate: 'Data fine',
      fromDate: 'dal',
      toDate: 'al',
      noEndDate: 'Non impostata',
      noEndDateShort: 'non impostata',
      clearEndDate: 'Rimuovi data fine',
      prescribedByLabel: 'Veterinario / prescrittore',
      prescribedByHint: 'Opzionale',
      prescribedByShort: 'Vet',
      instructionsLabel: 'Indicazioni del veterinario',
      instructionsHint:
          'Opzionale. Inserisci solo indicazioni fornite dal veterinario.',
      instructionsShort: 'Indicazioni',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      reminderTimesTitle: 'Orari giornalieri promemoria',
      reminderTimesDescription:
          'Imposta uno o più orari al giorno per ricevere avvisi.',
      addTime: 'Aggiungi orario',
      noReminderTimes: 'Nessun orario',
      reminderTimesRequired: 'Aggiungi almeno un orario promemoria',
      reminderMustHaveFutureOccurrence: 'Imposta almeno un promemoria futuro',
      automaticReminderNote:
          'Pet Life crea promemoria giornalieri automatici per questi orari. Serve solo a ricordare informazioni inserite da te.',
      saveEntry: 'Salva farmaco',
      updateEntry: 'Aggiorna farmaco',
      cancelEditing: 'Annulla modifica',
      entrySavedWithReminders: 'Farmaco salvato e promemoria creati',
      entryUpdatedWithReminders: 'Farmaco aggiornato e promemoria ricreati',
      entryUpdated: 'Farmaco aggiornato',
      emptyTitle: 'Nessun farmaco',
      emptyDescription:
          'Aggiungi farmaci solo come registro personale delle informazioni fornite dal veterinario.',
      manageEntries: 'Gestisci farmaci',
      deleteEntryTitle: 'Eliminare questo farmaco?',
      deleteEntryMessage:
          'Il farmaco e i suoi promemoria automatici verranno rimossi.',
      entryDeleted: 'Farmaco eliminato',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Pet Life ti aiuta a ricordare le terapie. Dosi, durata e farmaci li decide solo il veterinario. Pet Life non prescrive farmaci, non suggerisce terapie e non calcola dosaggi.',
      reminderNoteHeader:
          'Promemoria automatico generato da una terapia farmacologica.',
      skip: 'Salta',
      edit: 'Modifica',
      markTaken: 'Segna presa',
      day: 'Giorno',
      ofText: 'di',
      daysRemaining: 'giorni rimasti',
      activeTherapy: 'terapia attiva',
    );
  }
}

String _formatHourMinute(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}