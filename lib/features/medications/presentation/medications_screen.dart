import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../application/medication_controller.dart';
import '../domain/medication_entry.dart';

enum _MedicationFilter {
  active,
  past,
  all,
}

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
  _MedicationFilter _filter = _MedicationFilter.active;

  @override
  Widget build(BuildContext context) {
    final petsState = ref.watch(petControllerProvider);
    final medicationState = ref.watch(medicationControllerProvider);
    final reminderState = ref.watch(reminderControllerProvider);

    return Scaffold(
      backgroundColor: _MedPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return const _ErrorState(error: 'Pet non trovato');
            }

            return medicationState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final reminders = reminderState.valueOrNull ?? const <Reminder>[];

                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false);

                petEntries.sort(
                  (a, b) => b.startDate.compareTo(a.startDate),
                );

                final filteredEntries = _filterEntries(petEntries);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
                  children: [
                    _Header(
                      onBack: () => context.go('/pets/${pet.id}'),
                      onAdd: () => _openEditor(pet: pet),
                    ),
                    const SizedBox(height: 16),
                    _FilterRow(
                      filter: _filter,
                      onChanged: (filter) {
                        setState(() {
                          _filter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _sectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _MedPalette.darkText,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (filteredEntries.isEmpty)
                      _EmptyState(
                        title: _emptyTitle,
                        description:
                            'Tocca + per aggiungere una cura prescritta dal veterinario.',
                      )
                    else
                      ...filteredEntries.map(
                        (entry) => _MedicationCard(
                          entry: entry,
                          pet: pet,
                          reminders: reminders,
                          onSuspendOrReinstate: () {
                            if (entry.status == MedicationStatus.paused) {
                              _reinstate(entry);
                            } else {
                              _suspend(entry);
                            }
                          },
                          onEdit: () => _openEditor(
                            pet: pet,
                            entry: entry,
                          ),
                          onTaken: () => _markNextDoseTaken(
                            entry,
                            reminders,
                          ),
                          onUndoLastTaken: () => _undoLastDoseTaken(
                            entry,
                            reminders,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const _DisclaimerCard(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String get _sectionTitle {
    return switch (_filter) {
      _MedicationFilter.active => 'In corso',
      _MedicationFilter.past => 'Archivio',
      _MedicationFilter.all => 'Tutte le cure',
    };
  }

  String get _emptyTitle {
    return switch (_filter) {
      _MedicationFilter.active => 'Nessun farmaco attivo',
      _MedicationFilter.past => 'Nessuna cura archiviata',
      _MedicationFilter.all => 'Nessun farmaco',
    };
  }

  List<MedicationEntry> _filterEntries(List<MedicationEntry> entries) {
    return switch (_filter) {
      _MedicationFilter.active => entries
          .where(
            (entry) =>
                entry.status == MedicationStatus.active ||
                entry.status == MedicationStatus.paused,
          )
          .toList(growable: false),
      _MedicationFilter.past => entries
          .where((entry) => entry.status == MedicationStatus.completed)
          .toList(growable: false),
      _MedicationFilter.all => entries,
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

  Future<void> _openEditor({
    required Pet pet,
    MedicationEntry? entry,
  }) async {
    final result = await showModalBottomSheet<_MedicationEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MedicationEditorSheet(
          pet: pet,
          entry: entry,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    switch (result.action) {
      case _MedicationEditorAction.save:
        await _saveMedication(
          pet: pet,
          previousEntry: entry,
          draft: result.draft!,
        );
      case _MedicationEditorAction.delete:
        if (entry != null) {
          await _deleteMedication(entry);
        }
    }
  }

  Future<void> _saveMedication({
    required Pet pet,
    required MedicationEntry? previousEntry,
    required _MedicationDraft draft,
  }) async {
    final now = DateTime.now();
    final medicationId =
        previousEntry?.id ?? 'medication-${now.microsecondsSinceEpoch}';

    if (previousEntry != null) {
      await ref
          .read(reminderControllerProvider.notifier)
          .deleteReminders(previousEntry.automaticReminderIds);
    }

    final reminderTimes = draft.reminderTimes
        .map(
          (time) => MedicationReminderTime(
            id: 'time-${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}',
            hour: time.hour,
            minute: time.minute,
          ),
        )
        .toList(growable: false);

    final totalDoses = _totalDosesFor(
      startDate: draft.startDate,
      endDate: draft.endDate,
      dailyTimes: reminderTimes.length,
    );

    final completedDoseCount = draft.completedDoseCount.clamp(0, totalDoses);

    final reminders = _buildMedicationReminders(
      medicationId: medicationId,
      pet: pet,
      medicationName: draft.name,
      startDate: draft.startDate,
      endDate: draft.endDate,
      reminderTimes: reminderTimes,
      instructions: draft.instructions,
      notes: draft.notes,
      prescribedBy: draft.prescribedBy,
      completedDoseCount: completedDoseCount,
    );

    final takenReminderIds = reminders
        .where((reminder) => reminder.status == ReminderStatus.completed)
        .map((reminder) => reminder.id)
        .toList(growable: false);

    final isCompleted =
        reminders.isNotEmpty && takenReminderIds.length >= reminders.length;

    final entry = MedicationEntry(
      id: medicationId,
      petId: pet.id,
      petName: pet.name,
      name: draft.name,
      status: isCompleted ? MedicationStatus.completed : MedicationStatus.active,
      startDate: _dateOnly(draft.startDate),
      endDate: _dateOnly(draft.endDate),
      dosage: draft.dosage.isEmpty ? null : draft.dosage,
      prescribedBy: draft.prescribedBy.isEmpty ? null : draft.prescribedBy,
      instructions: draft.instructions.isEmpty ? null : draft.instructions,
      notes: draft.notes.isEmpty ? null : draft.notes,
      reminderTimes: reminderTimes,
      automaticReminderIds:
          reminders.map((reminder) => reminder.id).toList(growable: false),
      takenReminderIds: takenReminderIds,
      createdAt: previousEntry?.createdAt ?? now,
      completedAt: isCompleted ? now : null,
      updatedAt: now,
    );

    if (previousEntry == null) {
      await ref.read(medicationControllerProvider.notifier).addEntry(entry);
    } else {
      await ref.read(medicationControllerProvider.notifier).updateEntry(entry);
    }

    for (final reminder in reminders) {
      await ref.read(reminderControllerProvider.notifier).addReminder(reminder);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          previousEntry == null
              ? 'Farmaco salvato e promemoria creati'
              : 'Farmaco aggiornato e promemoria ricreati',
        ),
      ),
    );
  }

  List<Reminder> _buildMedicationReminders({
    required String medicationId,
    required Pet pet,
    required String medicationName,
    required DateTime startDate,
    required DateTime endDate,
    required List<MedicationReminderTime> reminderTimes,
    required String instructions,
    required String notes,
    required String prescribedBy,
    required int completedDoseCount,
  }) {
    final reminders = <Reminder>[];
    final now = DateTime.now();
    var currentDay = _dateOnly(startDate);
    final lastDay = _dateOnly(endDate);
    var index = 0;

    while (!currentDay.isAfter(lastDay)) {
      for (final reminderTime in reminderTimes) {
        final scheduledAt = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        final id =
            '$medicationId-${currentDay.year}${currentDay.month.toString().padLeft(2, '0')}${currentDay.day.toString().padLeft(2, '0')}-${reminderTime.storageKey.replaceAll(':', '')}';

        final isAlreadyTaken = index < completedDoseCount;

        reminders.add(
          Reminder(
            id: id,
            petId: pet.id,
            petName: pet.name,
            category: ReminderCategory.medication,
            title: 'Farmaco: $medicationName',
            scheduledAt: scheduledAt,
            status: isAlreadyTaken
                ? ReminderStatus.completed
                : ReminderStatus.active,
            createdAt: now,
            completedAt: isAlreadyTaken ? now : null,
            notes: _reminderNotes(
              prescribedBy: prescribedBy,
              instructions: instructions,
              notes: notes,
            ),
          ),
        );

        index++;
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  String? _reminderNotes({
    required String prescribedBy,
    required String instructions,
    required String notes,
  }) {
    final lines = <String>[
      'Promemoria automatico generato da una terapia farmacologica.',
    ];

    if (prescribedBy.trim().isNotEmpty) {
      lines.add('Veterinario: ${prescribedBy.trim()}');
    }

    if (instructions.trim().isNotEmpty) {
      lines.add('Indicazioni: ${instructions.trim()}');
    }

    if (notes.trim().isNotEmpty) {
      lines.add(notes.trim());
    }

    return lines.join('\n');
  }

  Future<void> _markNextDoseTaken(
    MedicationEntry entry,
    List<Reminder> reminders,
  ) async {
    final nextReminder = _nextPendingReminder(entry, reminders);

    if (nextReminder == null) {
      return;
    }

    await ref
        .read(reminderControllerProvider.notifier)
        .completeReminder(nextReminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assunzione segnata')),
    );
  }

  Future<void> _undoLastDoseTaken(
    MedicationEntry entry,
    List<Reminder> reminders,
  ) async {
    final lastTakenReminder = _lastTakenReminder(entry, reminders);

    if (lastTakenReminder == null) {
      return;
    }

    await ref
        .read(reminderControllerProvider.notifier)
        .reopenReminder(lastTakenReminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ultima assunzione annullata')),
    );
  }

  Reminder? _nextPendingReminder(
    MedicationEntry entry,
    List<Reminder> reminders,
  ) {
    final ids = entry.automaticReminderIds.toSet();

    final candidates = reminders
        .where(
          (reminder) =>
              ids.contains(reminder.id) &&
              reminder.status != ReminderStatus.completed &&
              !entry.takenReminderIds.contains(reminder.id),
        )
        .toList(growable: false);

    candidates.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (candidates.isEmpty) {
      return null;
    }

    return candidates.first;
  }

  Reminder? _lastTakenReminder(
    MedicationEntry entry,
    List<Reminder> reminders,
  ) {
    final takenIds = entry.takenReminderIds.toSet();

    final candidates = reminders
        .where(
          (reminder) =>
              takenIds.contains(reminder.id) ||
              reminder.status == ReminderStatus.completed &&
                  entry.automaticReminderIds.contains(reminder.id),
        )
        .toList(growable: false);

    candidates.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (candidates.isEmpty) {
      return null;
    }

    return candidates.first;
  }

  Future<void> _suspend(MedicationEntry entry) async {
    await ref.read(medicationControllerProvider.notifier).suspendEntry(entry.id);

    await ref
        .read(reminderControllerProvider.notifier)
        .pauseMedicationReminders(entry.automaticReminderIds);
  }

  Future<void> _reinstate(MedicationEntry entry) async {
    await ref
        .read(medicationControllerProvider.notifier)
        .reinstateEntry(entry.id);

    await ref
        .read(reminderControllerProvider.notifier)
        .reinstateMedicationReminders(entry.automaticReminderIds);
  }

  Future<void> _deleteMedication(MedicationEntry entry) async {
    await ref
        .read(reminderControllerProvider.notifier)
        .deleteReminders(entry.automaticReminderIds);

    await ref.read(medicationControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farmaco eliminato')),
    );
  }

  int _totalDosesFor({
    required DateTime startDate,
    required DateTime endDate,
    required int dailyTimes,
  }) {
    final days = _dateOnly(endDate).difference(_dateOnly(startDate)).inDays + 1;
    return math.max(0, days) * dailyTimes;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onAdd,
  });

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
                'Farmaci',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: _MedPalette.darkText,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                'Terapie attive e storico',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MedPalette.secondaryText,
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
      color: _MedPalette.chip,
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
            color: _MedPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.onChanged,
  });

  final _MedicationFilter filter;
  final ValueChanged<_MedicationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'Attive',
          selected: filter == _MedicationFilter.active,
          onTap: () => onChanged(_MedicationFilter.active),
        ),
        const SizedBox(width: 7),
        _FilterChipButton(
          label: 'Passate',
          selected: filter == _MedicationFilter.past,
          onTap: () => onChanged(_MedicationFilter.past),
        ),
        const SizedBox(width: 7),
        _FilterChipButton(
          label: 'Tutte',
          selected: filter == _MedicationFilter.all,
          onTap: () => onChanged(_MedicationFilter.all),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? _MedPalette.darkText : _MedPalette.chip;
    final foreground = selected ? Colors.white : _MedPalette.secondaryText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.entry,
    required this.pet,
    required this.reminders,
    required this.onSuspendOrReinstate,
    required this.onEdit,
    required this.onTaken,
    required this.onUndoLastTaken,
  });

  final MedicationEntry entry;
  final Pet pet;
  final List<Reminder> reminders;
  final VoidCallback onSuspendOrReinstate;
  final VoidCallback onEdit;
  final VoidCallback onTaken;
  final VoidCallback onUndoLastTaken;

  @override
  Widget build(BuildContext context) {
    final petColor = Color(pet.colorValue);
    final accent = _visibleAccent(petColor);
    final total = entry.totalDoses;
    final taken = entry.takenDoses;
    final progress = total == 0 ? 0.0 : (taken / total).clamp(0.0, 1.0);
    final remaining = math.max(0, total - taken);
    final nextReminder = _nextReminder(entry, reminders);
    final isPaused = entry.status == MedicationStatus.paused;
    final isCompleted = entry.status == MedicationStatus.completed;

    return Opacity(
      opacity: isPaused ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _MedPalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _MedPalette.outline),
          boxShadow: [
            BoxShadow(
              color: _MedPalette.darkText.withValues(alpha: 0.04),
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
                    _CardHeader(
                      entry: entry,
                      pet: pet,
                      petColor: petColor,
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
                            color: _MedPalette.darkText,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(context, entry, nextReminder),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _MedPalette.secondaryText,
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
                              color: _MedPalette.mutedText,
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
                              color: _MedPalette.secondaryText,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        color: accent,
                        backgroundColor: _MedPalette.progressBackground,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          '$taken di $total prese',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _MedPalette.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          isCompleted
                              ? 'cura completata'
                              : '$remaining rimaste',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _MedPalette.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _MedPalette.outline),
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: isPaused ? 'Reintegra' : 'Sospendi',
                        onTap: isCompleted ? null : onSuspendOrReinstate,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: _MedPalette.outline,
                    ),
                    Expanded(
                      child: _ActionButton(
                        label: 'Modifica',
                        onTap: onEdit,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: _MedPalette.outline,
                    ),
                    Expanded(
                      child: _ActionButton(
                        label: 'Annulla',
                        onTap: taken > 0 ? onUndoLastTaken : null,
                      ),
                    ),
                    const VerticalDivider(
                      width: 1,
                      color: _MedPalette.outline,
                    ),
                    Expanded(
                      child: _ActionButton(
                        label: 'Presa',
                        icon: Icons.check_rounded,
                        accent: accent,
                        onTap: isPaused || isCompleted || nextReminder == null
                            ? null
                            : onTaken,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Reminder? _nextReminder(MedicationEntry entry, List<Reminder> reminders) {
    final ids = entry.automaticReminderIds.toSet();

    final pending = reminders
        .where(
          (reminder) =>
              ids.contains(reminder.id) &&
              reminder.status != ReminderStatus.completed &&
              !entry.takenReminderIds.contains(reminder.id),
        )
        .toList(growable: false);

    pending.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (pending.isEmpty) {
      return null;
    }

    return pending.first;
  }

  String _subtitle(
    BuildContext context,
    MedicationEntry entry,
    Reminder? nextReminder,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dose = entry.dosage?.trim().isNotEmpty == true
        ? entry.dosage!.trim()
        : '1 compressa';

    if (nextReminder != null) {
      final date = DateFormat('d MMM', locale).format(nextReminder.scheduledAt);
      final time = DateFormat.Hm(locale).format(nextReminder.scheduledAt);
      return '$dose · prossima $date alle $time';
    }

    final start = DateFormat('d MMM', locale).format(entry.startDate);
    final end = entry.endDate == null
        ? 'fine non impostata'
        : DateFormat('d MMM', locale).format(entry.endDate!);

    return '$dose · dal $start al $end';
  }

  Color _visibleAccent(Color petColor) {
    if (petColor.computeLuminance() > 0.72) {
      return const Color(0xFFF3A83B);
    }

    return petColor;
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.entry,
    required this.pet,
    required this.petColor,
  });

  final MedicationEntry entry;
  final Pet pet;
  final Color petColor;

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
          Expanded(
            child: Text(
              prescribedBy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _MedPalette.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ] else
          const Spacer(),
        if (entry.status == MedicationStatus.paused)
          Text(
            'Sospesa',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _MedPalette.warningIcon,
                  fontWeight: FontWeight.w900,
                ),
          ),
        if (entry.status == MedicationStatus.completed)
          Text(
            'Completata',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _MedPalette.mutedText,
                  fontWeight: FontWeight.w900,
                ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
        ? _MedPalette.mutedText
        : accent ?? _MedPalette.secondaryText;

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
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedPalette.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _MedPalette.warningBorder),
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
                color: _MedPalette.warningIcon,
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
                'Pet Life ti aiuta a ricordare le terapie. Dosi, durata e farmaci li decide solo il veterinario.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MedPalette.warningText,
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

class _MedicationEditorSheet extends StatefulWidget {
  const _MedicationEditorSheet({
    required this.pet,
    this.entry,
  });

  final Pet pet;
  final MedicationEntry? entry;

  @override
  State<_MedicationEditorSheet> createState() => _MedicationEditorSheetState();
}

class _MedicationEditorSheetState extends State<_MedicationEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _completedDoseCountController;
  late final TextEditingController _prescribedByController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late DateTime _endDate;
  late List<TimeOfDay> _times;

  bool get _isEditing => widget.entry != null;

  int get _totalDoses {
    final days = _dateOnly(_endDate).difference(_dateOnly(_startDate)).inDays + 1;
    return math.max(0, days) * _times.length;
  }

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;
    final now = DateTime.now();

    _nameController = TextEditingController(text: entry?.name ?? '');
    _dosageController = TextEditingController(text: entry?.dosage ?? '1 compressa');
    _completedDoseCountController = TextEditingController(
      text: (entry?.takenDoses ?? 0).toString(),
    );
    _prescribedByController = TextEditingController(text: entry?.prescribedBy ?? '');
    _instructionsController = TextEditingController(text: entry?.instructions ?? '');
    _notesController = TextEditingController(text: entry?.notes ?? '');

    _startDate = entry?.startDate ?? _dateOnly(now);
    _endDate = entry?.endDate ?? _dateOnly(now.add(const Duration(days: 6)));

    _times = entry == null
        ? [
            TimeOfDay(
              hour: now.add(const Duration(hours: 1)).hour,
              minute: 0,
            ),
          ]
        : entry.reminderTimes
            .map(
              (time) => TimeOfDay(
                hour: time.hour,
                minute: time.minute,
              ),
            )
            .toList(growable: false);

    if (_times.isEmpty) {
      _times = const [TimeOfDay(hour: 9, minute: 0)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _completedDoseCountController.dispose();
    _prescribedByController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _MedPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Modifica farmaco' : 'Nuovo farmaco',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _MedPalette.darkText,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cura di ${widget.pet.name}. Pet Life crea promemoria giornalieri automatici e aggiorna l’avanzamento quando segni una presa.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MedPalette.secondaryText,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome farmaco',
                      hintText: 'Es. Gabapentin 50 mg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Inserisci il nome del farmaco';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Quantità / nota assunzione',
                      hintText: 'Es. 1 compressa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _completedDoseCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Prese già effettuate',
                      helperText: 'Totale previsto: $_totalDoses assunzioni',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final raw = value?.trim() ?? '';

                      if (raw.isEmpty) {
                        return 'Inserisci 0 se la cura deve iniziare ora';
                      }

                      final parsed = int.tryParse(raw);

                      if (parsed == null || parsed < 0) {
                        return 'Inserisci un numero valido';
                      }

                      if (parsed > _totalDoses) {
                        return 'Non può superare il totale previsto';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _prescribedByController,
                    decoration: const InputDecoration(
                      labelText: 'Veterinario / prescrittore',
                      hintText: 'Opzionale',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructionsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Indicazioni del veterinario',
                      hintText: 'Es. Dopo i pasti',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Opzionale',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Inizio',
                    date: _startDate,
                    onTap: () => _selectDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateSelector(
                    label: 'Fine',
                    date: _endDate,
                    onTap: () => _selectDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TimesEditor(
              times: _times,
              onAdd: _addTime,
              onEdit: _editTime,
              onRemove: _removeTime,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Aggiorna farmaco' : 'Salva farmaco'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina cura'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({
    required bool isStart,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = _dateOnly(picked);

        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = _dateOnly(picked);

        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      }
    });
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _times.isEmpty ? const TimeOfDay(hour: 9, minute: 0) : _times.last,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _times = _sortTimes([..._times, picked]);
    });
  }

  Future<void> _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );

    if (picked == null || !mounted) {
      return;
    }

    final updated = [..._times];
    updated[index] = picked;

    setState(() {
      _times = _sortTimes(updated);
    });
  }

  void _removeTime(int index) {
    if (_times.length == 1) {
      return;
    }

    final updated = [..._times]..removeAt(index);

    setState(() {
      _times = _sortTimes(updated);
    });
  }

  List<TimeOfDay> _sortTimes(List<TimeOfDay> times) {
    final byKey = <String, TimeOfDay>{};

    for (final time in times) {
      final key =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      byKey[key] = time;
    }

    final sorted = byKey.values.toList(growable: false);

    sorted.sort((a, b) {
      final first = a.hour * 60 + a.minute;
      final second = b.hour * 60 + b.minute;
      return first.compareTo(second);
    });

    return sorted;
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      _MedicationEditorResult.save(
        _MedicationDraft(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          completedDoseCount: int.parse(_completedDoseCountController.text),
          prescribedBy: _prescribedByController.text.trim(),
          instructions: _instructionsController.text.trim(),
          notes: _notesController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          reminderTimes: _times,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminare questo farmaco?'),
          content: const Text(
            'La cura e i promemoria collegati verranno rimossi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      Navigator.of(context).pop(_MedicationEditorResult.delete());
    }
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Material(
      color: _MedPalette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _MedPalette.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _MedPalette.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM yyyy', locale).format(date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _MedPalette.darkText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimesEditor extends StatelessWidget {
  const _TimesEditor({
    required this.times,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<TimeOfDay> times;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _MedPalette.outline),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orari giornalieri',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _MedPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < times.length; index++)
                InputChip(
                  label: Text(times[index].format(context)),
                  avatar: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  onPressed: () => onEdit(index),
                  onDeleted: times.length == 1 ? null : () => onRemove(index),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Aggiungi orario'),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MedPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MedPalette.outline),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.medication_outlined,
            size: 42,
            color: _MedPalette.secondaryText,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _MedPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _MedPalette.secondaryText,
                  height: 1.3,
                ),
          ),
        ],
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
          style: const TextStyle(color: _MedPalette.darkText),
        ),
      ),
    );
  }
}

class _MedicationDraft {
  const _MedicationDraft({
    required this.name,
    required this.dosage,
    required this.completedDoseCount,
    required this.prescribedBy,
    required this.instructions,
    required this.notes,
    required this.startDate,
    required this.endDate,
    required this.reminderTimes,
  });

  final String name;
  final String dosage;
  final int completedDoseCount;
  final String prescribedBy;
  final String instructions;
  final String notes;
  final DateTime startDate;
  final DateTime endDate;
  final List<TimeOfDay> reminderTimes;
}

enum _MedicationEditorAction {
  save,
  delete,
}

class _MedicationEditorResult {
  const _MedicationEditorResult._({
    required this.action,
    this.draft,
  });

  factory _MedicationEditorResult.save(_MedicationDraft draft) {
    return _MedicationEditorResult._(
      action: _MedicationEditorAction.save,
      draft: draft,
    );
  }

  factory _MedicationEditorResult.delete() {
    return const _MedicationEditorResult._(
      action: _MedicationEditorAction.delete,
    );
  }

  final _MedicationEditorAction action;
  final _MedicationDraft? draft;
}

class _MedPalette {
  const _MedPalette._();

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

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}