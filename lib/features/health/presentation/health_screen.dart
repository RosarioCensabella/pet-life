import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/health_controller.dart';
import '../domain/health_entry.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({
    required this.petId,
    required this.initialType,
    super.key,
  });

  final String petId;
  final HealthEntryType initialType;

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late HealthEntryType _selectedType;
  SymptomIntensity _selectedIntensity = SymptomIntensity.moderate;
  DateTime _recordedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  Future<void> _saveEntry(Pet pet, _HealthStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();
    final notes = _notesController.text.trim();

    final entry = HealthEntry(
      id: 'health-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      type: _selectedType,
      title: _titleController.text.trim(),
      recordedAt: _recordedAt,
      createdAt: now,
      notes: notes.isEmpty ? null : notes,
      symptomIntensity:
          _selectedType == HealthEntryType.symptom ? _selectedIntensity : null,
    );

    await ref.read(healthControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _titleController.clear();
    _notesController.clear();

    setState(() {
      _recordedAt = DateTime.now();
      _selectedIntensity = SymptomIntensity.moderate;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
  }

  Future<void> _confirmDelete(
    HealthEntry entry,
    _HealthStrings strings,
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

    await ref.read(healthControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _HealthStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final healthState = ref.watch(healthControllerProvider);

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

            return healthState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

                final visibleEntries = petEntries
                    .where((entry) => entry.type == _selectedType)
                    .toList(growable: false);

                final symptomCount = petEntries
                    .where((entry) => entry.type == HealthEntryType.symptom)
                    .length;
                final diaryCount = petEntries
                    .where((entry) => entry.type == HealthEntryType.diary)
                    .length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _TopBar(
                      title: strings.screenTitle(_selectedType),
                      onBack: () => context.go('/pets/${pet.id}'),
                    ),
                    const SizedBox(height: 12),
                    _HeroCard(
                      strings: strings,
                      selectedType: _selectedType,
                      diaryCount: diaryCount,
                      symptomCount: symptomCount,
                    ),
                    const SizedBox(height: 12),
                    _DisclaimerCard(strings: strings),
                    const SizedBox(height: 12),
                    _AddHealthEntryCard(
                      formKey: _formKey,
                      titleController: _titleController,
                      notesController: _notesController,
                      selectedType: _selectedType,
                      selectedIntensity: _selectedIntensity,
                      recordedAt: _recordedAt,
                      strings: strings,
                      onTypeChanged: (type) {
                        if (type == null) {
                          return;
                        }

                        setState(() {
                          _selectedType = type;
                        });
                      },
                      onIntensityChanged: (intensity) {
                        if (intensity == null) {
                          return;
                        }

                        setState(() {
                          _selectedIntensity = intensity;
                        });
                      },
                      onSelectDate: _selectDate,
                      onSave: () => _saveEntry(pet, strings),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: strings.historyTitle(_selectedType),
                      count: visibleEntries.length,
                    ),
                    const SizedBox(height: 8),
                    if (visibleEntries.isEmpty)
                      _EmptyHealthCard(strings: strings)
                    else
                      ...visibleEntries.map(
                        (entry) => _HealthEntryCard(
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
    final strings = _HealthStrings.of(context);

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
    required this.selectedType,
    required this.diaryCount,
    required this.symptomCount,
  });

  final _HealthStrings strings;
  final HealthEntryType selectedType;
  final int diaryCount;
  final int symptomCount;

  @override
  Widget build(BuildContext context) {
    final title = strings.screenTitle(selectedType);
    final subtitle = selectedType == HealthEntryType.symptom
        ? strings.symptomHeroSubtitle
        : strings.diaryHeroSubtitle;
    final icon = selectedType == HealthEntryType.symptom
        ? Icons.visibility_outlined
        : Icons.edit_note_outlined;

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
              child: Icon(
                icon,
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
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
                        icon: Icons.edit_note_outlined,
                        label: '$diaryCount ${strings.diaryEntriesShort}',
                      ),
                      _DarkPill(
                        icon: Icons.visibility_outlined,
                        label: '$symptomCount ${strings.symptomEntriesShort}',
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

  final _HealthStrings strings;

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

class _AddHealthEntryCard extends StatelessWidget {
  const _AddHealthEntryCard({
    required this.formKey,
    required this.titleController,
    required this.notesController,
    required this.selectedType,
    required this.selectedIntensity,
    required this.recordedAt,
    required this.strings,
    required this.onTypeChanged,
    required this.onIntensityChanged,
    required this.onSelectDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final HealthEntryType selectedType;
  final SymptomIntensity selectedIntensity;
  final DateTime recordedAt;
  final _HealthStrings strings;
  final ValueChanged<HealthEntryType?> onTypeChanged;
  final ValueChanged<SymptomIntensity?> onIntensityChanged;
  final VoidCallback onSelectDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(recordedAt);

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardTitle(
                icon: selectedType == HealthEntryType.symptom
                    ? Icons.visibility_outlined
                    : Icons.edit_note_outlined,
                title: strings.addEntry,
                subtitle: strings.formSubtitle,
                color: _colorForType(selectedType),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HealthEntryType>(
                key: ValueKey('health-type-$selectedType'),
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: strings.typeLabel,
                ),
                items: HealthEntryType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(strings.typeLabelFor(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onTypeChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: selectedType == HealthEntryType.symptom
                      ? strings.symptomTitleLabel
                      : strings.diaryTitleLabel,
                  hintText: selectedType == HealthEntryType.symptom
                      ? strings.symptomTitleHint
                      : strings.diaryTitleHint,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.titleRequired;
                  }

                  return null;
                },
              ),
              if (selectedType == HealthEntryType.symptom) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<SymptomIntensity>(
                  key: ValueKey('symptom-intensity-$selectedIntensity'),
                  initialValue: selectedIntensity,
                  decoration: InputDecoration(
                    labelText: strings.intensityLabel,
                  ),
                  items: SymptomIntensity.values
                      .map(
                        (intensity) => DropdownMenuItem(
                          value: intensity,
                          child: Text(strings.intensityLabelFor(intensity)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onIntensityChanged,
                ),
              ],
              const SizedBox(height: 12),
              _DateActionTile(
                icon: Icons.event_outlined,
                title: strings.recordedAt,
                value: dateLabel,
                onTap: onSelectDate,
              ),
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

  Color _colorForType(HealthEntryType type) {
    return switch (type) {
      HealthEntryType.diary => const Color(0xFF72A980),
      HealthEntryType.symptom => const Color(0xFFC85B4A),
    };
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
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
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

class _EmptyHealthCard extends StatelessWidget {
  const _EmptyHealthCard({
    required this.strings,
  });

  final _HealthStrings strings;

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
                color: PetLifeDesign.infoLilac,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.edit_note_outlined,
                size: 34,
                color: Color(0xFF9C6ADE),
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

class _HealthEntryCard extends StatelessWidget {
  const _HealthEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final HealthEntry entry;
  final _HealthStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(entry.recordedAt);
    final accentColor = entry.type == HealthEntryType.symptom
        ? const Color(0xFFC85B4A)
        : const Color(0xFF72A980);

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
                        entry.type == HealthEntryType.symptom
                            ? Icons.visibility_outlined
                            : Icons.edit_note_outlined,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
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
                                icon: entry.type == HealthEntryType.symptom
                                    ? Icons.visibility_outlined
                                    : Icons.edit_note_outlined,
                                label: strings.typeLabelFor(entry.type),
                              ),
                              _InfoPill(
                                color: PetLifeDesign.secondaryBrown,
                                icon: Icons.schedule_outlined,
                                label: dateLabel,
                              ),
                              _InfoPill(
                                color: accentColor,
                                icon: Icons.pets_outlined,
                                label: entry.petName,
                              ),
                              if (entry.symptomIntensity != null)
                                _InfoPill(
                                  color: _colorForIntensity(
                                    entry.symptomIntensity!,
                                  ),
                                  icon: Icons.speed_outlined,
                                  label:
                                      '${strings.intensityLabel}: ${strings.intensityLabelFor(entry.symptomIntensity!)}',
                                ),
                            ],
                          ),
                          if (entry.notes != null &&
                              entry.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
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

  Color _colorForIntensity(SymptomIntensity intensity) {
    return switch (intensity) {
      SymptomIntensity.mild => const Color(0xFF72A980),
      SymptomIntensity.moderate => const Color(0xFFE49D4F),
      SymptomIntensity.high => const Color(0xFFC85B4A),
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

class _HealthStrings {
  const _HealthStrings({
    required this.back,
    required this.healthDiaryTitle,
    required this.symptomsTitle,
    required this.diaryHeroSubtitle,
    required this.symptomHeroSubtitle,
    required this.diaryEntriesShort,
    required this.symptomEntriesShort,
    required this.addEntry,
    required this.formSubtitle,
    required this.typeLabel,
    required this.diaryType,
    required this.symptomType,
    required this.diaryTitleLabel,
    required this.diaryTitleHint,
    required this.symptomTitleLabel,
    required this.symptomTitleHint,
    required this.titleRequired,
    required this.intensityLabel,
    required this.intensityMild,
    required this.intensityModerate,
    required this.intensityHigh,
    required this.recordedAt,
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
    required this.diaryHistoryTitle,
    required this.symptomHistoryTitle,
  });

  final String back;
  final String healthDiaryTitle;
  final String symptomsTitle;
  final String diaryHeroSubtitle;
  final String symptomHeroSubtitle;
  final String diaryEntriesShort;
  final String symptomEntriesShort;
  final String addEntry;
  final String formSubtitle;
  final String typeLabel;
  final String diaryType;
  final String symptomType;
  final String diaryTitleLabel;
  final String diaryTitleHint;
  final String symptomTitleLabel;
  final String symptomTitleHint;
  final String titleRequired;
  final String intensityLabel;
  final String intensityMild;
  final String intensityModerate;
  final String intensityHigh;
  final String recordedAt;
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
  final String diaryHistoryTitle;
  final String symptomHistoryTitle;

  String screenTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom ? symptomsTitle : healthDiaryTitle;
  }

  String historyTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom
        ? symptomHistoryTitle
        : diaryHistoryTitle;
  }

  String typeLabelFor(HealthEntryType type) {
    return switch (type) {
      HealthEntryType.diary => diaryType,
      HealthEntryType.symptom => symptomType,
    };
  }

  String intensityLabelFor(SymptomIntensity intensity) {
    return switch (intensity) {
      SymptomIntensity.mild => intensityMild,
      SymptomIntensity.moderate => intensityModerate,
      SymptomIntensity.high => intensityHigh,
    };
  }

  static _HealthStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _HealthStrings(
        back: 'Back',
        healthDiaryTitle: 'Health diary',
        symptomsTitle: 'Symptoms',
        diaryHeroSubtitle:
            'Keep simple health notes organized before future vet visits.',
        symptomHeroSubtitle:
            'Record observations clearly, without interpreting or triaging them.',
        diaryEntriesShort: 'diary',
        symptomEntriesShort: 'symptoms',
        addEntry: 'Add entry',
        formSubtitle:
            'Save observations and notes exactly as you notice them.',
        typeLabel: 'Type',
        diaryType: 'Diary note',
        symptomType: 'Symptom observation',
        diaryTitleLabel: 'Title',
        diaryTitleHint: 'E.g. General check note',
        symptomTitleLabel: 'Symptom observed',
        symptomTitleHint: 'E.g. Cough',
        titleRequired: 'Enter a title',
        intensityLabel: 'Intensity',
        intensityMild: 'Mild',
        intensityModerate: 'Moderate',
        intensityHigh: 'High',
        recordedAt: 'Date',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save entry',
        entrySaved: 'Entry saved',
        emptyTitle: 'No entries yet',
        emptyDescription:
            'Add diary notes or symptom observations to keep information organized for future vet visits.',
        deleteEntryTitle: 'Delete this entry?',
        deleteEntryMessage:
            'This removes the entry from the local history.',
        entryDeleted: 'Entry deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'This section is only for tracking and organization. Pet Life does not diagnose, triage, prescribe, calculate dosages or replace your veterinarian.',
        diaryHistoryTitle: 'Diary history',
        symptomHistoryTitle: 'Symptom history',
      );
    }

    return const _HealthStrings(
      back: 'Indietro',
      healthDiaryTitle: 'Diario salute',
      symptomsTitle: 'Sintomi',
      diaryHeroSubtitle:
          'Tieni le note di salute ordinate in vista delle prossime visite.',
      symptomHeroSubtitle:
          'Registra le osservazioni in modo chiaro, senza interpretarle.',
      diaryEntriesShort: 'note',
      symptomEntriesShort: 'sintomi',
      addEntry: 'Aggiungi voce',
      formSubtitle:
          'Salva osservazioni e note così come le hai rilevate.',
      typeLabel: 'Tipo',
      diaryType: 'Nota diario',
      symptomType: 'Osservazione sintomo',
      diaryTitleLabel: 'Titolo',
      diaryTitleHint: 'Es. Nota controllo generale',
      symptomTitleLabel: 'Sintomo osservato',
      symptomTitleHint: 'Es. Tosse',
      titleRequired: 'Inserisci un titolo',
      intensityLabel: 'Intensità',
      intensityMild: 'Lieve',
      intensityModerate: 'Moderata',
      intensityHigh: 'Alta',
      recordedAt: 'Data',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva voce',
      entrySaved: 'Voce salvata',
      emptyTitle: 'Nessuna voce',
      emptyDescription:
          'Aggiungi note o osservazioni per mantenere le informazioni ordinate in vista delle visite veterinarie.',
      deleteEntryTitle: 'Eliminare questa voce?',
      deleteEntryMessage:
          'La voce verrà rimossa dallo storico locale.',
      entryDeleted: 'Voce eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Questa sezione serve solo per tracking e organizzazione. Pet Life non fa diagnosi, triage, prescrizioni, calcolo dosaggi e non sostituisce il veterinario.',
      diaryHistoryTitle: 'Storico diario',
      symptomHistoryTitle: 'Storico sintomi',
    );
  }
}