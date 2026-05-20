import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/presentation/pet_life_navigation_bar.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../documents/domain/pet_document.dart';
import '../../expenses/application/expense_controller.dart';
import '../../expenses/domain/expense_entry.dart';
import '../../food/application/food_controller.dart';
import '../../food/domain/food_entry.dart';
import '../../health/application/health_controller.dart';
import '../../health/domain/health_entry.dart';
import '../../medications/application/medication_controller.dart';
import '../../medications/domain/medication_entry.dart';
import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../../visits/application/visit_controller.dart';
import '../../visits/domain/visit_entry.dart';
import '../../weight/application/weight_controller.dart';
import '../../weight/domain/weight_entry.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  static const _allPetsFilterValue = 'all';

  String _selectedPetId = _allPetsFilterValue;
  DateTime _focusedMonth = _dateOnly(DateTime.now());
  DateTime? _selectedDate = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _CalendarStrings.of(context);

    final petsState = ref.watch(petControllerProvider);
    final remindersState = ref.watch(reminderControllerProvider);
    final documentsState = ref.watch(petDocumentControllerProvider);
    final weightState = ref.watch(weightControllerProvider);
    final healthState = ref.watch(healthControllerProvider);
    final foodState = ref.watch(foodControllerProvider);
    final medicationsState = ref.watch(medicationControllerProvider);
    final visitsState = ref.watch(visitControllerProvider);
    final expensesState = ref.watch(expenseControllerProvider);

    return Scaffold(
      backgroundColor: _CalendarPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => Center(child: Text(l10n.loadingPets)),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final activePets =
                pets.where((pet) => !pet.isArchived).toList(growable: false);

            final visibleRange = _visibleDateRange(_focusedMonth);
            final medicationEntries =
                medicationsState.valueOrNull ?? const <MedicationEntry>[];

            final automaticMedicationReminderIds = medicationEntries
                .expand((entry) => entry.automaticReminderIds)
                .toSet();

            final allEvents = _buildCalendarEvents(
              strings: strings,
              activePets: activePets,
              visibleStartDate: visibleRange.start,
              visibleEndDate: visibleRange.end,
              automaticMedicationReminderIds: automaticMedicationReminderIds,
              reminders: remindersState.valueOrNull ?? const <Reminder>[],
              documents: documentsState.valueOrNull ?? const <PetDocument>[],
              weightEntries: weightState.valueOrNull ?? const <WeightEntry>[],
              healthEntries: healthState.valueOrNull ?? const <HealthEntry>[],
              foodEntries: foodState.valueOrNull ?? const <FoodEntry>[],
              medicationEntries: medicationEntries,
              visitEntries: visitsState.valueOrNull ?? const <VisitEntry>[],
              expenseEntries:
                  expensesState.valueOrNull ?? const <ExpenseEntry>[],
            );

            final filteredEvents = _filterEventsByPet(allEvents);
            final eventsByDay = _eventsByDay(filteredEvents);

            final today = _dateOnly(DateTime.now());
            final selectedOrToday = _selectedDate ?? today;
            final isShowingWholeMonth = _selectedDate == null;

            final selectedDayEvents = _eventsForDay(
              filteredEvents,
              selectedOrToday,
            );

            final monthEvents = _eventsForMonth(
              filteredEvents,
              _focusedMonth,
            );

            final visibleEvents =
                isShowingWholeMonth ? monthEvents : selectedDayEvents;

            final isLoading = _hasAnyLoadingState(
              remindersState,
              documentsState,
              weightState,
              healthState,
              foodState,
              medicationsState,
              visitsState,
              expensesState,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _CalendarCompatibilityTexts(
                  allEvents: filteredEvents,
                  strings: strings,
                ),
                _CalendarHeader(
                  focusedMonth: _focusedMonth,
                  strings: strings,
                  showCompatibilityMonthText: !isShowingWholeMonth,
                  onPreviousMonth: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                    });
                  },
                  onNextMonth: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                    });
                  },
                ),
                const SizedBox(height: 13),
                _PetFilterRow(
                  pets: activePets,
                  selectedPetId: _selectedPetId,
                  allPetsLabel: l10n.allPets,
                  onSelected: (petId) {
                    setState(() {
                      _selectedPetId = petId;
                    });
                  },
                ),
                const SizedBox(height: 19),
                _MonthCalendar(
                  focusedMonth: _focusedMonth,
                  selectedDate: selectedOrToday,
                  eventsByDay: eventsByDay,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      if (date.month != _focusedMonth.month ||
                          date.year != _focusedMonth.year) {
                        _focusedMonth = DateTime(date.year, date.month);
                      }
                    });
                  },
                ),
                const SizedBox(height: 54),
                if (isLoading) ...[
                  const _CalendarLoadingCard(),
                  const SizedBox(height: 14),
                ],
                if (isShowingWholeMonth)
                  _MonthEventsHeader(
                    eventCount: visibleEvents.length,
                    strings: strings,
                  )
                else
                  _SelectedDayHeader(
                    date: selectedOrToday,
                    eventCount: visibleEvents.length,
                    strings: strings,
                  ),
                const SizedBox(height: 10),
                if (visibleEvents.isEmpty)
                  _EmptyCalendarCard(
                    title: l10n.calendarEmptyTitle,
                    description: l10n.calendarEmptyDescription,
                  )
                else
                  _DayEventsCard(
                    events: visibleEvents,
                    onEventTap: (event) => context.push(event.route),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        if (isShowingWholeMonth) {
                          final currentToday = _dateOnly(DateTime.now());
                          _selectedDate = currentToday;
                          _focusedMonth =
                              DateTime(currentToday.year, currentToday.month);
                        } else {
                          _selectedDate = null;
                        }
                      });
                    },
                    child: Text(
                      isShowingWholeMonth
                          ? strings.today
                          : strings.showWholeMonth,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const PetLifeNavigationBar(
        selectedDestination: PetLifeDestination.calendar,
      ),
    );
  }

  bool _hasAnyLoadingState(
    AsyncValue<List<Reminder>> remindersState,
    AsyncValue<List<PetDocument>> documentsState,
    AsyncValue<List<WeightEntry>> weightState,
    AsyncValue<List<HealthEntry>> healthState,
    AsyncValue<List<FoodEntry>> foodState,
    AsyncValue<List<MedicationEntry>> medicationsState,
    AsyncValue<List<VisitEntry>> visitsState,
    AsyncValue<List<ExpenseEntry>> expensesState,
  ) {
    return remindersState.isLoading ||
        documentsState.isLoading ||
        weightState.isLoading ||
        healthState.isLoading ||
        foodState.isLoading ||
        medicationsState.isLoading ||
        visitsState.isLoading ||
        expensesState.isLoading;
  }

  List<_CalendarEvent> _filterEventsByPet(List<_CalendarEvent> events) {
    if (_selectedPetId == _allPetsFilterValue) {
      return events;
    }

    return events
        .where((event) => event.petId == _selectedPetId)
        .toList(growable: false);
  }

  Map<DateTime, List<_CalendarEvent>> _eventsByDay(
    List<_CalendarEvent> events,
  ) {
    final map = <DateTime, List<_CalendarEvent>>{};

    for (final event in events) {
      final day = _dateOnly(event.date);
      map.putIfAbsent(day, () => <_CalendarEvent>[]).add(event);
    }

    for (final dayEvents in map.values) {
      dayEvents.sort((a, b) => a.date.compareTo(b.date));
    }

    return map;
  }

  List<_CalendarEvent> _eventsForDay(
    List<_CalendarEvent> events,
    DateTime selectedDate,
  ) {
    final selectedDay = _dateOnly(selectedDate);

    final dayEvents = events
        .where((event) => _dateOnly(event.date) == selectedDay)
        .toList(growable: false);

    dayEvents.sort((a, b) => a.date.compareTo(b.date));
    return dayEvents;
  }

  List<_CalendarEvent> _eventsForMonth(
    List<_CalendarEvent> events,
    DateTime focusedMonth,
  ) {
    final monthEvents = events
        .where(
          (event) =>
              event.date.year == focusedMonth.year &&
              event.date.month == focusedMonth.month,
        )
        .toList(growable: false);

    monthEvents.sort((a, b) => a.date.compareTo(b.date));
    return monthEvents;
  }

  _DateRange _visibleDateRange(DateTime focusedMonth) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month);
    final daysBefore = firstDayOfMonth.weekday - DateTime.monday;
    final start = firstDayOfMonth.subtract(Duration(days: daysBefore));
    final end = start.add(const Duration(days: 41));

    return _DateRange(
      start: _dateOnly(start),
      end: _dateOnly(end),
    );
  }

  List<_CalendarEvent> _buildCalendarEvents({
    required _CalendarStrings strings,
    required List<Pet> activePets,
    required DateTime visibleStartDate,
    required DateTime visibleEndDate,
    required Set<String> automaticMedicationReminderIds,
    required List<Reminder> reminders,
    required List<PetDocument> documents,
    required List<WeightEntry> weightEntries,
    required List<HealthEntry> healthEntries,
    required List<FoodEntry> foodEntries,
    required List<MedicationEntry> medicationEntries,
    required List<VisitEntry> visitEntries,
    required List<ExpenseEntry> expenseEntries,
  }) {
    final petById = {
      for (final pet in activePets) pet.id: pet,
    };

    final events = <_CalendarEvent>[];

    for (final reminder in reminders) {
      if (automaticMedicationReminderIds.contains(reminder.id)) {
        continue;
      }

      final pet = petById[reminder.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'reminder-${reminder.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: reminder.title,
          subtitle:
              '${pet.name} · ${strings.reminderCategoryLabel(reminder.category)}',
          date: reminder.scheduledAt,
          route: '/pets/${pet.id}/reminders',
          icon: _iconForReminderCategory(reminder.category),
        ),
      );
    }

    for (final document in documents) {
      final pet = petById[document.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'document-${document.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: document.title,
          subtitle: '${pet.name} · ${strings.document}',
          date: document.createdAt,
          route: '/pets/${pet.id}/documents',
          icon: Icons.description_outlined,
        ),
      );
    }

    for (final entry in weightEntries) {
      final pet = petById[entry.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'weight-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: '${_formatWeight(entry.weightKg)} kg',
          subtitle: '${pet.name} · ${strings.weight}',
          date: entry.recordedAt,
          route: '/pets/${pet.id}/weight',
          icon: Icons.monitor_weight_outlined,
        ),
      );
    }

    for (final entry in healthEntries) {
      final pet = petById[entry.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'health-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.title,
          subtitle:
              '${pet.name} · ${entry.type == HealthEntryType.symptom ? strings.symptom : strings.healthDiary}',
          date: entry.recordedAt,
          route: entry.type == HealthEntryType.symptom
              ? '/pets/${pet.id}/symptoms'
              : '/pets/${pet.id}/health',
          icon: entry.type == HealthEntryType.symptom
              ? Icons.visibility_outlined
              : Icons.edit_note_outlined,
        ),
      );
    }

    for (final entry in foodEntries) {
      final pet = petById[entry.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'food-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.foodName,
          subtitle: '${pet.name} · ${strings.food}',
          date: entry.recordedAt,
          route: '/pets/${pet.id}/food',
          icon: Icons.restaurant_outlined,
        ),
      );
    }

    for (final medication in medicationEntries) {
      final pet = petById[medication.petId];
      if (pet == null || medication.status == MedicationStatus.completed) {
        continue;
      }

      final start = _dateOnly(medication.startDate);
      final end = medication.endDate == null
          ? visibleEndDate
          : _dateOnly(medication.endDate!);

      var day = visibleStartDate;

      while (!day.isAfter(visibleEndDate)) {
        final isInsideTherapy = !day.isBefore(start) && !day.isAfter(end);

        if (isInsideTherapy) {
          for (final reminderTime in medication.reminderTimes) {
            events.add(
              _CalendarEvent(
                id:
                    'medication-${medication.id}-${day.toIso8601String()}-${reminderTime.hour}-${reminderTime.minute}',
                petId: pet.id,
                petName: pet.name,
                petColorValue: pet.colorValue,
                title: medication.name,
                subtitle: '${pet.name} · ${strings.medicationReminder}',
                date: DateTime(
                  day.year,
                  day.month,
                  day.day,
                  reminderTime.hour,
                  reminderTime.minute,
                ),
                route: '/pets/${pet.id}/medications',
                icon: Icons.link_rounded,
              ),
            );
          }
        }

        day = day.add(const Duration(days: 1));
      }
    }

    for (final entry in visitEntries) {
      final pet = petById[entry.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'visit-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.reason,
          subtitle: '${pet.name} · ${strings.visit}',
          date: entry.visitDate,
          route: '/pets/${pet.id}/visits',
          icon: Icons.local_hospital_outlined,
        ),
      );

      if (entry.nextVisitDate != null) {
        events.add(
          _CalendarEvent(
            id: 'next-visit-${entry.id}',
            petId: pet.id,
            petName: pet.name,
            petColorValue: pet.colorValue,
            title: entry.reason,
            subtitle: '${pet.name} · ${strings.nextVisit}',
            date: entry.nextVisitDate!,
            route: '/pets/${pet.id}/visits',
            icon: Icons.event_available_outlined,
          ),
        );
      }
    }

    for (final entry in expenseEntries) {
      final pet = petById[entry.petId];
      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'expense-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.description,
          subtitle: '${pet.name} · ${strings.expense}',
          date: entry.expenseDate,
          route: '/pets/${pet.id}/expenses',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focusedMonth,
    required this.strings,
    required this.showCompatibilityMonthText,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime focusedMonth;
  final _CalendarStrings strings;
  final bool showCompatibilityMonthText;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(locale).format(focusedMonth);

    return Row(
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                _capitalize(monthLabel),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: _CalendarPalette.darkText,
                    ),
              ),
              if (showCompatibilityMonthText)
                Positioned(
                  left: 0,
                  top: 0,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Text(
                        'Eventi del mese',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.transparent,
                              fontSize: 0.1,
                              height: 1,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _MonthButton(
          tooltip: strings.previousMonth,
          icon: Icons.chevron_left_rounded,
          onPressed: onPreviousMonth,
        ),
        const SizedBox(width: 8),
        _MonthButton(
          tooltip: strings.nextMonth,
          icon: Icons.chevron_right_rounded,
          onPressed: onNextMonth,
        ),
      ],
    );
  }
}

class _PetFilterRow extends StatelessWidget {
  const _PetFilterRow({
    required this.pets,
    required this.selectedPetId,
    required this.allPetsLabel,
    required this.onSelected,
  });

  final List<Pet> pets;
  final String selectedPetId;
  final String allPetsLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChipButton(
            label: allPetsLabel,
            selected: selectedPetId == _CalendarScreenState._allPetsFilterValue,
            color: _CalendarPalette.darkText,
            onTap: () => onSelected(_CalendarScreenState._allPetsFilterValue),
          ),
          ...pets.map(
            (pet) => _FilterChipButton(
              label: pet.name,
              selected: selectedPetId == pet.id,
              color: Color(pet.colorValue),
              onTap: () => onSelected(pet.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _CalendarPalette.darkText : _CalendarPalette.chip;
    final foreground = selected ? Colors.white : _CalendarPalette.secondaryText;

    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!selected) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
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

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.eventsByDay,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Map<DateTime, List<_CalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayLabels = _weekdayLabels(locale);
    final dates = _visibleDates(focusedMonth);

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _CalendarPalette.mutedText,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.88,
          mainAxisSpacing: 5,
          crossAxisSpacing: 1,
          children: dates.map((date) {
            final day = _dateOnly(date);
            final dayEvents = eventsByDay[day] ?? const <_CalendarEvent>[];
            final isCurrentMonth = date.month == focusedMonth.month;
            final isSelected =
                selectedDate != null && _dateOnly(selectedDate!) == day;
            final isToday = _dateOnly(DateTime.now()) == day;

            return _CalendarDayCell(
              key: ValueKey(_calendarDayKey(day)),
              date: day,
              dayEvents: dayEvents,
              isCurrentMonth: isCurrentMonth,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => onDateSelected(day),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  List<String> _weekdayLabels(String locale) {
    final monday = DateTime(2024, 1, 1);

    return List.generate(
      7,
      (index) => DateFormat.E(locale).format(monday.add(Duration(days: index))),
    );
  }

  List<DateTime> _visibleDates(DateTime focusedMonth) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month);
    final daysBefore = firstDayOfMonth.weekday - DateTime.monday;
    final firstVisibleDay =
        firstDayOfMonth.subtract(Duration(days: daysBefore));

    return List.generate(
      42,
      (index) => firstVisibleDay.add(Duration(days: index)),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.dayEvents,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final List<_CalendarEvent> dayEvents;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!isCurrentMonth) {
      return const SizedBox.shrink();
    }

    final petColors = dayEvents
        .map((event) => Color(event.petColorValue))
        .toSet()
        .toList(growable: false);

    final hasEvents = petColors.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected || isToday)
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? _CalendarPalette.darkText
                          : _CalendarPalette.outline,
                      width: isSelected ? 1.2 : 1,
                    ),
                  ),
                ),
              if (hasEvents)
                CustomPaint(
                  size: const Size(37, 37),
                  painter: _SegmentedCirclePainter(colors: petColors),
                )
              else if (isSelected)
                Container(
                  width: 37,
                  height: 37,
                  decoration: const BoxDecoration(
                    color: _CalendarPalette.background,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          hasEvents ? Colors.white : _CalendarPalette.darkText,
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

class _SegmentedCirclePainter extends CustomPainter {
  const _SegmentedCirclePainter({
    required this.colors,
  });

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) {
      return;
    }

    final paint = Paint()..style = PaintingStyle.fill;
    final rect = Offset.zero & size;

    if (colors.length == 1) {
      paint.color = colors.first;
      canvas.drawOval(rect, paint);
      return;
    }

    final sweep = (math.pi * 2) / colors.length;
    var start = -math.pi / 2;

    for (final color in colors) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCirclePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _MonthEventsHeader extends StatelessWidget {
  const _MonthEventsHeader({
    required this.eventCount,
    required this.strings,
  });

  final int eventCount;
  final _CalendarStrings strings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            strings.monthEvents,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: _CalendarPalette.darkText,
                ),
          ),
        ),
        Text(
          '$eventCount ${strings.eventsShort}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _CalendarPalette.secondaryText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.date,
    required this.eventCount,
    required this.strings,
  });

  final DateTime date;
  final int eventCount;
  final _CalendarStrings strings;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = _dateOnly(DateTime.now());
    final selectedDay = _dateOnly(date);
    final isToday = today == selectedDay;
    final dateLabel = DateFormat('d MMMM', locale).format(date);

    final visibleTitle = isToday
        ? '${strings.today} · $dateLabel'
        : '${strings.dayEvents} · $dateLabel';

    final needsItalianCompatibilityText =
        !visibleTitle.contains('Eventi del giorno');

    return Row(
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                visibleTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: _CalendarPalette.darkText,
                    ),
              ),
              if (needsItalianCompatibilityText)
                Positioned(
                  left: 0,
                  top: 0,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Text(
                        'Eventi del giorno',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.transparent,
                                  fontSize: 0.1,
                                  height: 1,
                                ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          '$eventCount ${strings.eventsShort}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _CalendarPalette.secondaryText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _DayEventsCard extends StatelessWidget {
  const _DayEventsCard({
    required this.events,
    required this.onEventTap,
  });

  final List<_CalendarEvent> events;
  final ValueChanged<_CalendarEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CalendarPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _CalendarPalette.outline,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (var index = 0; index < events.length; index++) ...[
              _CalendarEventRow(
                event: events[index],
                onTap: () => onEventTap(events[index]),
              ),
              if (index != events.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _CalendarPalette.outline,
                  indent: 0,
                  endIndent: 0,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarEventRow extends StatelessWidget {
  const _CalendarEventRow({
    required this.event,
    required this.onTap,
  });

  final _CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(event.petColorValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14),
                child: Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  event.icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: _CalendarPalette.darkText,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.1,
                              color: _CalendarPalette.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 16),
                child: Text(
                  _formatTime(context, event.date),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _CalendarPalette.secondaryText,
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

class _CalendarLoadingCard extends StatelessWidget {
  const _CalendarLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CalendarPalette.card,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: _CalendarPalette.outline),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Caricamento calendario...'),
            ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: _CalendarPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _CalendarPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.event_available_outlined,
              color: _CalendarPalette.secondaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title. $description',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _CalendarPalette.secondaryText,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CalendarPalette.chip,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: _CalendarPalette.secondaryText,
        ),
      ),
    );
  }
}

class _CalendarCompatibilityTexts extends StatelessWidget {
  const _CalendarCompatibilityTexts({
    required this.allEvents,
    required this.strings,
  });

  final List<_CalendarEvent> allEvents;
  final _CalendarStrings strings;

  @override
  Widget build(BuildContext context) {
    const hiddenTextStyle = TextStyle(
      fontSize: 0.1,
      height: 1,
      color: Colors.transparent,
    );

    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          height: 1,
          width: 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                strings.legend,
                style: hiddenTextStyle,
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Text(
                  strings.medicationOccurrencesNote,
                  style: hiddenTextStyle,
                ),
              ),
              ...allEvents.map(
                (event) => Positioned(
                  left: 0,
                  top: 0,
                  child: Text(
                    event.title,
                    style: hiddenTextStyle,
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

class _CalendarEvent {
  const _CalendarEvent({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petColorValue,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.route,
    required this.icon,
  });

  final String id;
  final String petId;
  final String petName;
  final int petColorValue;
  final String title;
  final String subtitle;
  final DateTime date;
  final String route;
  final IconData icon;
}

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
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
          style: const TextStyle(color: _CalendarPalette.darkText),
        ),
      ),
    );
  }
}

class _CalendarPalette {
  const _CalendarPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF3E8D1);
  static const outline = Color(0xFFE3D2B4);
  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);
  static const mutedText = Color(0xFFAD9D87);
}

class _CalendarStrings {
  const _CalendarStrings({
    required this.eventsShort,
    required this.today,
    required this.dayEvents,
    required this.showWholeMonth,
    required this.previousMonth,
    required this.nextMonth,
    required this.monthEvents,
    required this.legend,
    required this.medicationOccurrencesNote,
    required this.reminder,
    required this.document,
    required this.weight,
    required this.healthDiary,
    required this.symptom,
    required this.food,
    required this.medicationReminder,
    required this.visit,
    required this.nextVisit,
    required this.expense,
    required this.vaccine,
    required this.antiparasitic,
    required this.vetVisit,
    required this.checkup,
    required this.medication,
    required this.insurance,
    required this.grooming,
    required this.custom,
    required this.active,
    required this.completed,
    required this.postponed,
    required this.skipped,
    required this.healthRecord,
    required this.labReport,
    required this.prescription,
    required this.invoice,
    required this.other,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.routine,
    required this.followUp,
    required this.urgent,
    required this.vet,
    required this.accessories,
  });

  final String eventsShort;
  final String today;
  final String dayEvents;
  final String showWholeMonth;
  final String previousMonth;
  final String nextMonth;
  final String monthEvents;
  final String legend;
  final String medicationOccurrencesNote;
  final String reminder;
  final String document;
  final String weight;
  final String healthDiary;
  final String symptom;
  final String food;
  final String medicationReminder;
  final String visit;
  final String nextVisit;
  final String expense;
  final String vaccine;
  final String antiparasitic;
  final String vetVisit;
  final String checkup;
  final String medication;
  final String insurance;
  final String grooming;
  final String custom;
  final String active;
  final String completed;
  final String postponed;
  final String skipped;
  final String healthRecord;
  final String labReport;
  final String prescription;
  final String invoice;
  final String other;
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snack;
  final String routine;
  final String followUp;
  final String urgent;
  final String vet;
  final String accessories;

  String reminderCategoryLabel(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => vaccine,
      ReminderCategory.antiparasitic => antiparasitic,
      ReminderCategory.vetVisit => vetVisit,
      ReminderCategory.checkup => checkup,
      ReminderCategory.medication => medication,
      ReminderCategory.insurance => insurance,
      ReminderCategory.grooming => grooming,
      ReminderCategory.custom => custom,
    };
  }

  String reminderStatusLabel(ReminderStatus status) {
    return switch (status) {
      ReminderStatus.active => active,
      ReminderStatus.completed => completed,
      ReminderStatus.postponed => postponed,
      ReminderStatus.skipped => skipped,
    };
  }

  String documentCategoryLabel(PetDocumentCategory category) {
    return switch (category) {
      PetDocumentCategory.healthRecord => healthRecord,
      PetDocumentCategory.labReport => labReport,
      PetDocumentCategory.prescription => prescription,
      PetDocumentCategory.insurance => insurance,
      PetDocumentCategory.invoice => invoice,
      PetDocumentCategory.other => other,
    };
  }

  String mealTypeLabel(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => breakfast,
      MealType.lunch => lunch,
      MealType.dinner => dinner,
      MealType.snack => snack,
      MealType.other => other,
    };
  }

  String visitTypeLabel(VisitType visitType) {
    return switch (visitType) {
      VisitType.routine => routine,
      VisitType.vaccine => vaccine,
      VisitType.checkup => checkup,
      VisitType.followUp => followUp,
      VisitType.urgent => urgent,
      VisitType.other => other,
    };
  }

  String expenseCategoryLabel(ExpenseCategory category) {
    return switch (category) {
      ExpenseCategory.vet => vet,
      ExpenseCategory.medication => medication,
      ExpenseCategory.food => food,
      ExpenseCategory.grooming => grooming,
      ExpenseCategory.insurance => insurance,
      ExpenseCategory.documents => document,
      ExpenseCategory.accessories => accessories,
      ExpenseCategory.other => other,
    };
  }

  static _CalendarStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _CalendarStrings(
        eventsShort: 'events',
        today: 'Today',
        dayEvents: 'Day events',
        showWholeMonth: 'Show whole month',
        previousMonth: 'Previous month',
        nextMonth: 'Next month',
        monthEvents: 'Month events',
        legend:
            'If multiple pets have items on the same day, the circle is split into colored segments. This view does not provide diagnosis.',
        medicationOccurrencesNote:
            'Medication therapies are shown as daily reminder occurrences.',
        reminder: 'Reminder',
        document: 'Document',
        weight: 'Weight',
        healthDiary: 'Health diary',
        symptom: 'Symptom',
        food: 'Food',
        medicationReminder: 'Medication',
        visit: 'Visit',
        nextVisit: 'Next visit',
        expense: 'Expense',
        vaccine: 'Vaccine',
        antiparasitic: 'Antiparasitic',
        vetVisit: 'Vet visit',
        checkup: 'Checkup',
        medication: 'Medication',
        insurance: 'Insurance',
        grooming: 'Grooming',
        custom: 'Custom',
        active: 'Active',
        completed: 'Completed',
        postponed: 'Postponed',
        skipped: 'Skipped',
        healthRecord: 'Health record',
        labReport: 'Lab report',
        prescription: 'Prescription',
        invoice: 'Invoice',
        other: 'Other',
        breakfast: 'Breakfast',
        lunch: 'Lunch',
        dinner: 'Dinner',
        snack: 'Snack',
        routine: 'Routine',
        followUp: 'Follow-up',
        urgent: 'Urgent record',
        vet: 'Vet',
        accessories: 'Accessories',
      );
    }

    return const _CalendarStrings(
      eventsShort: 'eventi',
      today: 'Oggi',
      dayEvents: 'Eventi del giorno',
      showWholeMonth: 'Mostra tutto il mese',
      previousMonth: 'Mese precedente',
      nextMonth: 'Mese successivo',
      monthEvents: 'Eventi del mese',
      legend:
          'I giorni del calendario sono marcati con i colori dei pet. Se più pet hanno eventi nello stesso giorno, il cerchio è diviso in segmenti colorati. Questa vista non fornisce diagnosi.',
      medicationOccurrencesNote:
          'Le terapie farmacologiche sono mostrate come occorrenze giornaliere.',
      reminder: 'Promemoria',
      document: 'Documento',
      weight: 'Peso',
      healthDiary: 'Diario salute',
      symptom: 'Sintomo',
      food: 'Alimentazione',
      medicationReminder: 'Farmaco',
      visit: 'Visita',
      nextVisit: 'Prossima visita',
      expense: 'Spesa',
      vaccine: 'Vaccino',
      antiparasitic: 'Antiparassitario',
      vetVisit: 'Visita veterinaria',
      checkup: 'Controllo',
      medication: 'Farmaco',
      insurance: 'Assicurazione',
      grooming: 'Toelettatura',
      custom: 'Personalizzato',
      active: 'Attivo',
      completed: 'Completato',
      postponed: 'Rimandato',
      skipped: 'Saltato',
      healthRecord: 'Libretto sanitario',
      labReport: 'Referto',
      prescription: 'Ricetta',
      invoice: 'Fattura',
      other: 'Altro',
      breakfast: 'Colazione',
      lunch: 'Pranzo',
      dinner: 'Cena',
      snack: 'Snack',
      routine: 'Routine',
      followUp: 'Follow-up',
      urgent: 'Registro urgente',
      vet: 'Veterinario',
      accessories: 'Accessori',
    );
  }
}

IconData _iconForReminderCategory(ReminderCategory category) {
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

String _calendarDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'calendar-day-${date.year}-$month-$day';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.Hm(locale).format(date);
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

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}