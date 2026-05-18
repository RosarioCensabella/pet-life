import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(strings.visitsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(strings.visitsTitle)),
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
            appBar: AppBar(title: Text(strings.visitsTitle)),
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
            title: Text(strings.visitsTitle),
          ),
          body: visitState.when(
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

  final _VisitStrings strings;

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
              DropdownButtonFormField<VisitType>(
                initialValue: selectedVisitType,
                decoration: InputDecoration(
                  labelText: strings.visitTypeLabel,
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
              OutlinedButton.icon(
                onPressed: onSelectVisitDate,
                icon: const Icon(Icons.event_outlined),
                label: Text('${strings.visitDate}: $visitDateLabel'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: clinicNameController,
                decoration: InputDecoration(
                  labelText: strings.clinicNameLabel,
                  hintText: strings.clinicNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: outcomeController,
                decoration: InputDecoration(
                  labelText: strings.outcomeLabel,
                  hintText: strings.outcomeHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onSelectNextVisitDate,
                icon: const Icon(Icons.event_available_outlined),
                label: Text('${strings.nextVisitDate}: $nextVisitDateLabel'),
              ),
              if (nextVisitDate != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onClearNextVisitDate,
                  icon: const Icon(Icons.close_outlined),
                  label: Text(strings.clearNextVisitDate),
                ),
              ],
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

class _EmptyVisitCard extends StatelessWidget {
  const _EmptyVisitCard({
    required this.strings,
  });

  final _VisitStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.local_hospital_outlined,
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

    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_hospital_outlined),
        title: Text(entry.reason),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.visitTypeLabelFor(entry.visitType)} · $visitDateLabel',
            ),
            if (entry.clinicName != null && entry.clinicName!.trim().isNotEmpty)
              Text('${strings.clinicNameShort}: ${entry.clinicName!}'),
            if (entry.outcome != null && entry.outcome!.trim().isNotEmpty)
              Text('${strings.outcomeShort}: ${entry.outcome!}'),
            if (nextVisitDateLabel != null)
              Text('${strings.nextVisitDate}: $nextVisitDateLabel'),
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

class _VisitStrings {
  const _VisitStrings({
    required this.visitsTitle,
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

  final String visitsTitle;
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
        visitsTitle: 'Visits',
        addEntry: 'Add visit',
        visitTypeLabel: 'Visit type',
        visitRoutine: 'Routine',
        visitVaccine: 'Vaccine',
        visitCheckup: 'Checkup',
        visitFollowUp: 'Follow-up',
        visitUrgent: 'Urgent visit record',
        visitOther: 'Other',
        reasonLabel: 'Reason',
        reasonHint: 'E.g. Annual checkup',
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
        deleteEntryMessage: 'This removes the visit from the local history.',
        entryDeleted: 'Visit deleted',
        delete: 'Delete',
        cancel: 'Cancel',
        petNotFound: 'Pet not found',
        disclaimer:
            'Visit tracking is only for organization. Pet Life does not generate diagnoses, interpret medical records, triage symptoms or replace your veterinarian.',
      );
    }

    return const _VisitStrings(
      visitsTitle: 'Visite',
      addEntry: 'Aggiungi visita',
      visitTypeLabel: 'Tipo visita',
      visitRoutine: 'Routine',
      visitVaccine: 'Vaccino',
      visitCheckup: 'Controllo',
      visitFollowUp: 'Follow-up',
      visitUrgent: 'Registro visita urgente',
      visitOther: 'Altro',
      reasonLabel: 'Motivo',
      reasonHint: 'Es. Controllo annuale',
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
      deleteEntryMessage: 'La visita verrà rimossa dallo storico locale.',
      entryDeleted: 'Visita eliminata',
      delete: 'Elimina',
      cancel: 'Annulla',
      petNotFound: 'Pet non trovato',
      disclaimer:
          'Il tracking delle visite serve solo per organizzazione. Pet Life non genera diagnosi, non interpreta referti, non fa triage e non sostituisce il veterinario.',
    );
  }
}