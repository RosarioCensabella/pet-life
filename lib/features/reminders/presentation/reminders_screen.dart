import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/pet_life_navigation_bar.dart';
import '../../documents/application/document_file_service.dart';
import '../../documents/application/document_file_service_provider.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../documents/domain/pet_document.dart';
import '../../expenses/application/expense_controller.dart';
import '../../expenses/domain/expense_entry.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../visits/application/visit_controller.dart';
import '../../visits/domain/visit_entry.dart';
import '../application/reminder_controller.dart';
import '../domain/reminder.dart';

enum _ReminderFilter {
  active,
  completed,
  all,
}

enum _ReminderAction {
  complete,
  postpone,
  skip,
}

const String _allPetsFilterId = '__all_pets__';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({
    this.petId,
    super.key,
  });

  final String? petId;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  _ReminderFilter _filter = _ReminderFilter.active;
  late String _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId ?? _allPetsFilterId;
  }

  @override
  void didUpdateWidget(covariant RemindersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.petId != widget.petId) {
      _selectedPetId = widget.petId ?? _allPetsFilterId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(reminderControllerProvider);
    final petsState = ref.watch(petControllerProvider);
    ref.watch(visitControllerProvider);

    return Scaffold(
      backgroundColor: _ReminderPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final activePets = pets.where((pet) => !pet.isArchived).toList();
            final effectiveSelectedPetId = _effectiveSelectedPetId(activePets);

            return remindersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (reminders) {
                final remindersForPet = _applyPetFilter(
                  reminders,
                  effectiveSelectedPetId,
                );

                final sortedReminders = [...remindersForPet]
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                final activeCount = sortedReminders
                    .where(
                      (reminder) => reminder.status == ReminderStatus.active,
                    )
                    .length;

                final filteredReminders = _filteredReminders(sortedReminders);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  children: [
                    _ReminderHeader(
                      title: 'Promemoria',
                      subtitle: '$activeCount attivi',
                      onAdd: () => _openAddReminder(effectiveSelectedPetId),
                    ),
                    const SizedBox(height: 12),
                    _StatusFilterRow(
                      selectedFilter: _filter,
                      onChanged: (filter) {
                        setState(() {
                          _filter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (activePets.isNotEmpty)
                      _PetFilterRow(
                        pets: activePets,
                        selectedPetId: effectiveSelectedPetId,
                        onChanged: (petId) {
                          setState(() {
                            _selectedPetId = petId;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    if (filteredReminders.isEmpty)
                      _EmptyRemindersState(
                        title: _emptyTitle,
                        description: _emptyDescription,
                        onPressed: () =>
                            _openAddReminder(effectiveSelectedPetId),
                      )
                    else
                      ...filteredReminders.map(
                        (reminder) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReminderTile(
                            reminder: reminder,
                            dateLabel: _formatReminderDate(
                              context,
                              reminder.scheduledAt,
                            ),
                            statusLabel: _statusLabel(reminder.status),
                            onCompleteTap: () => _completeReminder(reminder),
                            onActionSelected: (action) {
                              switch (action) {
                                case _ReminderAction.complete:
                                  _completeReminder(reminder);
                                case _ReminderAction.postpone:
                                  _postponeReminder(reminder);
                                case _ReminderAction.skip:
                                  _skipReminder(reminder);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const PetLifeNavigationBar(
        selectedDestination: PetLifeDestination.reminders,
      ),
    );
  }

  String _effectiveSelectedPetId(List<Pet> pets) {
    if (_selectedPetId == _allPetsFilterId) {
      return _allPetsFilterId;
    }

    final exists = pets.any((pet) => pet.id == _selectedPetId);

    if (exists) {
      return _selectedPetId;
    }

    return _allPetsFilterId;
  }

  List<Reminder> _applyPetFilter(
    List<Reminder> reminders,
    String selectedPetId,
  ) {
    if (selectedPetId == _allPetsFilterId) {
      return reminders.toList(growable: false);
    }

    return reminders
        .where((reminder) => reminder.petId == selectedPetId)
        .toList(growable: false);
  }

  List<Reminder> _filteredReminders(List<Reminder> reminders) {
    switch (_filter) {
      case _ReminderFilter.active:
        return reminders
            .where((reminder) => reminder.status == ReminderStatus.active)
            .toList(growable: false);
      case _ReminderFilter.completed:
        return reminders
            .where((reminder) => reminder.status != ReminderStatus.active)
            .toList(growable: false);
      case _ReminderFilter.all:
        return reminders;
    }
  }

  String get _emptyTitle {
    switch (_filter) {
      case _ReminderFilter.active:
        return 'Nessun promemoria attivo';
      case _ReminderFilter.completed:
        return 'Nessun promemoria completato';
      case _ReminderFilter.all:
        return 'Nessun promemoria';
    }
  }

  String get _emptyDescription {
    switch (_filter) {
      case _ReminderFilter.active:
        return 'Non ci sono promemoria attivi per il filtro selezionato.';
      case _ReminderFilter.completed:
        return 'Non ci sono promemoria completati o rimandati per il filtro selezionato.';
      case _ReminderFilter.all:
        return 'Non ci sono promemoria per il filtro selezionato.';
    }
  }

  void _openAddReminder(String selectedPetId) {
    if (selectedPetId == _allPetsFilterId) {
      context.push('/reminders/new');
      return;
    }

    context.push('/pets/$selectedPetId/reminders/new');
  }

  Future<void> _completeReminder(Reminder reminder) async {
    final visitId = _visitIdFromReminder(reminder);

    if (visitId != null) {
      final visit = ref.read(visitControllerProvider.notifier).visitById(
            visitId,
          );

      if (visit != null && visit.status == VisitStatus.scheduled) {
        await _completeVisitReminder(
          reminder: reminder,
          visit: visit,
        );
        return;
      }
    }

    await ref
        .read(reminderControllerProvider.notifier)
        .completeReminder(reminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promemoria completato'),
      ),
    );
  }

  Future<void> _completeVisitReminder({
    required Reminder reminder,
    required VisitEntry visit,
  }) async {
    final result = await showModalBottomSheet<_VisitReminderCompletionData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _VisitReminderCompletionSheet(visit: visit);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    if (visit.expenseEntryId != null) {
      await ref
          .read(expenseControllerProvider.notifier)
          .deleteEntry(visit.expenseEntryId!);
    }

    final expenseEntryId = 'expense-visit-${visit.id}';
    String? reportDocumentId = visit.reportDocumentId;

    await ref.read(expenseControllerProvider.notifier).addEntry(
          ExpenseEntry(
            id: expenseEntryId,
            petId: visit.petId,
            petName: visit.petName,
            category: ExpenseCategory.vet,
            description: visit.reason,
            amount: result.amount,
            currency: result.currency,
            expenseDate: now,
            createdAt: now,
            vendor: visit.clinicName,
            notes: _optionalText(result.outcome),
          ),
        );

    if (result.shouldAttachReport) {
      final documentId = 'visit-report-${visit.id}-${now.microsecondsSinceEpoch}';

      final pickedDocument = await ref
          .read(documentFileServiceProvider)
          .pickAndCopyDocument(
            petId: visit.petId,
            documentId: documentId,
          );

      if (pickedDocument is PickedLocalDocument) {
        reportDocumentId = documentId;

        await ref.read(petDocumentControllerProvider.notifier).addDocument(
              PetDocument(
                id: documentId,
                petId: visit.petId,
                petName: visit.petName,
                title: 'Referto visita · ${visit.reason}',
                category: PetDocumentCategory.labReport,
                originalFileName: pickedDocument.originalFileName,
                localPath: pickedDocument.localPath,
                sizeBytes: pickedDocument.sizeBytes,
                createdAt: now,
                notes: 'Collegato a una visita',
              ),
            );
      }
    }

    final updatedVisit = visit.copyWith(
      status: VisitStatus.completed,
      visitDate: visit.visitDate.isAfter(now) ? now : visit.visitDate,
      completedAt: now,
      outcome: _optionalText(result.outcome),
      amount: result.amount,
      currency: result.currency,
      expenseEntryId: expenseEntryId,
      reportDocumentId: reportDocumentId,
      addToCalendar: false,
      automaticReminderIds: const [],
      updatedAt: now,
    );

    await ref.read(visitControllerProvider.notifier).updateEntry(updatedVisit);

    final linkedReminderIds = <String>{
      reminder.id,
      ...visit.automaticReminderIds,
      ..._linkedVisitReminderIds(visit),
    };

    await ref
        .read(reminderControllerProvider.notifier)
        .deleteReminders(linkedReminderIds.toList(growable: false));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visita segnata come svolta'),
      ),
    );
  }

  List<String> _linkedVisitReminderIds(VisitEntry visit) {
    final reminders =
        ref.read(reminderControllerProvider).valueOrNull ?? const <Reminder>[];

    return reminders
        .where(
          (reminder) =>
              reminder.id.startsWith('visit-${visit.id}-') ||
              (reminder.notes?.contains('visitId:${visit.id}') ?? false),
        )
        .map((reminder) => reminder.id)
        .toList(growable: false);
  }

  String? _visitIdFromReminder(Reminder reminder) {
    final notes = reminder.notes ?? '';

    for (final line in notes.split('\n')) {
      final trimmed = line.trim();

      if (trimmed.startsWith('visitId:')) {
        return trimmed.substring('visitId:'.length).trim();
      }
    }

    if (reminder.id.startsWith('visit-') && reminder.id.endsWith('-reminder')) {
      return reminder.id.substring(
        'visit-'.length,
        reminder.id.length - '-reminder'.length,
      );
    }

    return null;
  }

  Future<void> _postponeReminder(Reminder reminder) async {
    await ref
        .read(reminderControllerProvider.notifier)
        .postponeReminderByOneDay(reminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promemoria rimandato di un giorno'),
      ),
    );
  }

  Future<void> _skipReminder(Reminder reminder) async {
    await ref
        .read(reminderControllerProvider.notifier)
        .skipReminder(reminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promemoria saltato'),
      ),
    );
  }

  String _formatReminderDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('EEE dd MMM', locale)
        .format(date)
        .replaceAll('.', '');
    final timeLabel = DateFormat.Hm(locale).format(date);

    return '${_capitalize(dayLabel)} · $timeLabel';
  }

  String _statusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.active:
        return 'attivo';
      case ReminderStatus.completed:
        return 'completato';
      case ReminderStatus.postponed:
        return 'rimandato';
      case ReminderStatus.skipped:
        return 'saltato';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: _ReminderPalette.darkText,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _ReminderPalette.secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: _ReminderPalette.chip,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAdd,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.add,
                size: 22,
                color: _ReminderPalette.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _ReminderFilter selectedFilter;
  final ValueChanged<_ReminderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Attivi',
          selected: selectedFilter == _ReminderFilter.active,
          onTap: () => onChanged(_ReminderFilter.active),
        ),
        _FilterChipButton(
          label: 'Completati',
          selected: selectedFilter == _ReminderFilter.completed,
          onTap: () => onChanged(_ReminderFilter.completed),
        ),
        _FilterChipButton(
          label: 'Tutti',
          selected: selectedFilter == _ReminderFilter.all,
          onTap: () => onChanged(_ReminderFilter.all),
        ),
      ],
    );
  }
}

class _PetFilterRow extends StatelessWidget {
  const _PetFilterRow({
    required this.pets,
    required this.selectedPetId,
    required this.onChanged,
  });

  final List<Pet> pets;
  final String selectedPetId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Tutti',
          selected: selectedPetId == _allPetsFilterId,
          onTap: () => onChanged(_allPetsFilterId),
        ),
        for (final pet in pets)
          _PetFilterChipButton(
            label: pet.name,
            color: _visiblePetColor(Color(pet.colorValue)),
            selected: selectedPetId == pet.id,
            onTap: () => onChanged(pet.id),
          ),
      ],
    );
  }

  Color _visiblePetColor(Color color) {
    if (color.computeLuminance() > 0.82) {
      return _ReminderPalette.orange;
    }

    return color;
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
    final background =
        selected ? _ReminderPalette.selectedChip : _ReminderPalette.chip;
    final foreground =
        selected ? Colors.white : _ReminderPalette.secondaryText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
          ),
        ),
      ),
    );
  }
}

class _PetFilterChipButton extends StatelessWidget {
  const _PetFilterChipButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _ReminderPalette.selectedChip : _ReminderPalette.chip;
    final foreground =
        selected ? Colors.white : _ReminderPalette.secondaryText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.dateLabel,
    required this.statusLabel,
    required this.onCompleteTap,
    required this.onActionSelected,
  });

  final Reminder reminder;
  final String dateLabel;
  final String statusLabel;
  final VoidCallback onCompleteTap;
  final ValueChanged<_ReminderAction> onActionSelected;

  bool get _isCompleted => reminder.status == ReminderStatus.completed;
  bool get _isPostponed => reminder.status == ReminderStatus.postponed;
  bool get _isSkipped => reminder.status == ReminderStatus.skipped;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconForCategory(reminder.category);
    final accent = _colorForCategory(reminder.category);

    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _ReminderPalette.secondaryText,
        );

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: _isCompleted || _isSkipped
              ? _ReminderPalette.secondaryText
              : _ReminderPalette.darkText,
          decoration:
              _isCompleted || _isSkipped ? TextDecoration.lineThrough : null,
          decorationColor: _ReminderPalette.secondaryText,
          decorationThickness: 2,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ReminderPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _ReminderPalette.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              _LeadingStatusButton(
                status: reminder.status,
                color: accent,
                onTap: reminder.status == ReminderStatus.active
                    ? onCompleteTap
                    : null,
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reminder.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: metaStyle,
                        ),
                        Expanded(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                        if (_isPostponed) ...[
                          const SizedBox(width: 8),
                          Text(
                            statusLabel,
                            style: metaStyle?.copyWith(
                              color: _ReminderPalette.purple,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ReminderMenuButton(
                onSelected: onActionSelected,
                canComplete: reminder.status == ReminderStatus.active,
                canPostpone: reminder.status == ReminderStatus.active,
                canSkip: reminder.status == ReminderStatus.active,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.vaccine:
        return Icons.shield_outlined;
      case ReminderCategory.antiparasitic:
        return Icons.water_drop_outlined;
      case ReminderCategory.vetVisit:
        return Icons.medical_services_outlined;
      case ReminderCategory.checkup:
        return Icons.health_and_safety_outlined;
      case ReminderCategory.medication:
        return Icons.medication_liquid_outlined;
      case ReminderCategory.insurance:
        return Icons.verified_user_outlined;
      case ReminderCategory.grooming:
        return Icons.content_cut_rounded;
      case ReminderCategory.custom:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForCategory(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.vaccine:
        return _ReminderPalette.orange;
      case ReminderCategory.antiparasitic:
        return _ReminderPalette.orange;
      case ReminderCategory.vetVisit:
        return _ReminderPalette.purple;
      case ReminderCategory.checkup:
        return _ReminderPalette.green;
      case ReminderCategory.medication:
        return _ReminderPalette.purple;
      case ReminderCategory.insurance:
        return _ReminderPalette.green;
      case ReminderCategory.grooming:
        return _ReminderPalette.orange;
      case ReminderCategory.custom:
        return _ReminderPalette.purple;
    }
  }
}

class _LeadingStatusButton extends StatelessWidget {
  const _LeadingStatusButton({
    required this.status,
    required this.color,
    this.onTap,
  });

  final ReminderStatus status;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == ReminderStatus.completed;
    final isSkipped = status == ReminderStatus.skipped;
    final isDone = isCompleted || isSkipped;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDone ? color.withValues(alpha: 0.55) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? color.withValues(alpha: 0.55)
                  : _ReminderPalette.outline,
              width: 1.2,
            ),
          ),
          child: isDone
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _ReminderMenuButton extends StatelessWidget {
  const _ReminderMenuButton({
    required this.onSelected,
    required this.canComplete,
    required this.canPostpone,
    required this.canSkip,
  });

  final ValueChanged<_ReminderAction> onSelected;
  final bool canComplete;
  final bool canPostpone;
  final bool canSkip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReminderAction>(
      onSelected: onSelected,
      enabled: canComplete || canPostpone || canSkip,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<_ReminderAction>>[];

        if (canComplete) {
          items.add(
            const PopupMenuItem(
              value: _ReminderAction.complete,
              child: Text('Segna come fatto'),
            ),
          );
        }

        if (canPostpone) {
          items.add(
            const PopupMenuItem(
              value: _ReminderAction.postpone,
              child: Text('Rimanda di 1 giorno'),
            ),
          );
        }

        if (canSkip) {
          items.add(
            const PopupMenuItem(
              value: _ReminderAction.skip,
              child: Text('Salta'),
            ),
          );
        }

        return items;
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: _ReminderPalette.chip,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '⋯',
          style: TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w700,
            color: _ReminderPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _VisitReminderCompletionSheet extends StatefulWidget {
  const _VisitReminderCompletionSheet({
    required this.visit,
  });

  final VisitEntry visit;

  @override
  State<_VisitReminderCompletionSheet> createState() =>
      _VisitReminderCompletionSheetState();
}

class _VisitReminderCompletionSheetState
    extends State<_VisitReminderCompletionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _outcomeController = TextEditingController();

  String _currency = 'EUR';
  bool _shouldAttachReport = false;

  @override
  void initState() {
    super.initState();

    _currency = widget.visit.currency;
    _amountController.text = widget.visit.amount == null
        ? ''
        : _formatNumber(widget.visit.amount!);
    _outcomeController.text = widget.visit.outcome ?? '';
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
      _VisitReminderCompletionData(
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _ReminderPalette.background,
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
                    'Chiudi visita',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _ReminderPalette.darkText,
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    widget.visit.reason,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _ReminderPalette.darkText,
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
                    decoration: const InputDecoration(
                      labelText: 'Importo',
                      hintText: '65,00',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );

                      if (amount == null || amount < 0) {
                        return 'Inserisci un importo valido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _outcomeController,
                    decoration: const InputDecoration(
                      labelText: 'Esito / riepilogo',
                      hintText:
                          'Inserisci solo informazioni fornite dal veterinario.',
                      border: OutlineInputBorder(),
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
                    title: const Text('Carica referto'),
                    subtitle: const Text(
                      'Potrai selezionare un documento dopo il salvataggio.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Svolta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitReminderCompletionData {
  const _VisitReminderCompletionData({
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

class _EmptyRemindersState extends StatelessWidget {
  const _EmptyRemindersState({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ReminderPalette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ReminderPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: Column(
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 42,
              color: _ReminderPalette.secondaryText,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _ReminderPalette.darkText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ReminderPalette.secondaryText,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: _ReminderPalette.selectedChip,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi promemoria'),
            ),
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

class _ReminderPalette {
  const _ReminderPalette._();

  static const background = Color(0xFFF8F4E8);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF2EAD8);
  static const selectedChip = Color(0xFF2C2418);
  static const outline = Color(0xFFE6D9BE);

  static const darkText = Color(0xFF33291F);
  static const secondaryText = Color(0xFF8C7A66);

  static const orange = Color(0xFFE9B14A);
  static const purple = Color(0xFFB38BE8);
  static const green = Color(0xFFA8CDAF);
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}