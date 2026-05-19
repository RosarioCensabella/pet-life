import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final initialTime = _reminderTimes.isEmpty
        ? TimeOfDay.now()
        : _reminderTimes.last;

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

    if (!isValid || _isSaving) {
      return;
    }

    if (_reminderTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.atLeastOneReminderTime)),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
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
        automaticReminderIds: reminders
            .map((reminder) => reminder.id)
            .toList(growable: false),
      );

      if (_editingEntry == null) {
        await ref.read(medicationControllerProvider.notifier).addEntry(entry);
      } else {
        for (final reminderId in _editingEntry!.automaticReminderIds) {
          await ref.read(reminderControllerProvider.notifier).deleteReminder(
                reminderId,
              );
        }

        await ref.read(medicationControllerProvider.notifier).updateEntry(entry);
      }

      for (final reminder in reminders) {
        await ref.read(reminderControllerProvider.notifier).addReminder(
              reminder,
            );
      }

      if (!mounted) {
        return;
      }

      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingEntry == null
                ? strings.entrySavedWithReminders
                : strings.entryUpdatedWithReminders,
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
    final lines = <String>[
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
      await ref.read(reminderControllerProvider.notifier).deleteReminder(
            reminderId,
          );
    }

    if (!mounted) {
      return;
    }

    if (_editingEntry?.id == entry.id) {
      _clearForm();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  String _reminderTimeId(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}';
  }

  List<TimeOfDay> _sortAndDeduplicateTimes(List<TimeOfDay> times) {
    final byKey = <String, TimeOfDay>{};

    for (final time in times) {
      byKey[_reminderTimeId(time)] = time;
    }

    final sorted = byKey.values.toList(growable: false);

    sorted.sort((a, b) {
      final hourComparison = a.hour.compareTo(b.hour);

      if (hourComparison != 0) {
        return hourComparison;
      }

      return a.minute.compareTo(b.minute);
    });

    return sorted;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  Widget build(BuildContext context) {
    final strings = _MedicationStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final medicationState = ref.watch(medicationControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.medicationsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.medicationsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (pets) {
        final pet = _findPet(pets, widget.petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.medicationsTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.petNotFound),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.medicationsTitle),
          ),
          body: medicationState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (entries) {
              final petEntries = entries
                  .where((entry) => entry.petId == pet.id)
                  .toList(growable: false);

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _DisclaimerCard(strings: strings),
                  _AddMedicationEntryCard(
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
                  if (petEntries.isEmpty)
                    _EmptyMedicationCard(strings: strings)
                  else
                    ...petEntries.map(
                      (entry) => _MedicationEntryCard(
                        entry: entry,
                        strings: strings,
                        onEdit: () => _startEditing(entry),
                        onDelete: () => _confirmDelete(entry, strings),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(strings.disclaimer),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicationEntryCard extends StatelessWidget {
  const _AddMedicationEntryCard({
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
    final endDateLabel = endDate == null
        ? strings.noEndDate
        : DateFormat.yMMMd(locale).format(endDate!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? strings.editEntry : strings.addEntry,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
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
              OutlinedButton.icon(
                onPressed: onSelectStartDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('${strings.startDate}: $startDateLabel'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectEndDate,
                icon: const Icon(Icons.event_available_outlined),
                label: Text('${strings.endDate}: $endDateLabel'),
              ),
              if (endDate != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onClearEndDate,
                  icon: const Icon(Icons.close_outlined),
                  label: Text(strings.clearEndDate),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                strings.dailyReminderTimes,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.automaticReminderDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...reminderTimes.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final time = entry.value;

                      return InputChip(
                        label: Text(time.format(context)),
                        avatar: const Icon(Icons.schedule_outlined),
                        onPressed: () => onEditReminderTime(index),
                        onDeleted: reminderTimes.length == 1
                            ? null
                            : () => onRemoveReminderTime(index),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add),
                    label: Text(strings.addReminderTime),
                    onPressed: onAddReminderTime,
                  ),
                ],
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isEditing ? strings.updateEntry : strings.saveEntry),
              ),
              if (isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onCancelEditing,
                  icon: const Icon(Icons.close_outlined),
                  label: Text(strings.cancelEdit),
                ),
              ],
            ],
          ),
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.emptyDescription,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationEntryCard extends StatelessWidget {
  const _MedicationEntryCard({
    required this.entry,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationEntry entry;
  final _MedicationStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startLabel = DateFormat.yMMMd(locale).format(entry.startDate);
    final endLabel = entry.endDate == null
        ? null
        : DateFormat.yMMMd(locale).format(entry.endDate!);
    final dateText = endLabel == null
        ? '${strings.startDate}: $startLabel'
        : '${strings.startDate}: $startLabel · ${strings.endDate}: $endLabel';
    final reminderTimesText = entry.reminderTimes
        .map(
          (reminderTime) => TimeOfDay(
            hour: reminderTime.hour,
            minute: reminderTime.minute,
          ).format(context),
        )
        .join(' · ');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text(entry.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.statusLabel}: ${strings.statusLabelFor(entry.status)}'),
            Text(dateText),
            Text('${strings.dailyReminderTimes}: $reminderTimesText'),
            if (entry.prescribedBy != null &&
                entry.prescribedBy!.trim().isNotEmpty)
              Text('${strings.prescribedByShort}: ${entry.prescribedBy!}'),
            if (entry.instructions != null &&
                entry.instructions!.trim().isNotEmpty)
              Text('${strings.instructionsShort}: ${entry.instructions!}'),
            if (entry.notes != null && entry.notes!.trim().isNotEmpty)
              Text(entry.notes!),
          ],
        ),
        trailing: SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: strings.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: strings.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationStrings {
  const _MedicationStrings({
    required this.medicationsTitle,
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
    required this.noEndDate,
    required this.clearEndDate,
    required this.dailyReminderTimes,
    required this.addReminderTime,
    required this.automaticReminderDescription,
    required this.atLeastOneReminderTime,
    required this.reminderMustHaveFutureOccurrence,
    required this.prescribedByLabel,
    required this.prescribedByHint,
    required this.prescribedByShort,
    required this.instructionsLabel,
    required this.instructionsHint,
    required this.instructionsShort,
    required this.notesLabel,
    required this.notesHint,
    required this.saveEntry,
    required this.updateEntry,
    required this.cancelEdit,
    required this.entrySavedWithReminders,
    required this.entryUpdatedWithReminders,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.edit,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
    required this.reminderNoteHeader,
    required this.takeMedicationReminderPrefix,
  });

  final String medicationsTitle;
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
  final String noEndDate;
  final String clearEndDate;
  final String dailyReminderTimes;
  final String addReminderTime;
  final String automaticReminderDescription;
  final String atLeastOneReminderTime;
  final String reminderMustHaveFutureOccurrence;
  final String prescribedByLabel;
  final String prescribedByHint;
  final String prescribedByShort;
  final String instructionsLabel;
  final String instructionsHint;
  final String instructionsShort;
  final String notesLabel;
  final String notesHint;
  final String saveEntry;
  final String updateEntry;
  final String cancelEdit;
  final String entrySavedWithReminders;
  final String entryUpdatedWithReminders;
  final String emptyTitle;
  final String emptyDescription;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String edit;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;
  final String reminderNoteHeader;
  final String takeMedicationReminderPrefix;

  String statusLabelFor(MedicationStatus status) {
    return switch (status) {
      MedicationStatus.active => statusActive,
      MedicationStatus.completed => statusCompleted,
      MedicationStatus.paused => statusPaused,
    };
  }

  String reminderTitleFor(String medicationName) {
    return '$takeMedicationReminderPrefix $medicationName';
  }

  static _MedicationStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _MedicationStrings(
        medicationsTitle: 'Medications',
        addEntry: 'Add medication',
        editEntry: 'Edit medication',
        medicationNameLabel: 'Medication name',
        medicationNameHint: 'E.g. Antibiotic',
        medicationNameRequired: 'Enter the medication name',
        statusLabel: 'Status',
        statusActive: 'Active',
        statusCompleted: 'Completed',
        statusPaused: 'Paused',
        startDate: 'Start date',
        endDate: 'End date',
        noEndDate: 'Not set',
        clearEndDate: 'Clear end date',
        dailyReminderTimes: 'Daily reminder times',
        addReminderTime: 'Add time',
        automaticReminderDescription:
            'Pet Life creates automatic daily medication reminders for these times. This only reminds you of information entered by you.',
        atLeastOneReminderTime: 'Add at least one reminder time.',
        reminderMustHaveFutureOccurrence:
            'Choose a date range with at least one future reminder.',
        prescribedByLabel: 'Veterinarian / prescriber',
        prescribedByHint: 'Optional',
        prescribedByShort: 'Vet',
        instructionsLabel: 'Veterinarian instructions',
        instructionsHint:
            'Optional. Enter only instructions provided by your veterinarian.',
        instructionsShort: 'Instructions',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save medication',
        updateEntry: 'Update medication',
        cancelEdit: 'Cancel edit',
        entrySavedWithReminders: 'Medication saved and reminders created',
        entryUpdatedWithReminders: 'Medication updated and reminders refreshed',
        emptyTitle: 'No medications',
        emptyDescription:
            'Add medications only as a personal record of information provided by your veterinarian.',
        deleteEntryTitle: 'Delete this medication?',
        deleteEntryMessage:
            'This removes the medication entry and its automatic reminders from the local history.',
        entryDeleted: 'Medication deleted',
        edit: 'Edit',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Medication tracking is only for organization. Pet Life does not prescribe medications, suggest treatments, calculate dosages or replace your veterinarian.',
        reminderNoteHeader:
            'Automatic medication reminder created from the medication record.',
        takeMedicationReminderPrefix: 'Medication:',
      );
    }

    return const _MedicationStrings(
      medicationsTitle: 'Farmaci',
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
      noEndDate: 'Non impostata',
      clearEndDate: 'Rimuovi data fine',
      dailyReminderTimes: 'Orari giornalieri promemoria',
      addReminderTime: 'Aggiungi orario',
      automaticReminderDescription:
          'Pet Life crea promemoria giornalieri automatici per questi orari. Serve solo a ricordare informazioni inserite da te.',
      atLeastOneReminderTime: 'Aggiungi almeno un orario promemoria.',
      reminderMustHaveFutureOccurrence:
          'Scegli un intervallo con almeno un promemoria futuro.',
      prescribedByLabel: 'Veterinario / prescrittore',
      prescribedByHint: 'Opzionale',
      prescribedByShort: 'Vet',
      instructionsLabel: 'Indicazioni del veterinario',
      instructionsHint:
          'Opzionale. Inserisci solo indicazioni fornite dal veterinario.',
      instructionsShort: 'Indicazioni',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva farmaco',
      updateEntry: 'Aggiorna farmaco',
      cancelEdit: 'Annulla modifica',
      entrySavedWithReminders: 'Farmaco salvato e promemoria creati',
      entryUpdatedWithReminders: 'Farmaco aggiornato e promemoria rigenerati',
      emptyTitle: 'Nessun farmaco',
      emptyDescription:
          'Aggiungi farmaci solo come registro personale delle informazioni fornite dal veterinario.',
      deleteEntryTitle: 'Eliminare questo farmaco?',
      deleteEntryMessage:
          'Il farmaco e i suoi promemoria automatici verranno rimossi dallo storico locale.',
      entryDeleted: 'Farmaco eliminato',
      edit: 'Modifica',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking dei farmaci serve solo per organizzazione. Pet Life non prescrive farmaci, non suggerisce terapie, non calcola dosaggi e non sostituisce il veterinario.',
      reminderNoteHeader:
          'Promemoria farmaco automatico creato dal registro farmaci.',
      takeMedicationReminderPrefix: 'Farmaco:',
    );
  }
}