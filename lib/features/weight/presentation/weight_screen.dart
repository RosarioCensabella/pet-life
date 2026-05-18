import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.weightTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.weightTitle)),
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
            appBar: AppBar(title: Text(strings.weightTitle)),
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
            title: Text(strings.weightTitle),
          ),
          body: weightState.when(
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
                  _SummaryCard(
                    entries: petEntries,
                    strings: strings,
                  ),
                  _AddWeightCard(
                    formKey: _formKey,
                    weightController: _weightController,
                    notesController: _notesController,
                    recordedAt: _recordedAt,
                    strings: strings,
                    onSelectDate: _selectDate,
                    onSave: () => _saveEntry(pet, strings),
                  ),
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

  final _WeightStrings strings;

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
              child: Text(strings.weightDisclaimer),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: latestEntry == null
                  ? Text(
                      strings.noWeightSummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.latestWeight,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatWeight(latestEntry.weightKg)} kg',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (delta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${strings.changeFromPrevious}: ${delta >= 0 ? '+' : ''}${_formatWeight(delta)} kg',
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addWeight,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: strings.weightKgLabel,
                  hintText: strings.weightKgHint,
                  border: const OutlineInputBorder(),
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
                label: Text(strings.saveWeight),
              ),
            ],
          ),
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              strings.noWeightEntriesTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.noWeightEntriesDescription,
              textAlign: TextAlign.center,
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

    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text('${_formatWeight(entry.weightKg)} kg'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel),
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
    required this.weightTitle,
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

  final String weightTitle;
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
        weightTitle: 'Weight',
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
      weightTitle: 'Peso',
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