import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/medication_controller.dart';
import '../domain/medication_entry.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();

  MedicationStatus _selectedStatus = MedicationStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _prescribedByController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _startDate.hour,
        _startDate.minute,
      );

      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  Future<void> _saveEntry(Pet pet, _MedicationStrings strings) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();
    final prescribedBy = _prescribedByController.text.trim();
    final instructions = _instructionsController.text.trim();
    final notes = _notesController.text.trim();

    final entry = MedicationEntry(
      id: 'medication-${now.microsecondsSinceEpoch}',
      petId: pet.id,
      petName: pet.name,
      name: _nameController.text.trim(),
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
      createdAt: now,
      prescribedBy: prescribedBy.isEmpty ? null : prescribedBy,
      instructions: instructions.isEmpty ? null : instructions,
      notes: notes.isEmpty ? null : notes,
    );

    await ref.read(medicationControllerProvider.notifier).addEntry(entry);

    if (!mounted) {
      return;
    }

    _nameController.clear();
    _prescribedByController.clear();
    _instructionsController.clear();
    _notesController.clear();

    setState(() {
      _selectedStatus = MedicationStatus.active;
      _startDate = DateTime.now();
      _endDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entrySaved)),
    );
  }

  Future<void> _confirmDelete(
    MedicationEntry entry,
    _MedicationStrings strings,
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

    await ref.read(medicationControllerProvider.notifier).deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.entryDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = _MedicationStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final medicationState = ref.watch(medicationControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.medicationsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.medicationsTitle)),
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
            appBar: AppBar(title: Text(strings.medicationsTitle)),
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
            title: Text(strings.medicationsTitle),
          ),
          body: medicationState.when(
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
                  _AddMedicationEntryCard(
                    formKey: _formKey,
                    nameController: _nameController,
                    prescribedByController: _prescribedByController,
                    instructionsController: _instructionsController,
                    notesController: _notesController,
                    selectedStatus: _selectedStatus,
                    startDate: _startDate,
                    endDate: _endDate,
                    strings: strings,
                    onStatusChanged: (status) {
                      if (status == null) {
                        return;
                      }

                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    onSelectStartDate: _selectStartDate,
                    onSelectEndDate: _selectEndDate,
                    onClearEndDate: () {
                      setState(() {
                        _endDate = null;
                      });
                    },
                    onSave: () => _saveEntry(pet, strings),
                  ),
                  if (petEntries.isEmpty)
                    _EmptyMedicationCard(strings: strings)
                  else
                    ...petEntries.map(
                      (entry) => _MedicationEntryCard(
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

  final _MedicationStrings strings;

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

class _AddMedicationEntryCard extends StatelessWidget {
  const _AddMedicationEntryCard({
    required this.formKey,
    required this.nameController,
    required this.prescribedByController,
    required this.instructionsController,
    required this.notesController,
    required this.selectedStatus,
    required this.startDate,
    required this.endDate,
    required this.strings,
    required this.onStatusChanged,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.onClearEndDate,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController prescribedByController;
  final TextEditingController instructionsController;
  final TextEditingController notesController;
  final MedicationStatus selectedStatus;
  final DateTime startDate;
  final DateTime? endDate;
  final _MedicationStrings strings;
  final ValueChanged<MedicationStatus?> onStatusChanged;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final VoidCallback onClearEndDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startDateLabel = DateFormat.yMMMd(locale).format(startDate);
    final endDateLabel = endDate == null
        ? strings.noEndDate
        : DateFormat.yMMMd(locale).format(endDate!);

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
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.medicationNameLabel,
                  hintText: strings.medicationNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return strings.medicationNameRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MedicationStatus>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: strings.statusLabel,
                  border: const OutlineInputBorder(),
                ),
                items: MedicationStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(strings.statusLabelFor(status)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onStatusChanged,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectStartDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('${strings.startDate}: $startDateLabel'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectEndDate,
                icon: const Icon(Icons.event_available_outlined),
                label: Text('${strings.endDate}: $endDateLabel'),
              ),
              if (endDate != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onClearEndDate,
                  icon: const Icon(Icons.close_outlined),
                  label: Text(strings.clearEndDate),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: prescribedByController,
                decoration: InputDecoration(
                  labelText: strings.prescribedByLabel,
                  hintText: strings.prescribedByHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: instructionsController,
                decoration: InputDecoration(
                  labelText: strings.instructionsLabel,
                  hintText: strings.instructionsHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
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

class _EmptyMedicationCard extends StatelessWidget {
  const _EmptyMedicationCard({
    required this.strings,
  });

  final _MedicationStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.medication_outlined,
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

class _MedicationEntryCard extends StatelessWidget {
  const _MedicationEntryCard({
    required this.entry,
    required this.strings,
    required this.onDelete,
  });

  final MedicationEntry entry;
  final _MedicationStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startLabel = DateFormat.yMMMd(locale).format(entry.startDate);
    final endLabel =
        entry.endDate == null ? null : DateFormat.yMMMd(locale).format(entry.endDate!);

    final dateText = endLabel == null
        ? '${strings.startDate}: $startLabel'
        : '${strings.startDate}: $startLabel · ${strings.endDate}: $endLabel';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text(entry.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.statusLabel}: ${strings.statusLabelFor(entry.status)}'),
            Text(dateText),
            if (entry.prescribedBy != null &&
                entry.prescribedBy!.trim().isNotEmpty)
              Text('${strings.prescribedByShort}: ${entry.prescribedBy!}'),
            if (entry.instructions != null &&
                entry.instructions!.trim().isNotEmpty)
              Text('${strings.instructionsShort}: ${entry.instructions!}'),
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

class _MedicationStrings {
  const _MedicationStrings({
    required this.medicationsTitle,
    required this.addEntry,
    required this.medicationNameLabel,
    required this.medicationNameHint,
    required this.medicationNameRequired,
    required this.statusLabel,
    required this.statusActive,
    required this.statusCompleted,
    required this.statusPaused,
    required this.startDate,
    required this.endDate,
    required this.noEndDate,
    required this.clearEndDate,
    required this.prescribedByLabel,
    required this.prescribedByHint,
    required this.prescribedByShort,
    required this.instructionsLabel,
    required this.instructionsHint,
    required this.instructionsShort,
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

  final String medicationsTitle;
  final String addEntry;
  final String medicationNameLabel;
  final String medicationNameHint;
  final String medicationNameRequired;
  final String statusLabel;
  final String statusActive;
  final String statusCompleted;
  final String statusPaused;
  final String startDate;
  final String endDate;
  final String noEndDate;
  final String clearEndDate;
  final String prescribedByLabel;
  final String prescribedByHint;
  final String prescribedByShort;
  final String instructionsLabel;
  final String instructionsHint;
  final String instructionsShort;
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

  String statusLabelFor(MedicationStatus status) {
    return switch (status) {
      MedicationStatus.active => statusActive,
      MedicationStatus.completed => statusCompleted,
      MedicationStatus.paused => statusPaused,
    };
  }

  static _MedicationStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _MedicationStrings(
        medicationsTitle: 'Medications',
        addEntry: 'Add medication',
        medicationNameLabel: 'Medication name',
        medicationNameHint: 'E.g. Antibiotic',
        medicationNameRequired: 'Enter the medication name',
        statusLabel: 'Status',
        statusActive: 'Active',
        statusCompleted: 'Completed',
        statusPaused: 'Paused',
        startDate: 'Start date',
        endDate: 'End date',
        noEndDate: 'Not set',
        clearEndDate: 'Clear end date',
        prescribedByLabel: 'Veterinarian / prescriber',
        prescribedByHint: 'Optional',
        prescribedByShort: 'Vet',
        instructionsLabel: 'Veterinarian instructions',
        instructionsHint:
            'Optional. Enter only instructions provided by your veterinarian.',
        instructionsShort: 'Instructions',
        notesLabel: 'Notes',
        notesHint: 'Optional',
        saveEntry: 'Save medication',
        entrySaved: 'Medication saved',
        emptyTitle: 'No medications',
        emptyDescription:
            'Add medications only as a personal record of information provided by your veterinarian.',
        deleteEntryTitle: 'Delete this medication?',
        deleteEntryMessage:
            'This removes the medication entry from the local history.',
        entryDeleted: 'Medication deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Medication tracking is only for organization. Pet Life does not prescribe medications, suggest treatments, calculate dosages or replace your veterinarian.',
      );
    }

    return const _MedicationStrings(
      medicationsTitle: 'Farmaci',
      addEntry: 'Aggiungi farmaco',
      medicationNameLabel: 'Nome farmaco',
      medicationNameHint: 'Es. Antibiotico',
      medicationNameRequired: 'Inserisci il nome del farmaco',
      statusLabel: 'Stato',
      statusActive: 'Attivo',
      statusCompleted: 'Completato',
      statusPaused: 'Sospeso',
      startDate: 'Data inizio',
      endDate: 'Data fine',
      noEndDate: 'Non impostata',
      clearEndDate: 'Rimuovi data fine',
      prescribedByLabel: 'Veterinario / prescrittore',
      prescribedByHint: 'Opzionale',
      prescribedByShort: 'Vet',
      instructionsLabel: 'Indicazioni del veterinario',
      instructionsHint:
          'Opzionale. Inserisci solo indicazioni fornite dal veterinario.',
      instructionsShort: 'Indicazioni',
      notesLabel: 'Note',
      notesHint: 'Opzionale',
      saveEntry: 'Salva farmaco',
      entrySaved: 'Farmaco salvato',
      emptyTitle: 'Nessun farmaco',
      emptyDescription:
          'Aggiungi farmaci solo come registro personale delle informazioni fornite dal veterinario.',
      deleteEntryTitle: 'Eliminare questo farmaco?',
      deleteEntryMessage:
          'Il farmaco verrà rimosso dallo storico locale.',
      entryDeleted: 'Farmaco eliminato',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking dei farmaci serve solo per organizzazione. Pet Life non prescrive farmaci, non suggerisce terapie, non calcola dosaggi e non sostituisce il veterinario.',
    );
  }
}