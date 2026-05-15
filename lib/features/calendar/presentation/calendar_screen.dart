import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _allPetsFilterValue = 'all';

  String _selectedPetId = _allPetsFilterValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
      ),
      body: petsState.when(
        loading: () => Center(child: Text(l10n.loadingPets)),
        error: (error, stackTrace) => _ErrorState(error: error),
        data: (pets) {
          final activePets = pets
              .where((pet) => !pet.isArchived)
              .toList(growable: false);

          return remindersState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _ErrorState(error: error),
            data: (reminders) {
              final visibleReminders = _filterReminders(
                reminders: reminders,
                activePets: activePets,
              );

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _PetFilterCard(
                    l10n: l10n,
                    activePets: activePets,
                    selectedPetId: _selectedPetId,
                    allPetsFilterValue: _allPetsFilterValue,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedPetId = value;
                      });
                    },
                  ),
                  if (visibleReminders.isEmpty)
                    _EmptyCalendarCard(
                      title: l10n.calendarEmptyTitle,
                      description: l10n.calendarEmptyDescription,
                    )
                  else
                    ...visibleReminders.map(
                      (reminder) => _CalendarReminderCard(
                        reminder: reminder,
                        categoryLabel: _categoryLabel(
                          l10n,
                          reminder.category,
                        ),
                        statusLabel: _statusLabel(l10n, reminder.status),
                        dateLabel: _formatDate(context, reminder.scheduledAt),
                        onTap: () => context.go(
                          '/pets/${reminder.petId}/reminders',
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/home');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.homeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.calendar,
          ),
        ],
      ),
    );
  }

  List<Reminder> _filterReminders({
    required List<Reminder> reminders,
    required List<Pet> activePets,
  }) {
    final activePetIds = activePets.map((pet) => pet.id).toSet();

    final filtered = reminders.where((reminder) {
      final belongsToActivePet = activePetIds.contains(reminder.petId);

      if (!belongsToActivePet) {
        return false;
      }

      if (_selectedPetId == _allPetsFilterValue) {
        return true;
      }

      return reminder.petId == _selectedPetId;
    }).toList(growable: false);

    filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return filtered;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return dateFormat.format(date);
  }

  String _categoryLabel(AppLocalizations l10n, ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => l10n.reminderCategoryVaccine,
      ReminderCategory.antiparasitic => l10n.reminderCategoryAntiparasitic,
      ReminderCategory.vetVisit => l10n.reminderCategoryVetVisit,
      ReminderCategory.checkup => l10n.reminderCategoryCheckup,
      ReminderCategory.medication => l10n.reminderCategoryMedication,
      ReminderCategory.insurance => l10n.reminderCategoryInsurance,
      ReminderCategory.grooming => l10n.reminderCategoryGrooming,
      ReminderCategory.custom => l10n.reminderCategoryCustom,
    };
  }

  String _statusLabel(AppLocalizations l10n, ReminderStatus status) {
    return switch (status) {
      ReminderStatus.active => l10n.reminderStatusActive,
      ReminderStatus.completed => l10n.reminderStatusCompleted,
      ReminderStatus.postponed => l10n.reminderStatusPostponed,
      ReminderStatus.skipped => l10n.reminderStatusSkipped,
    };
  }
}

class _PetFilterCard extends StatelessWidget {
  const _PetFilterCard({
    required this.l10n,
    required this.activePets,
    required this.selectedPetId,
    required this.allPetsFilterValue,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final List<Pet> activePets;
  final String selectedPetId;
  final String allPetsFilterValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DropdownButtonFormField<String>(
          initialValue: selectedPetId,
          decoration: InputDecoration(
            labelText: l10n.filterByPet,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: allPetsFilterValue,
              child: Text(l10n.allPets),
            ),
            ...activePets.map(
              (pet) => DropdownMenuItem(
                value: pet.id,
                child: Text(pet.name),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CalendarReminderCard extends StatelessWidget {
  const _CalendarReminderCard({
    required this.reminder,
    required this.categoryLabel,
    required this.statusLabel,
    required this.dateLabel,
    required this.onTap,
  });

  final Reminder reminder;
  final String categoryLabel;
  final String statusLabel;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.event_available_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(reminder.petName),
                    Text(categoryLabel),
                    Text(dateLabel),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(label: Text(statusLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCalendarCard extends StatelessWidget {
  const _EmptyCalendarCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
          ],
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