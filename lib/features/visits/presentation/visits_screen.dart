import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _notesController = TextEditingController();

  VisitType _selectedVisitType = VisitType.routine;
  DateTime _visitDate = DateTime.now();
  DateTime? _nextVisitDate;

  @override
  void dispose() {
    _reasonController.dispose();
    _clinicNameController.dispose();
    _outcomeController.dispose();
    _notesController.dispose();
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

    setState(() {
      _visitDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _visitDate.hour,
        _visitDate.minute,
      );
    });
  }

  Future<void> _selectNextVisitDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now(),
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

  Future<void> _saveEntry(Pet pet, _VisitStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();
    final clinicName = _clinicNameController.text.trim();
    final outcome = _outcomeController.text.trim();
    final notes = _notesController.text.trim();

    final entry = VisitEntry(
      id: 'visit-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      visitType: _selectedVisitType,
      reason: _reasonController.text.trim(),
      visitDate: _visitDate,
      createdAt: now,
      clinicName: clinicName.isEmpty ? null : clinicName,
      outcome: outcome.isEmpty ? null : outcome,
      nextVisitDate: _nextVisitDate,
      notes: notes.isEmpty ? null : notes,
    );

    await ref.read(visitControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _reasonController.clear();
    _clinicNameController.clear();
    _outcomeController.clear();
    _notesController.clear();

    setState(() {
      _selectedVisitType = VisitType.routine;
      _visitDate = DateTime.now();
      _nextVisitDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
  }

  Future<void> _confirmDelete(
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

    await ref.read(visitControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _VisitStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final visitState = ref.watch(visitControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, widget.petId);

            if (pet == null) {
              return _PetNotFoundState(
                title: strings.petNotFound,
                onBack: () => context.go('/home'),
              );
            }

            return visitState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

                final nextVisitCount =
                    petEntries.where((entry) => entry.nextVisitDate != null).length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _TopBar(
                      title: strings.visitsTitle,
                      onBack: () => context.go('/pets/${pet.id}'),
                    ),
                    const SizedBox(height: 12),
                    _HeroCard(
                      strings: strings,
                      totalCount: petEntries.length,
                      nextVisitCount: nextVisitCount,
                    ),
                    const SizedBox(height: 12),
                    _DisclaimerCard(strings: strings),
                    const SizedBox(height: 12),
                    _VisitSummaryCard(
                      strings: strings,
                      entries: petEntries,
                    ),
                    const SizedBox(height: 12),
                    _AddVisitEntryCard(
                      formKey: _formKey,
                      reasonController: _reasonController,
                      clinicNameController: _clinicNameController,
                      outcomeController: _outcomeController,
                      notesController: _notesController,
                      selectedVisitType: _selectedVisitType,
                      visitDate: _visitDate,
                      nextVisitDate: _nextVisitDate,
                      strings: strings,
                      onVisitTypeChanged: (visitType) {
                        if (visitType == null) {
                          return;
                        }

                        setState(() {
                          _selectedVisitType = visitType;
                        });
                      },
                      onSelectVisitDate: _selectVisitDate,
                      onSelectNextVisitDate: _selectNextVisitDate,
                      onClearNextVisitDate: () {
                        setState(() {
                          _nextVisitDate = null;
                        });
                      },
                      onSave: () => _saveEntry(pet, strings),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: strings.historyTitle,
                      count: petEntries.length,
                    ),
                    const SizedBox(height: 8),
                    if (petEntries.isEmpty)
                      _EmptyVisitCard(strings: strings)
                    else
                      ...petEntries.map(
                        (entry) => _VisitEntryCard(
                          entry: entry,
                          strings: strings,
                          onDelete: () => _confirmDelete(entry, strings),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final strings = _VisitStrings.of(context);

    return Row(
      children: [
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: strings.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.strings,
    required this.totalCount,
    required this.nextVisitCount,
  });

  final _VisitStrings strings;
  final int totalCount;
  final int nextVisitCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.primaryBrown,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        boxShadow: [PetLifeDesign.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.visitsTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.heroSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DarkPill(
                        icon: Icons.list_alt_outlined,
                        label: '$totalCount ${strings.entriesLabel}',
                      ),
                      _DarkPill(
                        icon: Icons.event_available_outlined,
                        label: '$nextVisitCount ${strings.nextVisitsShort}',
                      ),
                    ],
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

class _DarkPill extends StatelessWidget {
  const _DarkPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.strings,
  });

  final _VisitStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: const Color(0xFFF0D6BF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB87841),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({
    required this.strings,
    required this.entries,
  });

  final _VisitStrings strings;
  final List<VisitEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latestEntry = entries.isEmpty ? null : entries.first;

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF5A8BB8).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: Color(0xFF5A8BB8),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: latestEntry == null
                  ? Text(
                      strings.noVisitSummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.latestVisit,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: PetLifeDesign.secondaryBrown,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.visitTypeLabelFor(latestEntry.visitType),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.latestVisitSummary,
                          style: Theme.of(context).textTheme.bodySmall,
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

class _AddVisitEntryCard extends StatelessWidget {
  const _AddVisitEntryCard({
    required this.formKey,
    required this.reasonController,
    required this.clinicNameController,
    required this.outcomeController,
    required this.notesController,
    required this.selectedVisitType,
    required this.visitDate,
    required this.nextVisitDate,
    required this.strings,
    required this.onVisitTypeChanged,
    required this.onSelectVisitDate,
    required this.onSelectNextVisitDate,
    required this.onClearNextVisitDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController reasonController;
  final TextEditingController clinicNameController;
  final TextEditingController outcomeController;
  final TextEditingController notesController;
  final VisitType selectedVisitType;
  final DateTime visitDate;
  final DateTime? nextVisitDate;
  final _VisitStrings strings;
  final ValueChanged<VisitType?> onVisitTypeChanged;
  final VoidCallback onSelectVisitDate;
  final VoidCallback onSelectNextVisitDate;
  final VoidCallback onClearNextVisitDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final visitDateLabel = DateFormat.yMMMd(locale).format(visitDate);
    final nextVisitDateLabel = nextVisitDate == null
        ? strings.notSet
        : DateFormat.yMMMd(locale).format(nextVisitDate!);

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                icon: Icons.add_rounded,
                title: strings.addEntry,
                subtitle: strings.formSubtitle,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VisitType>(
                key: ValueKey('visit-type-$selectedVisitType'),
                initialValue: selectedVisitType,
                decoration: InputDecoration(
                  labelText: strings.visitTypeLabel,
                ),
                items: VisitType.values
                    .map(
                      (visitType) => DropdownMenuItem(
                        value: visitType,
                        child: Text(strings.visitTypeLabelFor(visitType)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onVisitTypeChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: strings.reasonLabel,
                  hintText: strings.reasonHint,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.reasonRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateActionTile(
                icon: Icons.event_outlined,
                title: strings.visitDate,
                value: visitDateLabel,
                onTap: onSelectVisitDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: clinicNameController,
                decoration: InputDecoration(
                  labelText: strings.clinicNameLabel,
                  hintText: strings.clinicNameHint,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: outcomeController,
                decoration: InputDecoration(
                  labelText: strings.outcomeLabel,
                  hintText: strings.outcomeHint,
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _DateActionTile(
                icon: Icons.event_available_outlined,
                title: strings.nextVisitDate,
                value: nextVisitDateLabel,
                onTap: onSelectNextVisitDate,
              ),
              if (nextVisitDate != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onClearNextVisitDate,
                    icon: const Icon(Icons.close_outlined),
                    label: Text(strings.clearNextVisitDate),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: strings.notesLabel,
                  hintText: strings.notesHint,
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.saveEntry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateActionTile extends StatelessWidget {
  const _DateActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PetLifeDesign.softSurface.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: PetLifeDesign.secondaryBrown,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF5A8BB8).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5A8BB8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PetLifeDesign.softSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVisitCard extends StatelessWidget {
  const _EmptyVisitCard({
    required this.strings,
  });

  final _VisitStrings strings;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF5A8BB8).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                size: 34,
                color: Color(0xFF5A8BB8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.emptyDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitEntryCard extends StatelessWidget {
  const _VisitEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final VisitEntry entry;
  final _VisitStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final visitDateLabel = DateFormat.yMMMd(locale).format(entry.visitDate);
    final nextVisitDateLabel = entry.nextVisitDate == null
        ? null
        : DateFormat.yMMMd(locale).format(entry.nextVisitDate!);
    final accentColor = _colorForVisitType(entry.visitType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(PetLifeDesign.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _iconForVisitType(entry.visitType),
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _InfoPill(
                                color: accentColor,
                                icon: _iconForVisitType(entry.visitType),
                                label: strings.visitTypeLabelFor(
                                  entry.visitType,
                                ),
                              ),
                              _InfoPill(
                                color: PetLifeDesign.secondaryBrown,
                                icon: Icons.schedule_outlined,
                                label: visitDateLabel,
                              ),
                              _InfoPill(
                                color: accentColor,
                                icon: Icons.pets_outlined,
                                label: entry.petName,
                              ),
                            ],
                          ),
                          if (entry.clinicName != null &&
                              entry.clinicName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${strings.clinicNameShort}: ${entry.clinicName!}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (entry.outcome != null &&
                              entry.outcome!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${strings.outcomeShort}: ${entry.outcome!}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (nextVisitDateLabel != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${strings.nextVisitDate}: $nextVisitDateLabel',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (entry.notes != null &&
                              entry.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              entry.notes!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
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
          ],
        ),
      ),
    );
  }

  Color _colorForVisitType(VisitType visitType) {
    return switch (visitType) {
      VisitType.routine => const Color(0xFF5A8BB8),
      VisitType.vaccine => const Color(0xFF72A980),
      VisitType.checkup => const Color(0xFF8F7AE5),
      VisitType.followUp => const Color(0xFFE49D4F),
      VisitType.urgent => const Color(0xFFC85B4A),
      VisitType.other => const Color(0xFF9C6ADE),
    };
  }

  IconData _iconForVisitType(VisitType visitType) {
    return switch (visitType) {
      VisitType.routine => Icons.local_hospital_outlined,
      VisitType.vaccine => Icons.vaccines_outlined,
      VisitType.checkup => Icons.event_available_outlined,
      VisitType.followUp => Icons.replay_outlined,
      VisitType.urgent => Icons.warning_amber_rounded,
      VisitType.other => Icons.description_outlined,
    };
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: child,
    );
  }
}

class _PetNotFoundState extends StatelessWidget {
  const _PetNotFoundState({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SoftCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onBack,
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
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

class _VisitStrings {
  const _VisitStrings({
    required this.back,
    required this.visitsTitle,
    required this.heroSubtitle,
    required this.entriesLabel,
    required this.nextVisitsShort,
    required this.historyTitle,
    required this.formSubtitle,
    required this.latestVisit,
    required this.latestVisitSummary,
    required this.noVisitSummary,
    required this.addEntry,
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
    required this.clinicNameLabel,
    required this.clinicNameHint,
    required this.clinicNameShort,
    required this.outcomeLabel,
    required this.outcomeHint,
    required this.outcomeShort,
    required this.nextVisitDate,
    required this.notSet,
    required this.clearNextVisitDate,
    required this.notesLabel,
    required this.notesHint,
    required this.saveEntry,
    required this.entrySaved,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
  });

  final String back;
  final String visitsTitle;
  final String heroSubtitle;
  final String entriesLabel;
  final String nextVisitsShort;
  final String historyTitle;
  final String formSubtitle;
  final String latestVisit;
  final String latestVisitSummary;
  final String noVisitSummary;
  final String addEntry;
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
  final String clinicNameLabel;
  final String clinicNameHint;
  final String clinicNameShort;
  final String outcomeLabel;
  final String outcomeHint;
  final String outcomeShort;
  final String nextVisitDate;
  final String notSet;
  final String clearNextVisitDate;
  final String notesLabel;
  final String notesHint;
  final String saveEntry;
  final String entrySaved;
  final String emptyTitle;
  final String emptyDescription;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;

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
        back: 'Back',
        visitsTitle: 'Visits',
        heroSubtitle:
            'Keep vet appointments, outcomes and follow-ups organized.',
        entriesLabel: 'entries',
        nextVisitsShort: 'next visits',
        historyTitle: 'Visit history',
        formSubtitle:
            'Save only visit details and information provided by your veterinarian.',
        latestVisit: 'Latest visit',
        latestVisitSummary: 'Most recent saved appointment',
        noVisitSummary: 'No visits recorded yet',
        addEntry: 'Add visit',
        visitTypeLabel: 'Visit type',
        visitRoutine: 'Routine',
        visitVaccine: 'Vaccine',
        visitCheckup: 'Checkup',
        visitFollowUp: 'Follow-up',
        visitUrgent: 'Urgent visit record',
        visitOther: 'Other',
        reasonLabel: 'Reason',
        reasonHint: 'E.g. veterinary appointment',
        reasonRequired: 'Enter the reason for the visit',
        visitDate: 'Visit date',
        clinicNameLabel: 'Veterinarian / clinic',
        clinicNameHint: 'Optional',
        clinicNameShort: 'Vet / clinic',
        outcomeLabel: 'Outcome or vet summary',
        outcomeHint:
            'Optional. Enter only information provided by your veterinarian.',
        outcomeShort: 'Outcome',
        nextVisitDate: 'Next visit',
        notSet: 'Not set',
        clearNextVisitDate: 'Clear next visit',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save visit',
        entrySaved: 'Visit saved',
        emptyTitle: 'No visits',
        emptyDescription:
            'Add vet visits to keep appointments and notes organized.',
        deleteEntryTitle: 'Delete this visit?',
        deleteEntryMessage:
            'This removes the visit from the local history.',
        entryDeleted: 'Visit deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Visit tracking is only for organization. Pet Life does not generate diagnoses, interpret medical records, triage symptoms or replace your veterinarian.',
      );
    }

    return const _VisitStrings(
      back: 'Indietro',
      visitsTitle: 'Visite',
      heroSubtitle:
          'Tieni visite, esiti e follow-up veterinari sempre ordinati.',
      entriesLabel: 'voci',
      nextVisitsShort: 'prossime',
      historyTitle: 'Storico visite',
      formSubtitle:
          'Salva solo dettagli della visita e informazioni fornite dal veterinario.',
      latestVisit: 'Ultima visita',
      latestVisitSummary: 'Appuntamento più recente salvato',
      noVisitSummary: 'Nessuna visita registrata',
      addEntry: 'Aggiungi visita',
      visitTypeLabel: 'Tipo visita',
      visitRoutine: 'Routine',
      visitVaccine: 'Vaccino',
      visitCheckup: 'Controllo',
      visitFollowUp: 'Follow-up',
      visitUrgent: 'Registro visita urgente',
      visitOther: 'Altro',
      reasonLabel: 'Motivo',
      reasonHint: 'Es. appuntamento veterinario',
      reasonRequired: 'Inserisci il motivo della visita',
      visitDate: 'Data visita',
      clinicNameLabel: 'Veterinario / clinica',
      clinicNameHint: 'Opzionale',
      clinicNameShort: 'Vet / clinica',
      outcomeLabel: 'Esito o riepilogo del veterinario',
      outcomeHint:
          'Opzionale. Inserisci solo informazioni fornite dal veterinario.',
      outcomeShort: 'Esito',
      nextVisitDate: 'Prossima visita',
      notSet: 'Non impostata',
      clearNextVisitDate: 'Rimuovi prossima visita',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva visita',
      entrySaved: 'Visita salvata',
      emptyTitle: 'Nessuna visita',
      emptyDescription:
          'Aggiungi visite veterinarie per tenere appuntamenti e note in ordine.',
      deleteEntryTitle: 'Eliminare questa visita?',
      deleteEntryMessage:
          'La visita verrà rimossa dallo storico locale.',
      entryDeleted: 'Visita eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking delle visite serve solo per organizzazione. Pet Life non genera diagnosi, non interpreta referti, non fa triage e non sostituisce il veterinario.',
    );
  }
}