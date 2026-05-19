import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/presentation/pet_life_navigation_bar.dart';
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
    final strings = _HomeDesignStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: petsState.when(
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                _HomeHeader(
                  title: strings.greeting,
                  subtitle: strings.daySummary,
                  onOpenSettings: () => context.go('/settings'),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.homeTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: PetLifeDesign.secondaryBrown,
                      ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 4),
                _AddPetButton(
                  label: l10n.addPet,
                  onPressed: () => context.push('/pets/new'),
                ),
                const SizedBox(height: 18),
                _UpcomingRemindersSection(
                  l10n: l10n,
                  strings: strings,
                  remindersState: remindersState,
                  activePets: activePets,
                  onOpenCalendar: () => context.go('/calendar'),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const PetLifeNavigationBar(
        selectedDestination: PetLifeDestination.home,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.subtitle,
    required this.onOpenSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
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
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
      ],
    );
  }
}

class _UpcomingRemindersSection extends StatelessWidget {
  const _UpcomingRemindersSection({
    required this.l10n,
    required this.strings,
    required this.remindersState,
    required this.activePets,
    required this.onOpenCalendar,
  });

  final AppLocalizations l10n;
  final _HomeDesignStrings strings;
  final AsyncValue<List<Reminder>> remindersState;
  final List<Pet> activePets;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return remindersState.when(
      loading: () => _SoftCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.loadingPets),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (reminders) {
        final upcomingReminders = _upcomingReminders(reminders, activePets);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.todayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenCalendar,
                  child: Text(l10n.calendar),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upcomingReminders.isEmpty)
              _SoftCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.noUpcomingReminders),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcomingReminders.map(
                (reminder) {
                  final pet = _findPet(activePets, reminder.petId);

                  return _UpcomingReminderTile(
                    title: reminder.title,
                    petName: reminder.petName,
                    dateLabel: _formatDate(context, reminder.scheduledAt),
                    timeLabel: _formatTime(context, reminder.scheduledAt),
                    petColorValue: pet?.colorValue ?? Pet.defaultColorValue,
                  );
                },
              ),
          ],
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

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.MMMEd(locale);

    return dateFormat.format(date);
  }

  String _formatTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.Hm(locale);

    return dateFormat.format(date);
  }
}

class _UpcomingReminderTile extends StatelessWidget {
  const _UpcomingReminderTile({
    required this.title,
    required this.petName,
    required this.dateLabel,
    required this.timeLabel,
    required this.petColorValue,
  });

  final String title;
  final String petName;
  final String dateLabel;
  final String timeLabel;
  final int petColorValue;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: Color(petColorValue),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(PetLifeDesign.radiusMedium),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(petColorValue).withValues(
                        alpha: 0.14,
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        size: 18,
                        color: Color(petColorValue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$petName · $dateLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: PetLifeDesign.primaryBrown,
                          ),
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
    final petColor = Color(pet.colorValue);

    return _SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: petColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(PetLifeDesign.radiusLarge),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      _PetAvatar(
                        imagePath: pet.profileImagePath,
                        colorValue: pet.colorValue,
                        radius: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              breed == null || breed.isEmpty
                                  ? '$speciesLabel · ${pet.estimatedAgeYears} $yearsSuffix'
                                  : '$speciesLabel · $breed · ${pet.estimatedAgeYears} $yearsSuffix',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _PetMiniChip(
                                  color: petColor,
                                  icon: Icons.pets_outlined,
                                  label: openLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: PetLifeDesign.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetMiniChip extends StatelessWidget {
  const _PetMiniChip({
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
        color: color.withValues(alpha: 0.12),
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

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.imagePath,
    required this.colorValue,
    required this.radius,
  });

  final String? imagePath;
  final int colorValue;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProviderForPath(imagePath);
    final hasPhoto = imageProvider != null;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(colorValue),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(colorValue).withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Color(colorValue).withValues(alpha: 0.18),
        backgroundImage: imageProvider,
        child: hasPhoto
            ? null
            : Icon(
                Icons.pets,
                color: Color(colorValue),
                size: radius,
              ),
      ),
    );
  }

  ImageProvider<Object>? _imageProviderForPath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }
}

class _AddPetButton extends StatelessWidget {
  const _AddPetButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: PetLifeDesign.outline.withValues(alpha: 0.95),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: PetLifeDesign.secondaryBrown,
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
    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PetLifeDesign.infoLilac,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.pets,
                size: 34,
                color: Color(0xFF9C6ADE),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
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

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: child,
    );
  }
}

class _HomeDesignStrings {
  const _HomeDesignStrings({
    required this.greeting,
    required this.daySummary,
    required this.todayTitle,
  });

  final String greeting;
  final String daySummary;
  final String todayTitle;

  static _HomeDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _HomeDesignStrings(
        greeting: 'Hi!',
        daySummary: 'Here is your pet day.',
        todayTitle: 'Today',
      );
    }

    return const _HomeDesignStrings(
      greeting: 'Ciao!',
      daySummary: 'Ecco com’è la giornata.',
      todayTitle: 'Oggi',
    );
  }
}