import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.foodTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.foodTitle)),
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
            appBar: AppBar(title: Text(strings.foodTitle)),
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
            title: Text(strings.foodTitle),
          ),
          body: foodState.when(
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

  final _FoodStrings strings;

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addEntry,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealType>(
                initialValue: selectedMealType,
                decoration: InputDecoration(
                  labelText: strings.mealTypeLabel,
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('${strings.recordedAt}: $dateLabel'),
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

class _EmptyFoodCard extends StatelessWidget {
  const _EmptyFoodCard({
    required this.strings,
  });

  final _FoodStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_outlined,
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

    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_outlined),
        title: Text(entry.foodName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.mealTypeLabelFor(entry.mealType)} · $dateLabel'),
            if (entry.quantity != null && entry.quantity!.trim().isNotEmpty)
              Text('${strings.quantityLabel}: ${entry.quantity!}'),
            if (entry.notes != null && entry.notes!.trim().isNotEmpty)
              Text(entry.notes!),
          ],
        ),
        trailing: IconButton(
          tooltip: strings.delete,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _FoodStrings {
  const _FoodStrings({
    required this.foodTitle,
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
    required this.deleteEntryTitle,
    required this.deleteEntryMessage,
    required this.entryDeleted,
    required this.delete,
    required this.cancel,
    required this.petNotFound,
    required this.disclaimer,
  });

  final String foodTitle;
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
        foodTitle: 'Food',
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
        quantityHint: 'Optional, e.g. 80 g or 1 pouch',
        recordedAt: 'Date',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save food entry',
        entrySaved: 'Food entry saved',
        emptyTitle: 'No food entries',
        emptyDescription:
            'Add meals and notes to keep feeding information organized.',
        deleteEntryTitle: 'Delete this food entry?',
        deleteEntryMessage: 'This removes the entry from the local history.',
        entryDeleted: 'Food entry deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Food tracking is only for organization. Pet Life does not create diets, calculate ideal portions or replace your veterinarian.',
      );
    }

    return const _FoodStrings(
      foodTitle: 'Alimentazione',
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
      quantityHint: 'Opzionale, es. 80 g o 1 bustina',
      recordedAt: 'Data',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva alimento',
      entrySaved: 'Voce alimentazione salvata',
      emptyTitle: 'Nessuna voce alimentazione',
      emptyDescription:
          'Aggiungi pasti e note per tenere ordinate le informazioni alimentari.',
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