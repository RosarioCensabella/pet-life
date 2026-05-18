import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.screenTitle(_selectedType))),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.screenTitle(_selectedType))),
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
            appBar: AppBar(title: Text(strings.screenTitle(_selectedType))),
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
            title: Text(strings.screenTitle(_selectedType)),
          ),
          body: healthState.when(
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
                  if (petEntries.isEmpty)
                    _EmptyHealthCard(strings: strings)
                  else
                    ...petEntries.map(
                      (entry) => _HealthEntryCard(
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

  final _HealthStrings strings;

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
              DropdownButtonFormField<HealthEntryType>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: strings.typeLabel,
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
                  initialValue: selectedIntensity,
                  decoration: InputDecoration(
                    labelText: strings.intensityLabel,
                    border: const OutlineInputBorder(),
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

class _EmptyHealthCard extends StatelessWidget {
  const _EmptyHealthCard({
    required this.strings,
  });

  final _HealthStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.edit_note_outlined,
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

    return Card(
      child: ListTile(
        leading: Icon(
          entry.type == HealthEntryType.symptom
              ? Icons.visibility_outlined
              : Icons.edit_note_outlined,
        ),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.typeLabelFor(entry.type)} · $dateLabel'),
            if (entry.symptomIntensity != null)
              Text(
                '${strings.intensityLabel}: ${strings.intensityLabelFor(entry.symptomIntensity!)}',
              ),
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

class _HealthStrings {
  const _HealthStrings({
    required this.healthDiaryTitle,
    required this.symptomsTitle,
    required this.addEntry,
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
  });

  final String healthDiaryTitle;
  final String symptomsTitle;
  final String addEntry;
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

  String screenTitle(HealthEntryType type) {
    return type == HealthEntryType.symptom ? symptomsTitle : healthDiaryTitle;
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
        healthDiaryTitle: 'Health diary',
        symptomsTitle: 'Symptoms',
        addEntry: 'Add entry',
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
        deleteEntryMessage: 'This removes the entry from the local history.',
        entryDeleted: 'Entry deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'This section is only for tracking and organization. Pet Life does not diagnose, triage, prescribe, calculate dosages or replace your veterinarian.',
      );
    }

    return const _HealthStrings(
      healthDiaryTitle: 'Diario salute',
      symptomsTitle: 'Sintomi',
      addEntry: 'Aggiungi voce',
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
      deleteEntryMessage: 'La voce verrà rimossa dallo storico locale.',
      entryDeleted: 'Voce eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Questa sezione serve solo per tracking e organizzazione. Pet Life non fa diagnosi, triage, prescrizioni, calcolo dosaggi e non sostituisce il veterinario.',
    );
  }
}