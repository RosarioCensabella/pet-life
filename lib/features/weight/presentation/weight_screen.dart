import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/weight_controller.dart';
import '../domain/weight_entry.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _recordedAt = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
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

  Future<void> _saveEntry(Pet pet, _WeightStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final normalizedWeight = _weightController.text.trim().replaceAll(',', '.');
    final weightKg = double.parse(normalizedWeight);
    final now = DateTime.now();
    final notes = _notesController.text.trim();

    final entry = WeightEntry(
      id: 'weight-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      weightKg: weightKg,
      recordedAt: _recordedAt,
      createdAt: now,
      notes: notes.isEmpty ? null : notes,
    );

    await ref.read(weightControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _weightController.clear();
    _notesController.clear();

    setState(() {
      _recordedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.weightSaved)),
    );
  }

  Future<void> _confirmDelete(
    WeightEntry entry,
    _WeightStrings strings,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteWeightTitle),
          content: Text(strings.deleteWeightMessage),
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

    await ref.read(weightControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.weightDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _WeightStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final weightState = ref.watch(weightControllerProvider);

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

            return weightState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final petEntries = entries
                    .where((entry) => entry.petId == pet.id)
                    .toList(growable: false)
                  ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _TopBar(
                      title: strings.weightTitle,
                      onBack: () => context.go('/pets/${pet.id}'),
                    ),
                    const SizedBox(height: 12),
                    _HeroCard(
                      strings: strings,
                      entries: petEntries,
                    ),
                    const SizedBox(height: 12),
                    _DisclaimerCard(strings: strings),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      entries: petEntries,
                      strings: strings,
                    ),
                    const SizedBox(height: 12),
                    _AddWeightCard(
                      formKey: _formKey,
                      weightController: _weightController,
                      notesController: _notesController,
                      recordedAt: _recordedAt,
                      strings: strings,
                      onSelectDate: _selectDate,
                      onSave: () => _saveEntry(pet, strings),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: strings.historyTitle,
                      count: petEntries.length,
                    ),
                    const SizedBox(height: 8),
                    if (petEntries.isEmpty)
                      _EmptyWeightCard(strings: strings)
                    else
                      ...petEntries.map(
                        (entry) => _WeightEntryCard(
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
    final strings = _WeightStrings.of(context);

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
    required this.entries,
  });

  final _WeightStrings strings;
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latestEntry = entries.isEmpty ? null : entries.first;
    final latestLabel = latestEntry == null
        ? strings.noWeightSummary
        : '${_formatWeight(latestEntry.weightKg)} kg';

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
                Icons.monitor_weight_outlined,
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
                    strings.weightTitle,
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
                        icon: Icons.favorite_border_outlined,
                        label: latestLabel,
                      ),
                      _DarkPill(
                        icon: Icons.list_alt_outlined,
                        label: '${entries.length} ${strings.entriesLabel}',
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

  final _WeightStrings strings;

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
                strings.weightDisclaimer,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.entries,
    required this.strings,
  });

  final List<WeightEntry> entries;
  final _WeightStrings strings;

  @override
  Widget build(BuildContext context) {
    final latestEntry = entries.isEmpty ? null : entries.first;
    final previousEntry = entries.length < 2 ? null : entries[1];

    final delta = latestEntry == null || previousEntry == null
        ? null
        : latestEntry.weightKg - previousEntry.weightKg;

    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF72A980).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                color: Color(0xFF72A980),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: latestEntry == null
                  ? Text(
                      strings.noWeightSummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.latestWeight,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: PetLifeDesign.secondaryBrown,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatWeight(latestEntry.weightKg)} kg',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                        ),
                        if (delta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${strings.changeFromPrevious}: ${delta >= 0 ? '+' : ''}${_formatWeight(delta)} kg',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWeightCard extends StatelessWidget {
  const _AddWeightCard({
    required this.formKey,
    required this.weightController,
    required this.notesController,
    required this.recordedAt,
    required this.strings,
    required this.onSelectDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController weightController;
  final TextEditingController notesController;
  final DateTime recordedAt;
  final _WeightStrings strings;
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
                icon: Icons.add_rounded,
                title: strings.addWeight,
                subtitle: strings.formSubtitle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: strings.weightKgLabel,
                  hintText: strings.weightKgHint,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                validator: (value) {
                  final normalized = value?.trim().replaceAll(',', '.') ?? '';

                  if (normalized.isEmpty) {
                    return strings.weightRequired;
                  }

                  final parsed = double.tryParse(normalized);

                  if (parsed == null || parsed <= 0) {
                    return strings.weightInvalid;
                  }

                  return null;
                },
              ),
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
                label: Text(strings.saveWeight),
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
            color: const Color(0xFF72A980).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF72A980),
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

class _EmptyWeightCard extends StatelessWidget {
  const _EmptyWeightCard({
    required this.strings,
  });

  final _WeightStrings strings;

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
                color: const Color(0xFF72A980).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                size: 34,
                color: Color(0xFF72A980),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.noWeightEntriesTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.noWeightEntriesDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightEntryCard extends StatelessWidget {
  const _WeightEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final WeightEntry entry;
  final _WeightStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(entry.recordedAt);

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
              decoration: const BoxDecoration(
                color: Color(0xFF72A980),
                borderRadius: BorderRadius.horizontal(
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
                        color: const Color(0xFF72A980).withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_outlined,
                        color: Color(0xFF72A980),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatWeight(entry.weightKg)} kg',
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
                                color: PetLifeDesign.secondaryBrown,
                                icon: Icons.schedule_outlined,
                                label: dateLabel,
                              ),
                              _InfoPill(
                                color: const Color(0xFF72A980),
                                icon: Icons.pets_outlined,
                                label: entry.petName,
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

String _formatWeight(double value) {
  final fixed = value.toStringAsFixed(2);

  if (fixed.endsWith('00')) {
    return value.toStringAsFixed(0);
  }

  if (fixed.endsWith('0')) {
    return value.toStringAsFixed(1);
  }

  return fixed;
}

class _WeightStrings {
  const _WeightStrings({
    required this.back,
    required this.weightTitle,
    required this.heroSubtitle,
    required this.entriesLabel,
    required this.historyTitle,
    required this.formSubtitle,
    required this.addWeight,
    required this.weightKgLabel,
    required this.weightKgHint,
    required this.weightRequired,
    required this.weightInvalid,
    required this.recordedAt,
    required this.notesLabel,
    required this.notesHint,
    required this.saveWeight,
    required this.weightSaved,
    required this.noWeightEntriesTitle,
    required this.noWeightEntriesDescription,
    required this.latestWeight,
    required this.noWeightSummary,
    required this.changeFromPrevious,
    required this.deleteWeightTitle,
    required this.deleteWeightMessage,
    required this.weightDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.weightDisclaimer,
  });

  final String back;
  final String weightTitle;
  final String heroSubtitle;
  final String entriesLabel;
  final String historyTitle;
  final String formSubtitle;
  final String addWeight;
  final String weightKgLabel;
  final String weightKgHint;
  final String weightRequired;
  final String weightInvalid;
  final String recordedAt;
  final String notesLabel;
  final String notesHint;
  final String saveWeight;
  final String weightSaved;
  final String noWeightEntriesTitle;
  final String noWeightEntriesDescription;
  final String latestWeight;
  final String noWeightSummary;
  final String changeFromPrevious;
  final String deleteWeightTitle;
  final String deleteWeightMessage;
  final String weightDeleted;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String weightDisclaimer;

  static _WeightStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _WeightStrings(
        back: 'Back',
        weightTitle: 'Weight',
        heroSubtitle:
            'Track weight measurements over time and keep notes organized.',
        entriesLabel: 'entries',
        historyTitle: 'Weight history',
        formSubtitle: 'Add a simple weight measurement with optional notes.',
        addWeight: 'Add weight',
        weightKgLabel: 'Weight in kg',
        weightKgHint: 'E.g. 12.4',
        weightRequired: 'Enter the weight',
        weightInvalid: 'Enter a valid weight',
        recordedAt: 'Date',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveWeight: 'Save weight',
        weightSaved: 'Weight saved',
        noWeightEntriesTitle: 'No weight entries',
        noWeightEntriesDescription:
            'Add weight entries to track changes over time.',
        latestWeight: 'Latest weight',
        noWeightSummary: 'No weight recorded yet',
        changeFromPrevious: 'Change from previous',
        deleteWeightTitle: 'Delete this weight entry?',
        deleteWeightMessage:
            'This removes the entry from the local weight history.',
        weightDeleted: 'Weight entry deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        weightDisclaimer:
            'Weight tracking is for organization only. Pet Life does not interpret weight changes, diagnose conditions or replace your veterinarian.',
      );
    }

    return const _WeightStrings(
      back: 'Indietro',
      weightTitle: 'Peso',
      heroSubtitle:
          'Registra le misurazioni nel tempo e tieni le note sempre ordinate.',
      entriesLabel: 'voci',
      historyTitle: 'Storico peso',
      formSubtitle: 'Aggiungi una misurazione semplice con note opzionali.',
      addWeight: 'Aggiungi peso',
      weightKgLabel: 'Peso in kg',
      weightKgHint: 'Es. 12,4',
      weightRequired: 'Inserisci il peso',
      weightInvalid: 'Inserisci un peso valido',
      recordedAt: 'Data',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveWeight: 'Salva peso',
      weightSaved: 'Peso salvato',
      noWeightEntriesTitle: 'Nessuna misurazione',
      noWeightEntriesDescription:
          'Aggiungi misurazioni del peso per seguire le variazioni nel tempo.',
      latestWeight: 'Ultimo peso',
      noWeightSummary: 'Nessun peso registrato',
      changeFromPrevious: 'Variazione precedente',
      deleteWeightTitle: 'Eliminare questa misurazione?',
      deleteWeightMessage:
          'La misurazione verrà rimossa dallo storico locale del peso.',
      weightDeleted: 'Misurazione eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      weightDisclaimer:
          'Il tracciamento del peso serve solo per organizzazione. Pet Life non interpreta variazioni di peso, non diagnostica condizioni e non sostituisce il veterinario.',
    );
  }
}