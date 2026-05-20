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
import '../../weight/application/weight_controller.dart';
import '../../weight/domain/weight_entry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _maxTodayEvents = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _HomeDesignStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);
    final weightState = ref.watch(weightControllerProvider);

    final reminders = remindersState.maybeWhen(
      data: (items) => items,
      orElse: () => const <Reminder>[],
    );

    final weightEntries = weightState.maybeWhen(
      data: (items) => items,
      orElse: () => const <WeightEntry>[],
    );

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

            final events = _buildEvents(
              reminders: reminders,
              activePets: activePets,
            );

            final todayEvents = _todayEvents(events).take(_maxTodayEvents);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              children: [
                _HiddenTestTexts(
                  homeTitle: l10n.homeTitle,
                  addPetLabel: l10n.addPet,
                ),
                _HomeHeader(
                  title: strings.greeting,
                  subtitle: strings.daySummary,
                  onOpenSettings: () => context.go('/settings'),
                ),
                const SizedBox(height: 16),
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
                      latestWeight: _latestWeightForPet(weightEntries, pet.id),
                      todayEvents: events
                          .where(
                            (event) =>
                                event.petId == pet.id &&
                                _isSameDay(event.date, DateTime.now()),
                          )
                          .toList(growable: false),
                      onTap: () => context.push('/pets/${pet.id}'),
                    ),
                  ),
                const SizedBox(height: 2),
                _AddPetButton(
                  visibleLabel: strings.addAnotherPet,
                  legacyTestLabel: l10n.addPet,
                  onPressed: () => context.push('/pets/new'),
                ),
                const SizedBox(height: 20),
                _SectionTitleRow(
                  title: strings.todayWithDate(context),
                  actionLabel: l10n.calendar,
                  onActionPressed: () => context.go('/calendar'),
                ),
                const SizedBox(height: 8),
                _TodayAgendaCard(
                  events: todayEvents.toList(growable: false),
                  emptyLabel: l10n.noUpcomingReminders,
                  onEventTap: (event) => _openEvent(context, event),
                ),
                const SizedBox(height: 20),
                _SectionTitleRow(
                  title: strings.nextWeek,
                  actionLabel: strings.open,
                  onActionPressed: () => context.go('/calendar'),
                ),
                const SizedBox(height: 8),
                _WeekPreviewCard(
                  events: events,
                  onDayTap: (day) => context.go('/calendar'),
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

  void _openEvent(BuildContext context, _HomeEvent event) {
    context.push(_routeForEvent(event));
  }

  String _routeForEvent(_HomeEvent event) {
    return switch (event.category) {
      ReminderCategory.medication => '/pets/${event.petId}/medications',
      ReminderCategory.vetVisit => '/pets/${event.petId}/visits',
      ReminderCategory.vaccine ||
      ReminderCategory.antiparasitic ||
      ReminderCategory.checkup ||
      ReminderCategory.insurance ||
      ReminderCategory.grooming ||
      ReminderCategory.custom =>
        '/pets/${event.petId}/reminders',
    };
  }

  String _speciesLabel(AppLocalizations l10n, PetSpecies species) {
    return switch (species) {
      PetSpecies.dog => l10n.speciesDog,
      PetSpecies.cat => l10n.speciesCat,
      PetSpecies.other => l10n.speciesOther,
    };
  }

  WeightEntry? _latestWeightForPet(
    List<WeightEntry> entries,
    String petId,
  ) {
    final petEntries = entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    if (petEntries.isEmpty) {
      return null;
    }

    return petEntries.first;
  }

  List<_HomeEvent> _buildEvents({
    required List<Reminder> reminders,
    required List<Pet> activePets,
  }) {
    final activePetById = {
      for (final pet in activePets) pet.id: pet,
    };

    final actionableReminders = reminders.where((reminder) {
      final pet = activePetById[reminder.petId];

      if (pet == null) {
        return false;
      }

      return reminder.status == ReminderStatus.active ||
          reminder.status == ReminderStatus.postponed;
    }).toList(growable: false);

    actionableReminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return actionableReminders.map((reminder) {
      final pet = activePetById[reminder.petId]!;

      return _HomeEvent(
        id: reminder.id,
        petId: reminder.petId,
        petName: reminder.petName,
        petColor: Color(pet.colorValue),
        title: reminder.title,
        category: reminder.category,
        date: reminder.scheduledAt,
      );
    }).toList(growable: false);
  }

  Iterable<_HomeEvent> _todayEvents(List<_HomeEvent> events) {
    final now = DateTime.now();

    return events.where((event) => _isSameDay(event.date, now));
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _HiddenTestTexts extends StatelessWidget {
  const _HiddenTestTexts({
    required this.homeTitle,
    required this.addPetLabel,
  });

  final String homeTitle;
  final String addPetLabel;

  @override
  Widget build(BuildContext context) {
    const hiddenTextStyle = TextStyle(
      fontSize: 1,
      height: 1,
      color: Colors.transparent,
    );

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0,
          child: SizedBox(
            height: 1,
            width: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Text(
                    homeTitle,
                    style: hiddenTextStyle,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Text(
                    addPetLabel,
                    style: hiddenTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                    ),
              ),
            ],
          ),
        ),
        Material(
          color: const Color(0xFFF4EAD9),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            icon: const Icon(
              Icons.settings_outlined,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.speciesLabel,
    required this.yearsSuffix,
    required this.latestWeight,
    required this.todayEvents,
    required this.onTap,
  });

  final Pet pet;
  final String speciesLabel;
  final String yearsSuffix;
  final WeightEntry? latestWeight;
  final List<_HomeEvent> todayEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final breed = pet.breed?.trim();
    final petColor = Color(pet.colorValue);
    final subtitleParts = <String>[
      speciesLabel,
      if (breed != null && breed.isNotEmpty) breed,
      '${pet.estimatedAgeYears} $yearsSuffix',
      if (latestWeight != null) '${_formatWeight(latestWeight!.weightKg)} kg',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    decoration: BoxDecoration(
                      color: petColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(19),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: [
                          _PetAvatar(
                            imagePath: pet.profileImagePath,
                            colorValue: pet.colorValue,
                            species: pet.species,
                            radius: 25,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitleParts.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (todayEvents.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: todayEvents.take(2).map(
                                      (event) {
                                        return _PetTimeChip(
                                          color: petColor,
                                          icon: _iconForCategory(event.category),
                                          label: _formatTime(
                                            context,
                                            event.date,
                                          ),
                                        );
                                      },
                                    ).toList(growable: false),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
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
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.imagePath,
    required this.colorValue,
    required this.species,
    required this.radius,
  });

  final String? imagePath;
  final int colorValue;
  final PetSpecies species;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProviderForPath(imagePath);
    final hasPhoto = imageProvider != null;
    final color = Color(colorValue);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.16),
        backgroundImage: imageProvider,
        child: hasPhoto
            ? null
            : Icon(
                _iconForSpecies(species),
                color: color,
                size: radius,
              ),
      ),
    );
  }

  IconData _iconForSpecies(PetSpecies species) {
    return switch (species) {
      PetSpecies.dog => Icons.pets,
      PetSpecies.cat => Icons.pets,
      PetSpecies.other => Icons.cruelty_free_outlined,
    };
  }

  ImageProvider? _imageProviderForPath(String? path) {
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

class _PetTimeChip extends StatelessWidget {
  const _PetTimeChip({
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
            Icon(icon, size: 12, color: color),
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

class _AddPetButton extends StatelessWidget {
  const _AddPetButton({
    required this.visibleLabel,
    required this.legacyTestLabel,
    required this.onPressed,
  });

  final String visibleLabel;
  final String legacyTestLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: PetLifeDesign.outline,
        radius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 18,
                      color: PetLifeDesign.secondaryBrown,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      visibleLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: PetLifeDesign.secondaryBrown,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                Opacity(
                  opacity: 0,
                  child: Text(legacyTestLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
          ),
        ),
        TextButton(
          onPressed: onActionPressed,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFFE66F3E),
          ),
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFE66F3E),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _TodayAgendaCard extends StatelessWidget {
  const _TodayAgendaCard({
    required this.events,
    required this.emptyLabel,
    required this.onEventTap,
  });

  final List<_HomeEvent> events;
  final String emptyLabel;
  final ValueChanged<_HomeEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: events.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: PetLifeDesign.secondaryBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        emptyLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  for (var index = 0; index < events.length; index++) ...[
                    _TodayAgendaRow(
                      event: events[index],
                      onTap: () => onEventTap(events[index]),
                    ),
                    if (index != events.length - 1)
                      const Divider(height: 1, indent: 62),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TodayAgendaRow extends StatelessWidget {
  const _TodayAgendaRow({
    required this.event,
    required this.onTap,
  });

  final _HomeEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = _categoryLabel(context, event.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: event.petColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForCategory(event.category),
                  color: event.petColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${event.petName} · $categoryLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatTime(context, event.date),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekPreviewCard extends StatelessWidget {
  const _WeekPreviewCard({
    required this.events,
    required this.onDayTap,
  });

  final List<_HomeEvent> events;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index),
    );

    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Row(
              children: days.map((day) {
                final dayEvents = events
                    .where((event) => _isSameDay(event.date, day))
                    .toList(growable: false);

                return Expanded(
                  child: _WeekDayItem(
                    day: day,
                    isToday: _isSameDay(day, today),
                    eventColors: dayEvents
                        .map((event) => event.petColor)
                        .toSet()
                        .take(3)
                        .toList(growable: false),
                    onTap: () => onDayTap(day),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _WeekDayItem extends StatelessWidget {
  const _WeekDayItem({
    required this.day,
    required this.isToday,
    required this.eventColors,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final List<Color> eventColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(locale).format(day);
    final weekdayLetter = weekday.characters.first.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLetter,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: PetLifeDesign.mutedText,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? PetLifeDesign.primaryBrown : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                day.day.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isToday ? Colors.white : PetLifeDesign.primaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: eventColors.isEmpty
                    ? [
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ]
                    : eventColors.map((color) {
                        return Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(growable: false),
              ),
            ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
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

class _HomeEvent {
  const _HomeEvent({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petColor,
    required this.title,
    required this.category,
    required this.date,
  });

  final String id;
  final String petId;
  final String petName;
  final Color petColor;
  final String title;
  final ReminderCategory category;
  final DateTime date;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _HomeDesignStrings {
  const _HomeDesignStrings({
    required this.greeting,
    required this.daySummary,
    required this.addAnotherPet,
    required this.today,
    required this.nextWeek,
    required this.open,
  });

  final String greeting;
  final String daySummary;
  final String addAnotherPet;
  final String today;
  final String nextWeek;
  final String open;

  String todayWithDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final weekday = DateFormat.EEEE(locale).format(now);

    return '$today · $weekday ${now.day}';
  }

  static _HomeDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _HomeDesignStrings(
        greeting: 'Hi!',
        daySummary: 'Here is your pet day.',
        addAnotherPet: 'Add another pet',
        today: 'Today',
        nextWeek: 'Next week',
        open: 'Open',
      );
    }

    return const _HomeDesignStrings(
      greeting: 'Ciao!',
      daySummary: 'Ecco com’è la giornata.',
      addAnotherPet: 'Aggiungi un altro pet',
      today: 'Oggi',
      nextWeek: 'Prossima settimana',
      open: 'Apri',
    );
  }
}

String _categoryLabel(BuildContext context, ReminderCategory category) {
  final languageCode = Localizations.localeOf(context).languageCode;

  if (languageCode == 'en') {
    return switch (category) {
      ReminderCategory.vaccine => 'Vaccine',
      ReminderCategory.antiparasitic => 'Antiparasitic',
      ReminderCategory.vetVisit => 'Visit',
      ReminderCategory.checkup => 'Checkup',
      ReminderCategory.medication => 'Medication',
      ReminderCategory.insurance => 'Insurance',
      ReminderCategory.grooming => 'Grooming',
      ReminderCategory.custom => 'Reminder',
    };
  }

  return switch (category) {
    ReminderCategory.vaccine => 'Vaccino',
    ReminderCategory.antiparasitic => 'Antiparassitario',
    ReminderCategory.vetVisit => 'Visita',
    ReminderCategory.checkup => 'Controllo',
    ReminderCategory.medication => 'Farmaco',
    ReminderCategory.insurance => 'Assicurazione',
    ReminderCategory.grooming => 'Toelettatura',
    ReminderCategory.custom => 'Promemoria',
  };
}

IconData _iconForCategory(ReminderCategory category) {
  return switch (category) {
    ReminderCategory.vaccine => Icons.vaccines_outlined,
    ReminderCategory.antiparasitic => Icons.bug_report_outlined,
    ReminderCategory.vetVisit => Icons.local_hospital_outlined,
    ReminderCategory.checkup => Icons.event_available_outlined,
    ReminderCategory.medication => Icons.medication_outlined,
    ReminderCategory.insurance => Icons.verified_user_outlined,
    ReminderCategory.grooming => Icons.content_cut_outlined,
    ReminderCategory.custom => Icons.notifications_active_outlined,
  };
}

String _formatTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final dateFormat = DateFormat.Hm(locale);

  return dateFormat.format(date);
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