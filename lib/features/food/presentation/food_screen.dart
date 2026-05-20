import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/food_controller.dart';
import '../domain/food_entry.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  MealType _selectedMealType = MealType.other;
  DateTime _recordedAt = DateTime.now();

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
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

  Future<void> _saveEntry(Pet pet, _FoodStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();
    final quantity = _quantityController.text.trim();
    final notes = _notesController.text.trim();

    final entry = FoodEntry(
      id: 'food-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      mealType: _selectedMealType,
      foodName: _foodNameController.text.trim(),
      recordedAt: _recordedAt,
      createdAt: now,
      quantity: quantity.isEmpty ? null : quantity,
      notes: notes.isEmpty ? null : notes,
    );

    await ref.read(foodControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _foodNameController.clear();
    _quantityController.clear();
    _notesController.clear();

    setState(() {
      _selectedMealType = MealType.other;
      _recordedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
  }

  Future<void> _confirmDelete(
    FoodEntry entry,
    _FoodStrings strings,
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

    await ref.read(foodControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _FoodStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final foodState = ref.watch(foodControllerProvider);

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

            return foodState.when(
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
                      title: strings.foodTitle,
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
                    _MealSummaryCard(
                      strings: strings,
                      entries: petEntries,
                    ),
                    const SizedBox(height: 12),
                    _AddFoodEntryCard(
                      formKey: _formKey,
                      foodNameController: _foodNameController,
                      quantityController: _quantityController,
                      notesController: _notesController,
                      selectedMealType: _selectedMealType,
                      recordedAt: _recordedAt,
                      strings: strings,
                      onMealTypeChanged: (mealType) {
                        if (mealType == null) {
                          return;
                        }

                        setState(() {
                          _selectedMealType = mealType;
                        });
                      },
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
                      _EmptyFoodCard(strings: strings)
                    else
                      ...petEntries.map(
                        (entry) => _FoodEntryCard(
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
    final strings = _FoodStrings.of(context);

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

  final _FoodStrings strings;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latestEntry = entries.isEmpty ? null : entries.first;
    final latestLabel = latestEntry == null
        ? strings.noFoodSummary
        : '${strings.latestFood}: ${latestEntry.foodName}';

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
                Icons.restaurant_outlined,
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
                    strings.foodTitle,
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
                        icon: Icons.restaurant_menu_outlined,
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
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

  final _FoodStrings strings;

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

class _MealSummaryCard extends StatelessWidget {
  const _MealSummaryCard({
    required this.strings,
    required this.entries,
  });

  final _FoodStrings strings;
  final List<FoodEntry> entries;

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
                color: const Color(0xFFCC8E4A).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.restaurant_menu_outlined,
                color: Color(0xFFCC8E4A),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: latestEntry == null
                  ? Text(
                      strings.noFoodSummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.latestFood,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: PetLifeDesign.secondaryBrown,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${strings.mealTypeLabelFor(latestEntry.mealType)} · ${latestEntry.foodName}',
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
                          strings.latestFoodSummary,
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

class _AddFoodEntryCard extends StatelessWidget {
  const _AddFoodEntryCard({
    required this.formKey,
    required this.foodNameController,
    required this.quantityController,
    required this.notesController,
    required this.selectedMealType,
    required this.recordedAt,
    required this.strings,
    required this.onMealTypeChanged,
    required this.onSelectDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController foodNameController;
  final TextEditingController quantityController;
  final TextEditingController notesController;
  final MealType selectedMealType;
  final DateTime recordedAt;
  final _FoodStrings strings;
  final ValueChanged<MealType?> onMealTypeChanged;
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
                title: strings.addEntry,
                subtitle: strings.formSubtitle,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealType>(
                key: ValueKey('meal-type-$selectedMealType'),
                initialValue: selectedMealType,
                decoration: InputDecoration(
                  labelText: strings.mealTypeLabel,
                ),
                items: MealType.values
                    .map(
                      (mealType) => DropdownMenuItem(
                        value: mealType,
                        child: Text(strings.mealTypeLabelFor(mealType)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onMealTypeChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: foodNameController,
                decoration: InputDecoration(
                  labelText: strings.foodNameLabel,
                  hintText: strings.foodNameHint,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.foodNameRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: strings.quantityLabel,
                  hintText: strings.quantityHint,
                ),
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
            color: const Color(0xFFCC8E4A).withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFCC8E4A),
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

class _EmptyFoodCard extends StatelessWidget {
  const _EmptyFoodCard({
    required this.strings,
  });

  final _FoodStrings strings;

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
                color: const Color(0xFFCC8E4A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                size: 34,
                color: Color(0xFFCC8E4A),
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

class _FoodEntryCard extends StatelessWidget {
  const _FoodEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final FoodEntry entry;
  final _FoodStrings strings;
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
                color: Color(0xFFCC8E4A),
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
                        color: const Color(0xFFCC8E4A).withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: Color(0xFFCC8E4A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.foodName,
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
                                color: const Color(0xFFCC8E4A),
                                icon: Icons.restaurant_menu_outlined,
                                label: strings.mealTypeLabelFor(entry.mealType),
                              ),
                              _InfoPill(
                                color: PetLifeDesign.secondaryBrown,
                                icon: Icons.schedule_outlined,
                                label: dateLabel,
                              ),
                              _InfoPill(
                                color: const Color(0xFFCC8E4A),
                                icon: Icons.pets_outlined,
                                label: entry.petName,
                              ),
                            ],
                          ),
                          if (entry.quantity != null &&
                              entry.quantity!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              '${strings.quantityLabel}: ${entry.quantity!}',
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

class _FoodStrings {
  const _FoodStrings({
    required this.back,
    required this.foodTitle,
    required this.heroSubtitle,
    required this.entriesLabel,
    required this.historyTitle,
    required this.formSubtitle,
    required this.addEntry,
    required this.mealTypeLabel,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.other,
    required this.foodNameLabel,
    required this.foodNameHint,
    required this.foodNameRequired,
    required this.quantityLabel,
    required this.quantityHint,
    required this.recordedAt,
    required this.notesLabel,
    required this.notesHint,
    required this.saveEntry,
    required this.entrySaved,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.latestFood,
    required this.latestFoodSummary,
    required this.noFoodSummary,
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
  });

  final String back;
  final String foodTitle;
  final String heroSubtitle;
  final String entriesLabel;
  final String historyTitle;
  final String formSubtitle;
  final String addEntry;
  final String mealTypeLabel;
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snack;
  final String other;
  final String foodNameLabel;
  final String foodNameHint;
  final String foodNameRequired;
  final String quantityLabel;
  final String quantityHint;
  final String recordedAt;
  final String notesLabel;
  final String notesHint;
  final String saveEntry;
  final String entrySaved;
  final String emptyTitle;
  final String emptyDescription;
  final String latestFood;
  final String latestFoodSummary;
  final String noFoodSummary;
  final String deleteEntryTitle;
  final String deleteEntryMessage;
  final String entryDeleted;
  final String delete;
  final String cancel;
  final String petNotFound;
  final String disclaimer;

  String mealTypeLabelFor(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => breakfast,
      MealType.lunch => lunch,
      MealType.dinner => dinner,
      MealType.snack => snack,
      MealType.other => other,
    };
  }

  static _FoodStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _FoodStrings(
        back: 'Back',
        foodTitle: 'Food',
        heroSubtitle:
            'Keep meals, quantities and feeding notes organized over time.',
        entriesLabel: 'entries',
        historyTitle: 'Food history',
        formSubtitle: 'Add a meal, quantity and optional feeding notes.',
        addEntry: 'Add food entry',
        mealTypeLabel: 'Meal type',
        breakfast: 'Breakfast',
        lunch: 'Lunch',
        dinner: 'Dinner',
        snack: 'Snack',
        other: 'Other',
        foodNameLabel: 'Food or meal',
        foodNameHint: 'E.g. Dry food',
        foodNameRequired: 'Enter the food or meal',
        quantityLabel: 'Quantity',
        quantityHint: 'Optional, e.g. grams or 1 pouch',
        recordedAt: 'Date',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save food entry',
        entrySaved: 'Food entry saved',
        emptyTitle: 'No food entries',
        emptyDescription:
            'Add meals and notes to keep feeding information organized.',
        latestFood: 'Latest food entry',
        latestFoodSummary: 'Most recent saved meal',
        noFoodSummary: 'No food recorded yet',
        deleteEntryTitle: 'Delete this food entry?',
        deleteEntryMessage:
            'This removes the entry from the local history.',
        entryDeleted: 'Food entry deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Food tracking is only for organization. Pet Life does not create diets, calculate ideal portions or replace your veterinarian.',
      );
    }

    return const _FoodStrings(
      back: 'Indietro',
      foodTitle: 'Alimentazione',
      heroSubtitle:
          'Tieni pasti, quantità e note alimentari ordinati nel tempo.',
      entriesLabel: 'voci',
      historyTitle: 'Storico alimentazione',
      formSubtitle: 'Aggiungi pasto, quantità e note opzionali.',
      addEntry: 'Aggiungi alimento',
      mealTypeLabel: 'Tipo pasto',
      breakfast: 'Colazione',
      lunch: 'Pranzo',
      dinner: 'Cena',
      snack: 'Snack',
      other: 'Altro',
      foodNameLabel: 'Alimento o pasto',
      foodNameHint: 'Es. Crocchette',
      foodNameRequired: 'Inserisci alimento o pasto',
      quantityLabel: 'Quantità',
      quantityHint: 'Opzionale, es. grammi o 1 bustina',
      recordedAt: 'Data',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva alimento',
      entrySaved: 'Voce alimentazione salvata',
      emptyTitle: 'Nessuna voce alimentazione',
      emptyDescription:
          'Aggiungi pasti e note per tenere ordinate le informazioni alimentari.',
      latestFood: 'Ultimo alimento',
      latestFoodSummary: 'Pasto più recente salvato',
      noFoodSummary: 'Nessun alimento registrato',
      deleteEntryTitle: 'Eliminare questa voce?',
      deleteEntryMessage: 'La voce verrà rimossa dallo storico locale.',
      entryDeleted: 'Voce alimentazione eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking alimentare serve solo per organizzazione. Pet Life non crea diete, non calcola porzioni ideali e non sostituisce il veterinario.',
    );
  }
}