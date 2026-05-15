import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _maxUpcomingReminders = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
      ),
      body: petsState.when(
        loading: () => Center(
          child: Text(l10n.loadingPets),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (pets) {
          final activePets = pets
              .where((pet) => !pet.isArchived)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _UpcomingRemindersSection(
                l10n: l10n,
                remindersState: remindersState,
                activePets: activePets,
                onOpenCalendar: () => context.go('/calendar'),
              ),
              if (activePets.isEmpty)
                _EmptyPetsCard(
                  title: l10n.addFirstPetTitle,
                  description: l10n.addFirstPetDescription,
                )
              else
                ...activePets.map(
                  (pet) => _PetCard(
                    pet: pet,
                    speciesLabel: _speciesLabel(l10n, pet.species),
                    yearsSuffix: l10n.yearsSuffix,
                    openLabel: l10n.openPetDashboard,
                    onTap: () => context.push('/pets/${pet.id}'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/pets/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addPet),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.go('/calendar');
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

  String _speciesLabel(AppLocalizations l10n, PetSpecies species) {
    return switch (species) {
      PetSpecies.dog => l10n.speciesDog,
      PetSpecies.cat => l10n.speciesCat,
      PetSpecies.other => l10n.speciesOther,
    };
  }
}

class _UpcomingRemindersSection extends StatelessWidget {
  const _UpcomingRemindersSection({
    required this.l10n,
    required this.remindersState,
    required this.activePets,
    required this.onOpenCalendar,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<Reminder>> remindersState;
  final List<Pet> activePets;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return remindersState.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(l10n.loadingPets),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (reminders) {
        final upcomingReminders = _upcomingReminders(reminders, activePets);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.upcomingRemindersTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenCalendar,
                      child: Text(l10n.calendar),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (upcomingReminders.isEmpty)
                  Text(l10n.noUpcomingReminders)
                else
                  ...upcomingReminders.map(
                    (reminder) => _UpcomingReminderTile(
                      title: reminder.title,
                      petName: reminder.petName,
                      dateLabel: _formatDate(context, reminder.scheduledAt),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Reminder> _upcomingReminders(
    List<Reminder> reminders,
    List<Pet> activePets,
  ) {
    final now = DateTime.now();
    final activePetIds = activePets.map((pet) => pet.id).toSet();

    final upcoming = reminders.where((reminder) {
      final belongsToActivePet = activePetIds.contains(reminder.petId);
      final isFuture = reminder.scheduledAt.isAfter(now);
      final isActionable = reminder.status == ReminderStatus.active ||
          reminder.status == ReminderStatus.postponed;

      return belongsToActivePet && isFuture && isActionable;
    }).toList(growable: false);

    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return upcoming.take(HomeScreen._maxUpcomingReminders).toList();
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return dateFormat.format(date);
  }
}

class _UpcomingReminderTile extends StatelessWidget {
  const _UpcomingReminderTile({
    required this.title,
    required this.petName,
    required this.dateLabel,
  });

  final String title;
  final String petName;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chevron_right),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text('$petName · $dateLabel'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.speciesLabel,
    required this.yearsSuffix,
    required this.openLabel,
    required this.onTap,
  });

  final Pet pet;
  final String speciesLabel;
  final String yearsSuffix;
  final String openLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final breed = pet.breed?.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.pets,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breed == null || breed.isEmpty
                          ? '$speciesLabel · ${pet.estimatedAgeYears} $yearsSuffix'
                          : '$speciesLabel · $breed · ${pet.estimatedAgeYears} $yearsSuffix',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      openLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPetsCard extends StatelessWidget {
  const _EmptyPetsCard({
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
              Icons.pets,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}