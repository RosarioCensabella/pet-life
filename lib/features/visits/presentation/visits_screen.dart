import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../documents/application/document_file_service.dart';
import '../../documents/application/document_file_service_provider.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../documents/domain/pet_document.dart';
import '../../expenses/application/expense_controller.dart';
import '../../expenses/domain/expense_entry.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../application/visit_controller.dart';
import '../domain/visit_entry.dart';

class VisitsScreen extends ConsumerStatefulWidget {
  const VisitsScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends ConsumerState<VisitsScreen> {
  _VisitFilter _selectedFilter = _VisitFilter.all;

  @override
  Widget build(BuildContext context) {
    final strings = _VisitStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final visitState = ref.watch(visitControllerProvider);

    return Scaffold(
      backgroundColor: _VisitPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return _ErrorState(error: strings.petNotFound);
            }

            return visitState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false);

                final scheduledCount = petEntries
                    .where((entry) => entry.status == VisitStatus.scheduled)
                    .length;
                final completedCount = petEntries
                    .where((entry) => entry.status == VisitStatus.completed)
                    .length;

                final filteredEntries = _filterEntries(petEntries);

                final totalSpent = petEntries
                    .where((entry) => entry.status == VisitStatus.completed)
                    .fold<double>(
                      0,
                      (previous, entry) => previous + (entry.amount ?? 0),
                    );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  children: [
                    _VisitsHeader(
                      petName: pet.name,
                      subtitle: strings.headerSubtitle(
                        scheduledCount: scheduledCount,
                        completedCount: completedCount,
                      ),
                      onBack: () => context.go('/pets/${pet.id}'),
                      onAdd: () => _openVisitEditor(
                        pet: pet,
                        strings: strings,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StatusFilterRow(
                      selectedFilter: _selectedFilter,
                      strings: strings,
                      onSelected: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filteredEntries.isEmpty)
                      _EmptyVisitsCard(strings: strings)
                    else
                      ...filteredEntries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VisitCard(
                            entry: entry,
                            petColor: Color(pet.colorValue),
                            strings: strings,
                            onEdit: () => _openVisitEditor(
                              pet: pet,
                              strings: strings,
                              entry: entry,
                            ),
                            onDelete: () => _deleteVisit(entry, strings),
                            onComplete: () => _completeVisit(entry, strings),
                            onToggleCalendar: () => _toggleCalendar(
                              pet: pet,
                              entry: entry,
                              strings: strings,
                            ),
                            onOpenReport: () => _openReport(entry, strings),
                          ),
                        ),
                      ),
                    if (completedCount > 0) ...[
                      const SizedBox(height: 4),
                      _TotalSpentCard(
                        label: strings.totalSpent,
                        amount: totalSpent,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<VisitEntry> _filterEntries(List<VisitEntry> entries) {
    switch (_selectedFilter) {
      case _VisitFilter.all:
        return entries;
      case _VisitFilter.scheduled:
        return entries
            .where((entry) => entry.status == VisitStatus.scheduled)
            .toList(growable: false);
      case _VisitFilter.completed:
        return entries
            .where((entry) => entry.status == VisitStatus.completed)
            .toList(growable: false);
    }
  }

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  Future<void> _openVisitEditor({
    required Pet pet,
    required _VisitStrings strings,
    VisitEntry? entry,
  }) async {
    final result = await showModalBottomSheet<_VisitEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _VisitEditorSheet(
          strings: strings,
          entry: entry,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    switch (result.action) {
      case _VisitEditorAction.save:
        await _saveVisit(
          pet: pet,
          strings: strings,
          previousEntry: entry,
          data: result.data!,
        );
      case _VisitEditorAction.delete:
        if (entry != null) {
          await _deleteVisit(entry, strings);
        }
    }
  }

  Future<void> _saveVisit({
    required Pet pet,
    required _VisitStrings strings,
    required VisitEntry? previousEntry,
    required _VisitEditorData data,
  }) async {
    final now = DateTime.now();
    final isCompleted = data.isCompleted || !data.visitDate.isAfter(now);
    final entryId = previousEntry?.id ?? 'visit-${now.microsecondsSinceEpoch}';

    await _deleteLinkedReminders(previousEntry);

    if (previousEntry?.expenseEntryId != null) {
      await ref
          .read(expenseControllerProvider.notifier)
          .deleteEntry(previousEntry!.expenseEntryId!);
    }

    String? expenseEntryId;
    String? reportDocumentId = previousEntry?.reportDocumentId;

    if (isCompleted && data.amount != null) {
      expenseEntryId = 'expense-visit-$entryId';

      await ref.read(expenseControllerProvider.notifier).addEntry(
            ExpenseEntry(
              id: expenseEntryId,
              petId: pet.id,
              petName: pet.name,
              category: ExpenseCategory.vet,
              description: data.reason,
              amount: data.amount!,
              currency: data.currency,
              expenseDate: data.visitDate,
              createdAt: now,
              vendor: _optionalText(data.clinicName),
              notes: _optionalText(data.outcome),
            ),
          );
    }

    if (data.shouldAttachReport) {
      final createdDocumentId = await _pickAndSaveReport(
        pet: pet,
        documentId: 'visit-report-$entryId-${now.microsecondsSinceEpoch}',
        title: '${strings.reportTitle} · ${data.reason}',
        notes: strings.reportLinkedToVisit,
      );

      reportDocumentId = createdDocumentId ?? reportDocumentId;
    }

    final shouldAddReminder = data.addToCalendar && !isCompleted;
    final reminderIds = <String>[];

    if (shouldAddReminder) {
      final reminder = _buildVisitReminder(
        pet: pet,
        visitId: entryId,
        reason: data.reason,
        visitDate: data.visitDate,
        createdAt: now,
      );

      reminderIds.add(reminder.id);
      await ref.read(reminderControllerProvider.notifier).addReminder(reminder);
    }

    final updatedEntry = VisitEntry(
      id: entryId,
      petId: pet.id,
      petName: pet.name,
      visitType: data.visitType,
      reason: data.reason,
      visitDate: data.visitDate,
      createdAt: previousEntry?.createdAt ?? now,
      status: isCompleted ? VisitStatus.completed : VisitStatus.scheduled,
      clinicName: _optionalText(data.clinicName),
      doctorName: _optionalText(data.doctorName),
      outcome: _optionalText(data.outcome),
      nextVisitDate: data.nextVisitDate,
      notes: _optionalText(data.notes),
      amount: isCompleted ? data.amount : null,
      currency: data.currency,
      expenseEntryId: expenseEntryId,
      reportDocumentId: reportDocumentId,
      completedAt: isCompleted ? previousEntry?.completedAt ?? now : null,
      addToCalendar: shouldAddReminder,
      automaticReminderIds: reminderIds,
      updatedAt: now,
    );

    await ref.read(visitControllerProvider.notifier).upsertEntry(updatedEntry);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          previousEntry == null ? strings.entrySaved : strings.entryUpdated,
        ),
      ),
    );
  }

  Future<void> _toggleCalendar({
    required Pet pet,
    required VisitEntry entry,
    required _VisitStrings strings,
  }) async {
    if (entry.status == VisitStatus.completed) {
      return;
    }

    await _deleteLinkedReminders(entry);

    final now = DateTime.now();

    if (entry.addToCalendar) {
      await ref.read(visitControllerProvider.notifier).updateEntry(
            entry.copyWith(
              addToCalendar: false,
              automaticReminderIds: const [],
              updatedAt: now,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.removedFromCalendar)),
      );
      return;
    }

    final reminder = _buildVisitReminder(
      pet: pet,
      visitId: entry.id,
      reason: entry.reason,
      visitDate: entry.visitDate,
      createdAt: now,
    );

    await ref.read(reminderControllerProvider.notifier).addReminder(reminder);

    await ref.read(visitControllerProvider.notifier).updateEntry(
          entry.copyWith(
            addToCalendar: true,
            automaticReminderIds: [reminder.id],
            updatedAt: now,
          ),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.addedToCalendar)),
    );
  }

  Future<void> _completeVisit(
    VisitEntry entry,
    _VisitStrings strings,
  ) async {
    final result = await showModalBottomSheet<_VisitCompletionData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _VisitCompletionSheet(
          strings: strings,
          entry: entry,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    await _deleteLinkedReminders(entry);

    if (entry.expenseEntryId != null) {
      await ref
          .read(expenseControllerProvider.notifier)
          .deleteEntry(entry.expenseEntryId!);
    }

    final expenseEntryId = 'expense-visit-${entry.id}';
    String? reportDocumentId = entry.reportDocumentId;

    await ref.read(expenseControllerProvider.notifier).addEntry(
          ExpenseEntry(
            id: expenseEntryId,
            petId: entry.petId,
            petName: entry.petName,
            category: ExpenseCategory.vet,
            description: entry.reason,
            amount: result.amount,
            currency: result.currency,
            expenseDate: now,
            createdAt: now,
            vendor: entry.clinicName,
            notes: _optionalText(result.outcome),
          ),
        );

    if (result.shouldAttachReport) {
      final pet = Pet(
        id: entry.petId,
        name: entry.petName,
        species: PetSpecies.other,
        estimatedAgeYears: 0,
        createdAt: now,
      );

      final createdDocumentId = await _pickAndSaveReport(
        pet: pet,
        documentId: 'visit-report-${entry.id}-${now.microsecondsSinceEpoch}',
        title: '${strings.reportTitle} · ${entry.reason}',
        notes: strings.reportLinkedToVisit,
      );

      reportDocumentId = createdDocumentId ?? reportDocumentId;
    }

    await ref.read(visitControllerProvider.notifier).updateEntry(
          entry.copyWith(
            status: VisitStatus.completed,
            visitDate: entry.visitDate.isAfter(now) ? now : entry.visitDate,
            completedAt: now,
            outcome: _optionalText(result.outcome),
            amount: result.amount,
            currency: result.currency,
            expenseEntryId: expenseEntryId,
            reportDocumentId: reportDocumentId,
            addToCalendar: false,
            automaticReminderIds: const [],
            updatedAt: now,
          ),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.visitCompleted)),
    );
  }

  Future<void> _deleteVisit(
    VisitEntry entry,
    _VisitStrings strings,
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

    await _deleteLinkedReminders(entry);

    if (entry.expenseEntryId != null) {
      await ref
          .read(expenseControllerProvider.notifier)
          .deleteEntry(entry.expenseEntryId!);
    }

    await ref.read(visitControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  Future<String?> _pickAndSaveReport({
    required Pet pet,
    required String documentId,
    required String title,
    required String notes,
  }) async {
    final pickedDocument = await ref
        .read(documentFileServiceProvider)
        .pickAndCopyDocument(
          petId: pet.id,
          documentId: documentId,
        );

    if (pickedDocument is! PickedLocalDocument) {
      return null;
    }

    await ref.read(petDocumentControllerProvider.notifier).addDocument(
          PetDocument(
            id: documentId,
            petId: pet.id,
            petName: pet.name,
            title: title,
            category: PetDocumentCategory.labReport,
            originalFileName: pickedDocument.originalFileName,
            localPath: pickedDocument.localPath,
            sizeBytes: pickedDocument.sizeBytes,
            createdAt: DateTime.now(),
            notes: notes,
          ),
        );

    return documentId;
  }

  Future<void> _openReport(
    VisitEntry entry,
    _VisitStrings strings,
  ) async {
    final reportDocumentId = entry.reportDocumentId;

    if (reportDocumentId == null) {
      return;
    }

    final documents = ref.read(petDocumentControllerProvider).valueOrNull ??
        const <PetDocument>[];

    PetDocument? document;

    for (final item in documents) {
      if (item.id == reportDocumentId) {
        document = item;
        break;
      }
    }

    if (document == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.reportNotFound)),
      );
      return;
    }

    await ref.read(documentFileServiceProvider).openDocument(document.localPath);
  }

  Future<void> _deleteLinkedReminders(VisitEntry? entry) async {
    if (entry == null) {
      return;
    }

    final reminders = ref.read(reminderControllerProvider).valueOrNull ??
        const <Reminder>[];

    final ids = <String>{
      ...entry.automaticReminderIds,
      ...reminders
          .where(
            (reminder) =>
                reminder.id.startsWith('visit-${entry.id}-') ||
                (reminder.notes?.contains('visitId:${entry.id}') ?? false),
          )
          .map((reminder) => reminder.id),
    };

    if (ids.isEmpty) {
      return;
    }

    await ref
        .read(reminderControllerProvider.notifier)
        .deleteReminders(ids.toList(growable: false));
  }

  Reminder _buildVisitReminder({
    required Pet pet,
    required String visitId,
    required String reason,
    required DateTime visitDate,
    required DateTime createdAt,
  }) {
    return Reminder(
      id: 'visit-$visitId-reminder',
      petId: pet.id,
      petName: pet.name,
      category: ReminderCategory.vetVisit,
      title: reason,
      scheduledAt: visitDate,
      status: ReminderStatus.active,
      createdAt: createdAt,
      notes: 'visitId:$visitId',
    );
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}

enum _VisitFilter {
  all,
  scheduled,
  completed,
}

class _VisitsHeader extends StatelessWidget {
  const _VisitsHeader({
    required this.petName,
    required this.subtitle,
    required this.onBack,
    required this.onAdd,
  });

  final String petName;
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
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visite',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                        color: _VisitPalette.darkText,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _VisitPalette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.add,
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
      color: _VisitPalette.chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: _VisitPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selectedFilter,
    required this.strings,
    required this.onSelected,
  });

  final _VisitFilter selectedFilter;
  final _VisitStrings strings;
  final ValueChanged<_VisitFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterPill(
          label: strings.all,
          selected: selectedFilter == _VisitFilter.all,
          onTap: () => onSelected(_VisitFilter.all),
        ),
        _FilterPill(
          label: strings.scheduled,
          selected: selectedFilter == _VisitFilter.scheduled,
          onTap: () => onSelected(_VisitFilter.scheduled),
        ),
        _FilterPill(
          label: strings.completed,
          selected: selectedFilter == _VisitFilter.completed,
          onTap: () => onSelected(_VisitFilter.completed),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _VisitPalette.darkText : _VisitPalette.chip;
    final foreground = selected ? Colors.white : _VisitPalette.secondaryText;

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
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.entry,
    required this.petColor,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onToggleCalendar,
    required this.onOpenReport,
  });

  final VisitEntry entry;
  final Color petColor;
  final _VisitStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback onToggleCalendar;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel =
        DateFormat('dd MMM · HH:mm', locale).format(entry.visitDate);

    final detailItems = <String>[
      if (entry.doctorName != null && entry.doctorName!.trim().isNotEmpty)
        entry.doctorName!,
      if (entry.clinicName != null && entry.clinicName!.trim().isNotEmpty)
        entry.clinicName!,
    ];

    final note = entry.isCompleted
        ? (entry.outcome?.trim().isNotEmpty == true
            ? entry.outcome!.trim()
            : entry.notes)
        : (entry.notes?.trim().isNotEmpty == true
            ? entry.notes!.trim()
            : null);

    return Container(
      decoration: BoxDecoration(
        color: _VisitPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _VisitPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _VisitStatusBadge(
                        label: entry.isCompleted
                            ? strings.completedUpper
                            : strings.scheduledUpper,
                        completed: entry.isCompleted,
                      ),
                      const Spacer(),
                      _PetChip(
                        petName: entry.petName,
                        color: petColor,
                      ),
                      const SizedBox(width: 4),
                      _VisitMenuButton(
                        strings: strings,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.reason,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _VisitPalette.darkText,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      dateLabel,
                      ...detailItems,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _VisitPalette.secondaryText,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                  if (note != null && note.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _VisitPalette.noteBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      child: Text(
                        entry.isCompleted
                            ? note
                            : '${strings.reasonBoxPrefix}: $note',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _VisitPalette.darkText,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  if (entry.isCompleted) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          strings.expense,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _VisitPalette.secondaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          _formatMoney(entry.amount ?? 0, entry.currency),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _VisitPalette.darkText,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ],
                    ),
                    if (entry.reportDocumentId != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onOpenReport,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: Text(strings.openReport),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (entry.isScheduled)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _VisitPalette.outline),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _VisitActionButton(
                        label: strings.postpone,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(
                      height: 45,
                      child: VerticalDivider(
                        width: 1,
                        color: _VisitPalette.outline,
                      ),
                    ),
                    Expanded(
                      child: _VisitActionButton(
                        label: entry.addToCalendar
                            ? strings.removeFromCalendar
                            : strings.addToCalendar,
                        onTap: onToggleCalendar,
                      ),
                    ),
                    const SizedBox(
                      height: 45,
                      child: VerticalDivider(
                        width: 1,
                        color: _VisitPalette.outline,
                      ),
                    ),
                    Expanded(
                      child: _VisitActionButton(
                        label: strings.markDone,
                        onTap: onComplete,
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

  String _formatMoney(double amount, String currency) {
    final formatted = amount.toStringAsFixed(2).replaceAll('.', ',');

    return '$formatted ${currency == 'EUR' ? '€' : currency}';
  }
}

class _VisitStatusBadge extends StatelessWidget {
  const _VisitStatusBadge({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: completed
            ? _VisitPalette.completedBadge
            : _VisitPalette.scheduledBadge,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: completed
                  ? _VisitPalette.secondaryText
                  : _VisitPalette.purple,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  const _PetChip({
    required this.petName,
    required this.color,
  });

  final String petName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            petName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _VisitMenuButton extends StatelessWidget {
  const _VisitMenuButton({
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  final _VisitStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_VisitMenuAction>(
      tooltip: strings.actions,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (action) {
        switch (action) {
          case _VisitMenuAction.edit:
            onEdit();
          case _VisitMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _VisitMenuAction.edit,
            child: Text(strings.edit),
          ),
          PopupMenuItem(
            value: _VisitMenuAction.delete,
            child: Text(strings.delete),
          ),
        ];
      },
      child: const SizedBox(
        width: 34,
        height: 30,
        child: Center(
          child: Text(
            '⋯',
            style: TextStyle(
              color: _VisitPalette.secondaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

enum _VisitMenuAction {
  edit,
  delete,
}

class _VisitActionButton extends StatelessWidget {
  const _VisitActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _VisitPalette.card,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 45,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _VisitPalette.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyVisitsCard extends StatelessWidget {
  const _EmptyVisitsCard({
    required this.strings,
  });

  final _VisitStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _VisitPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _VisitPalette.outline),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.local_hospital_outlined,
            color: _VisitPalette.secondaryText,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            strings.emptyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _VisitPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.emptyDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _VisitPalette.secondaryText,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _TotalSpentCard extends StatelessWidget {
  const _TotalSpentCard({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _VisitPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _VisitPalette.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _VisitPalette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _VisitPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _VisitEditorSheet extends StatefulWidget {
  const _VisitEditorSheet({
    required this.strings,
    this.entry,
  });

  final _VisitStrings strings;
  final VisitEntry? entry;

  @override
  State<_VisitEditorSheet> createState() => _VisitEditorSheetState();
}

class _VisitEditorSheetState extends State<_VisitEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _doctorController = TextEditingController();
  final _clinicController = TextEditingController();
  final _notesController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _amountController = TextEditingController();

  late VisitType _visitType;
  late DateTime _visitDate;
  DateTime? _nextVisitDate;
  late bool _isCompleted;
  late bool _addToCalendar;
  bool _shouldAttachReport = false;
  String _currency = 'EUR';

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;
    final now = DateTime.now();

    _visitType = entry?.visitType ?? VisitType.routine;
    _visitDate = entry?.visitDate ?? now.add(const Duration(days: 1));
    _nextVisitDate = entry?.nextVisitDate;
    _isCompleted =
        entry?.status == VisitStatus.completed || !_visitDate.isAfter(now);
    _addToCalendar = entry?.addToCalendar ?? false;
    _currency = entry?.currency ?? 'EUR';

    _reasonController.text = entry?.reason ?? '';
    _doctorController.text = entry?.doctorName ?? '';
    _clinicController.text = entry?.clinicName ?? '';
    _notesController.text = entry?.notes ?? '';
    _outcomeController.text = entry?.outcome ?? '';
    _amountController.text =
        entry?.amount == null ? '' : _formatNumber(entry!.amount!);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _doctorController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
    _outcomeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectVisitDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_visitDate),
    );

    if (!mounted) {
      return;
    }

    final finalTime = pickedTime ?? TimeOfDay.fromDateTime(_visitDate);

    setState(() {
      _visitDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        finalTime.hour,
        finalTime.minute,
      );

      if (!_visitDate.isAfter(DateTime.now())) {
        _isCompleted = true;
        _addToCalendar = false;
      }
    });
  }

  Future<void> _selectNextVisitDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _nextVisitDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = amountText.isEmpty ? null : double.parse(amountText);
    final completed = _isCompleted || !_visitDate.isAfter(DateTime.now());

    Navigator.of(context).pop(
      _VisitEditorResult.save(
        _VisitEditorData(
          visitType: _visitType,
          reason: _reasonController.text.trim(),
          visitDate: _visitDate,
          doctorName: _doctorController.text.trim(),
          clinicName: _clinicController.text.trim(),
          notes: _notesController.text.trim(),
          outcome: _outcomeController.text.trim(),
          nextVisitDate: _nextVisitDate,
          isCompleted: completed,
          amount: completed ? amount : null,
          currency: _currency,
          shouldAttachReport: _shouldAttachReport,
          addToCalendar: completed ? false : _addToCalendar,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    Navigator.of(context).pop(_VisitEditorResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final visitDateLabel =
        DateFormat('dd MMM yyyy · HH:mm', locale).format(_visitDate);
    final nextVisitDateLabel = _nextVisitDate == null
        ? strings.notSet
        : DateFormat('dd MMM yyyy', locale).format(_nextVisitDate!);

    return _SheetShell(
      title: _isEditing ? strings.editVisit : strings.addVisit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<VisitType>(
              initialValue: _visitType,
              decoration: InputDecoration(
                labelText: strings.visitTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: VisitType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(strings.visitTypeLabelFor(type)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _visitType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: strings.reasonLabel,
                hintText: strings.reasonHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return strings.reasonRequired;
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectVisitDate,
              icon: const Icon(Icons.event_outlined),
              label: Text('${strings.visitDate}: $visitDateLabel'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doctorController,
              decoration: InputDecoration(
                labelText: strings.doctorLabel,
                hintText: strings.doctorHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clinicController,
              decoration: InputDecoration(
                labelText: strings.clinicNameLabel,
                hintText: strings.clinicNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: strings.notesLabel,
                hintText: strings.notesHint,
                border: const OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isCompleted,
              onChanged: (value) {
                setState(() {
                  _isCompleted = value;

                  if (_isCompleted) {
                    _addToCalendar = false;
                  }
                });
              },
              title: Text(strings.visitAlreadyDone),
              subtitle: Text(strings.visitAlreadyDoneDescription),
            ),
            if (!_isCompleted)
              SwitchListTile(
                value: _addToCalendar,
                onChanged: (value) {
                  setState(() {
                    _addToCalendar = value;
                  });
                },
                title: Text(strings.addToCalendar),
                subtitle: Text(strings.addToCalendarDescription),
              ),
            if (_isCompleted) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _outcomeController,
                decoration: InputDecoration(
                  labelText: strings.outcomeLabel,
                  hintText: strings.outcomeHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                decoration: InputDecoration(
                  labelText: strings.amountLabel,
                  hintText: '65,00',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_isCompleted) {
                    return null;
                  }

                  final amount = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );

                  if (amount == null || amount < 0) {
                    return strings.amountRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _shouldAttachReport,
                onChanged: (value) {
                  setState(() {
                    _shouldAttachReport = value;
                  });
                },
                title: Text(strings.attachReport),
                subtitle: Text(strings.attachReportDescription),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectNextVisitDate,
              icon: const Icon(Icons.event_available_outlined),
              label: Text('${strings.nextVisitDate}: $nextVisitDateLabel'),
            ),
            if (_nextVisitDate != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _nextVisitDate = null;
                  });
                },
                icon: const Icon(Icons.close_outlined),
                label: Text(strings.clearNextVisitDate),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? strings.updateVisit : strings.saveEntry),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VisitCompletionSheet extends StatefulWidget {
  const _VisitCompletionSheet({
    required this.strings,
    required this.entry,
  });

  final _VisitStrings strings;
  final VisitEntry entry;

  @override
  State<_VisitCompletionSheet> createState() => _VisitCompletionSheetState();
}

class _VisitCompletionSheetState extends State<_VisitCompletionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _outcomeController = TextEditingController();

  String _currency = 'EUR';
  bool _shouldAttachReport = false;

  @override
  void initState() {
    super.initState();

    _amountController.text =
        widget.entry.amount == null ? '' : _formatNumber(widget.entry.amount!);
    _outcomeController.text = widget.entry.outcome ?? '';
    _currency = widget.entry.currency;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      _VisitCompletionData(
        amount: double.parse(
          _amountController.text.trim().replaceAll(',', '.'),
        ),
        currency: _currency,
        outcome: _outcomeController.text.trim(),
        shouldAttachReport: _shouldAttachReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    return _SheetShell(
      title: strings.completeVisit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              widget.entry.reason,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _VisitPalette.darkText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: InputDecoration(
                labelText: strings.amountLabel,
                hintText: '65,00',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );

                if (amount == null || amount < 0) {
                  return strings.amountRequired;
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _outcomeController,
              decoration: InputDecoration(
                labelText: strings.outcomeLabel,
                hintText: strings.outcomeHint,
                border: const OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _shouldAttachReport,
              onChanged: (value) {
                setState(() {
                  _shouldAttachReport = value;
                });
              },
              title: Text(strings.attachReport),
              subtitle: Text(strings.attachReportDescription),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(strings.markDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _VisitPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _VisitPalette.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
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
        ),
      ),
    );
  }
}

class _VisitEditorData {
  const _VisitEditorData({
    required this.visitType,
    required this.reason,
    required this.visitDate,
    required this.doctorName,
    required this.clinicName,
    required this.notes,
    required this.outcome,
    required this.nextVisitDate,
    required this.isCompleted,
    required this.amount,
    required this.currency,
    required this.shouldAttachReport,
    required this.addToCalendar,
  });

  final VisitType visitType;
  final String reason;
  final DateTime visitDate;
  final String doctorName;
  final String clinicName;
  final String notes;
  final String outcome;
  final DateTime? nextVisitDate;
  final bool isCompleted;
  final double? amount;
  final String currency;
  final bool shouldAttachReport;
  final bool addToCalendar;
}

class _VisitCompletionData {
  const _VisitCompletionData({
    required this.amount,
    required this.currency,
    required this.outcome,
    required this.shouldAttachReport,
  });

  final double amount;
  final String currency;
  final String outcome;
  final bool shouldAttachReport;
}

enum _VisitEditorAction {
  save,
  delete,
}

class _VisitEditorResult {
  const _VisitEditorResult._({
    required this.action,
    this.data,
  });

  factory _VisitEditorResult.save(_VisitEditorData data) {
    return _VisitEditorResult._(
      action: _VisitEditorAction.save,
      data: data,
    );
  }

  factory _VisitEditorResult.delete() {
    return const _VisitEditorResult._(
      action: _VisitEditorAction.delete,
    );
  }

  final _VisitEditorAction action;
  final _VisitEditorData? data;
}

class _VisitPalette {
  const _VisitPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF0E6D0);
  static const outline = Color(0xFFE3D2B4);
  static const noteBackground = Color(0xFFF1E7D6);

  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);

  static const purple = Color(0xFFB084E8);
  static const scheduledBadge = Color(0xFFF1E7FF);
  static const completedBadge = Color(0xFFF0E6D0);
}

class _VisitStrings {
  const _VisitStrings({
    required this.addVisit,
    required this.editVisit,
    required this.updateVisit,
    required this.visitTypeLabel,
    required this.visitRoutine,
    required this.visitVaccine,
    required this.visitCheckup,
    required this.visitFollowUp,
    required this.visitUrgent,
    required this.visitOther,
    required this.reasonLabel,
    required this.reasonHint,
    required this.reasonRequired,
    required this.visitDate,
    required this.doctorLabel,
    required this.doctorHint,
    required this.clinicNameLabel,
    required this.clinicNameHint,
    required this.outcomeLabel,
    required this.outcomeHint,
    required this.nextVisitDate,
    required this.notSet,
    required this.clearNextVisitDate,
    required this.notesLabel,
    required this.notesHint,
    required this.saveEntry,
    required this.entrySaved,
    required this.entryUpdated,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.edit,
    required this.cancel,
    required this.actions,
    required this.petNotFound,
    required this.all,
    required this.scheduled,
    required this.completed,
    required this.scheduledUpper,
    required this.completedUpper,
    required this.postpone,
    required this.addToCalendar,
    required this.removeFromCalendar,
    required this.addedToCalendar,
    required this.removedFromCalendar,
    required this.addToCalendarDescription,
    required this.markDone,
    required this.completeVisit,
    required this.visitCompleted,
    required this.visitAlreadyDone,
    required this.visitAlreadyDoneDescription,
    required this.amountLabel,
    required this.amountRequired,
    required this.attachReport,
    required this.attachReportDescription,
    required this.reportTitle,
    required this.reportLinkedToVisit,
    required this.openReport,
    required this.reportNotFound,
    required this.expense,
    required this.totalSpent,
    required this.reasonBoxPrefix,
  });

  final String addVisit;
  final String editVisit;
  final String updateVisit;
  final String visitTypeLabel;
  final String visitRoutine;
  final String visitVaccine;
  final String visitCheckup;
  final String visitFollowUp;
  final String visitUrgent;
  final String visitOther;
  final String reasonLabel;
  final String reasonHint;
  final String reasonRequired;
  final String visitDate;
  final String doctorLabel;
  final String doctorHint;
  final String clinicNameLabel;
  final String clinicNameHint;
  final String outcomeLabel;
  final String outcomeHint;
  final String nextVisitDate;
  final String notSet;
  final String clearNextVisitDate;
  final String notesLabel;
  final String notesHint;
  final String saveEntry;
  final String entrySaved;
  final String entryUpdated;
  final String emptyTitle;
  final String emptyDescription;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String delete;
  final String edit;
  final String cancel;
  final String actions;
  final String petNotFound;
  final String all;
  final String scheduled;
  final String completed;
  final String scheduledUpper;
  final String completedUpper;
  final String postpone;
  final String addToCalendar;
  final String removeFromCalendar;
  final String addedToCalendar;
  final String removedFromCalendar;
  final String addToCalendarDescription;
  final String markDone;
  final String completeVisit;
  final String visitCompleted;
  final String visitAlreadyDone;
  final String visitAlreadyDoneDescription;
  final String amountLabel;
  final String amountRequired;
  final String attachReport;
  final String attachReportDescription;
  final String reportTitle;
  final String reportLinkedToVisit;
  final String openReport;
  final String reportNotFound;
  final String expense;
  final String totalSpent;
  final String reasonBoxPrefix;

  String headerSubtitle({
    required int scheduledCount,
    required int completedCount,
  }) {
    return '$scheduledCount programmate · $completedCount svolte';
  }

  String visitTypeLabelFor(VisitType visitType) {
    return switch (visitType) {
      VisitType.routine => visitRoutine,
      VisitType.vaccine => visitVaccine,
      VisitType.checkup => visitCheckup,
      VisitType.followUp => visitFollowUp,
      VisitType.urgent => visitUrgent,
      VisitType.other => visitOther,
    };
  }

  static _VisitStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _VisitStrings(
        addVisit: 'Add visit',
        editVisit: 'Edit visit',
        updateVisit: 'Update visit',
        visitTypeLabel: 'Visit type',
        visitRoutine: 'Routine',
        visitVaccine: 'Vaccine',
        visitCheckup: 'Checkup',
        visitFollowUp: 'Follow-up',
        visitUrgent: 'Urgent',
        visitOther: 'Other',
        reasonLabel: 'Reason',
        reasonHint: 'E.g. Annual checkup',
        reasonRequired: 'Enter the visit reason',
        visitDate: 'Visit date',
        doctorLabel: 'Veterinarian',
        doctorHint: 'Optional',
        clinicNameLabel: 'Clinic',
        clinicNameHint: 'Optional',
        outcomeLabel: 'Vet summary',
        outcomeHint: 'Optional. Enter only information provided by the vet.',
        nextVisitDate: 'Next visit',
        notSet: 'Not set',
        clearNextVisitDate: 'Clear next visit',
        notesLabel: 'Reason / notes',
        notesHint: 'E.g. Response check after therapy',
        saveEntry: 'Save visit',
        entrySaved: 'Visit saved',
        entryUpdated: 'Visit updated',
        emptyTitle: 'No visits',
        emptyDescription: 'Add scheduled or past vet visits.',
        deleteEntryTitle: 'Delete this visit?',
        deleteEntryMessage: 'This removes the visit from local history.',
        entryDeleted: 'Visit deleted',
        delete: 'Delete',
        edit: 'Edit',
        cancel: 'Cancel',
        actions: 'Actions',
        petNotFound: 'Pet not found',
        all: 'All',
        scheduled: 'Upcoming',
        completed: 'Done',
        scheduledUpper: 'UPCOMING',
        completedUpper: 'DONE',
        postpone: 'Postpone',
        addToCalendar: 'Add to calendar',
        removeFromCalendar: 'Remove',
        addedToCalendar: 'Visit added to calendar and reminders',
        removedFromCalendar: 'Visit removed from calendar and reminders',
        addToCalendarDescription:
            'Creates a reminder for this visit and shows it in the calendar.',
        markDone: 'Done',
        completeVisit: 'Complete visit',
        visitCompleted: 'Visit completed',
        visitAlreadyDone: 'This visit already happened',
        visitAlreadyDoneDescription:
            'Past visits require the amount and can include a report.',
        amountLabel: 'Amount',
        amountRequired: 'Enter a valid amount',
        attachReport: 'Attach report',
        attachReportDescription: 'You can upload a document after saving.',
        reportTitle: 'Visit report',
        reportLinkedToVisit: 'Linked to a visit',
        openReport: 'Open report',
        reportNotFound: 'Report not found',
        expense: 'Expense',
        totalSpent: 'Spent in visits',
        reasonBoxPrefix: 'Reason',
      );
    }

    return const _VisitStrings(
      addVisit: 'Aggiungi visita',
      editVisit: 'Modifica visita',
      updateVisit: 'Aggiorna visita',
      visitTypeLabel: 'Tipo visita',
      visitRoutine: 'Routine',
      visitVaccine: 'Vaccino',
      visitCheckup: 'Controllo',
      visitFollowUp: 'Follow-up',
      visitUrgent: 'Urgente',
      visitOther: 'Altro',
      reasonLabel: 'Motivo',
      reasonHint: 'Es. Visita di controllo',
      reasonRequired: 'Inserisci il motivo della visita',
      visitDate: 'Data visita',
      doctorLabel: 'Veterinario',
      doctorHint: 'Es. Dr.ssa Conti',
      clinicNameLabel: 'Clinica',
      clinicNameHint: 'Es. AnimalCare Milano',
      outcomeLabel: 'Esito / riepilogo',
      outcomeHint: 'Inserisci solo informazioni fornite dal veterinario.',
      nextVisitDate: 'Prossima visita',
      notSet: 'Non impostata',
      clearNextVisitDate: 'Rimuovi prossima visita',
      notesLabel: 'Motivo / note',
      notesHint: 'Es. Verifica risposta a Gabapentin',
      saveEntry: 'Salva visita',
      entrySaved: 'Visita salvata',
      entryUpdated: 'Visita aggiornata',
      emptyTitle: 'Nessuna visita',
      emptyDescription: 'Aggiungi visite programmate o visite già svolte.',
      deleteEntryTitle: 'Eliminare questa visita?',
      deleteEntryMessage: 'La visita verrà rimossa dallo storico locale.',
      entryDeleted: 'Visita eliminata',
      delete: 'Elimina',
      edit: 'Modifica',
      cancel: 'Annulla',
      actions: 'Azioni',
      petNotFound: 'Pet non trovato',
      all: 'Tutte',
      scheduled: 'In arrivo',
      completed: 'Svolte',
      scheduledUpper: 'IN ARRIVO',
      completedUpper: 'SVOLTA',
      postpone: 'Rimanda',
      addToCalendar: 'Aggiungi al calendario',
      removeFromCalendar: 'Rimuovi',
      addedToCalendar: 'Visita aggiunta a calendario e promemoria',
      removedFromCalendar: 'Visita rimossa da calendario e promemoria',
      addToCalendarDescription:
          'Crea un promemoria per questa visita e la mostra nel calendario.',
      markDone: 'Svolta',
      completeVisit: 'Chiudi visita',
      visitCompleted: 'Visita segnata come svolta',
      visitAlreadyDone: 'Questa visita è già stata svolta',
      visitAlreadyDoneDescription:
          'Per visite passate o chiuse serve l’importo e puoi caricare il referto.',
      amountLabel: 'Importo',
      amountRequired: 'Inserisci un importo valido',
      attachReport: 'Carica referto',
      attachReportDescription:
          'Potrai selezionare un documento dopo il salvataggio.',
      reportTitle: 'Referto visita',
      reportLinkedToVisit: 'Collegato a una visita',
      openReport: 'Apri referto',
      reportNotFound: 'Referto non trovato',
      expense: 'Spesa',
      totalSpent: 'Speso in visite',
      reasonBoxPrefix: 'Motivo',
    );
  }
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}