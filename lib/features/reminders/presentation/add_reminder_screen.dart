import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../application/reminder_controller.dart';
import '../domain/reminder.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  const AddReminderScreen({
    this.petId,
    super.key,
  });

  final String? petId;

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPetId;
  ReminderCategory _category = ReminderCategory.vaccine;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _selectedTime = selectedTime;
    });
  }

  Future<void> _saveReminder(List<Pet> pets) async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedPet = _selectedPetFrom(pets);

    if (selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi prima un animale')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final reminder = Reminder(
      id: const Uuid().v4(),
      petId: selectedPet.id,
      petName: selectedPet.name,
      category: _category,
      title: _titleController.text.trim(),
      scheduledAt: scheduledAt,
      status: ReminderStatus.active,
      createdAt: DateTime.now(),
      notes: _optionalText(_notesController.text),
    );

    await ref.read(reminderControllerProvider.notifier).addReminder(reminder);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderSaved)),
    );

    if (context.canPop()) {
      context.pop();
      return;
    }

    if (widget.petId == null) {
      context.go('/reminders');
    } else {
      context.go('/pets/${selectedPet.id}/reminders');
    }
  }

  Pet? _selectedPetFrom(List<Pet> pets) {
    final activePets = pets.where((pet) => !pet.isArchived).toList();

    if (activePets.isEmpty) {
      return null;
    }

    final selectedId = _selectedPetId;

    if (selectedId != null) {
      for (final pet in activePets) {
        if (pet.id == selectedId) {
          return pet;
        }
      }
    }

    return activePets.first;
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final petsState = ref.watch(petControllerProvider);

    final selectedDateLabel = DateFormat.yMMMd(locale).format(_selectedDate);
    final selectedTimeLabel = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addReminderTitle),
      ),
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          data: (pets) {
            final activePets = pets
                .where((pet) => !pet.isArchived)
                .toList(growable: false);

            final selectedPet = _selectedPetFrom(pets);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedPet?.id,
                    decoration: const InputDecoration(
                      labelText: 'Animale',
                      border: OutlineInputBorder(),
                    ),
                    items: activePets
                        .map(
                          (pet) => DropdownMenuItem(
                            value: pet.id,
                            child: Text(pet.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _selectedPetId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Seleziona un animale';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.reminderTitleLabel,
                      hintText: l10n.reminderTitleHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.reminderTitleRequired;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReminderCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: l10n.reminderCategoryLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ReminderCategory.vaccine,
                        child: Text(l10n.reminderCategoryVaccine),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.antiparasitic,
                        child: Text(l10n.reminderCategoryAntiparasitic),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.vetVisit,
                        child: Text(l10n.reminderCategoryVetVisit),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.checkup,
                        child: Text(l10n.reminderCategoryCheckup),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.medication,
                        child: Text(l10n.reminderCategoryMedication),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.insurance,
                        child: Text(l10n.reminderCategoryInsurance),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.grooming,
                        child: Text(l10n.reminderCategoryGrooming),
                      ),
                      DropdownMenuItem(
                        value: ReminderCategory.custom,
                        child: Text(l10n.reminderCategoryCustom),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _category = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('${l10n.reminderDateLabel}: $selectedDateLabel'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('${l10n.reminderTimeLabel}: $selectedTimeLabel'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.reminderNotesLabel,
                      hintText: l10n.reminderNotesHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _saveReminder(pets),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveReminder),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}