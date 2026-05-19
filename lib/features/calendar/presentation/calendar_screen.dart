import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  DateTime? _selectedDate;

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

          final events = _buildCalendarEvents(
            strings: strings,
            activePets: activePets,
            reminders: remindersState.valueOrNull ?? const <Reminder>[],
            documents: documentsState.valueOrNull ?? const <PetDocument>[],
            weightEntries: weightState.valueOrNull ?? const <WeightEntry>[],
            healthEntries: healthState.valueOrNull ?? const <HealthEntry>[],
            foodEntries: foodState.valueOrNull ?? const <FoodEntry>[],
            medicationEntries:
                medicationsState.valueOrNull ?? const <MedicationEntry>[],
            visitEntries: visitsState.valueOrNull ?? const <VisitEntry>[],
            expenseEntries: expensesState.valueOrNull ?? const <ExpenseEntry>[],
          );

          final filteredEvents = _filterEventsByPet(events);
          final eventsByDay = _eventsByDay(filteredEvents);
          final monthEvents = _eventsForMonth(filteredEvents, _focusedMonth);
          final visibleEvents = _selectedDate == null
              ? monthEvents
              : _eventsForDay(filteredEvents, _selectedDate!);

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
                    _selectedDate = null;
                  });
                },
              ),
              _CalendarLegendCard(strings: strings),
              _CalendarMonthCard(
                focusedMonth: _focusedMonth,
                selectedDate: _selectedDate,
                eventsByDay: eventsByDay,
                strings: strings,
                onPreviousMonth: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                    _selectedDate = null;
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                    _selectedDate = null;
                  });
                },
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = _dateOnly(date);
                    _focusedMonth = DateTime(date.year, date.month);
                  });
                },
              ),
              if (_hasAnyLoadingState(
                remindersState,
                documentsState,
                weightState,
                healthState,
                foodState,
                medicationsState,
                visitsState,
                expensesState,
              ))
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              _CalendarListHeader(
                strings: strings,
                selectedDate: _selectedDate,
                focusedMonth: _focusedMonth,
                eventCount: visibleEvents.length,
                onClearSelectedDate: _selectedDate == null
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
              ),
              if (visibleEvents.isEmpty)
                _EmptyCalendarCard(
                  title: l10n.calendarEmptyTitle,
                  description: l10n.calendarEmptyDescription,
                )
              else
                ...visibleEvents.map(
                  (event) => _CalendarEventCard(
                    event: event,
                    onTap: () => context.push(event.route),
                  ),
                ),
            ],
          );
        },
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

    return map;
  }

  List<_CalendarEvent> _eventsForMonth(
    List<_CalendarEvent> events,
    DateTime focusedMonth,
  ) {
    return events
        .where(
          (event) =>
              event.date.year == focusedMonth.year &&
              event.date.month == focusedMonth.month,
        )
        .toList(growable: false);
  }

  List<_CalendarEvent> _eventsForDay(
    List<_CalendarEvent> events,
    DateTime selectedDate,
  ) {
    final selectedDay = _dateOnly(selectedDate);

    return events
        .where((event) => _dateOnly(event.date) == selectedDay)
        .toList(growable: false);
  }

  List<_CalendarEvent> _buildCalendarEvents({
    required _CalendarStrings strings,
    required List<Pet> activePets,
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
              '${strings.reminder} · ${strings.reminderCategoryLabel(reminder.category)} · ${strings.reminderStatusLabel(reminder.status)}',
          date: reminder.scheduledAt,
          route: '/pets/${pet.id}/reminders',
          icon: Icons.notifications_active_outlined,
          kind: _CalendarEventKind.reminder,
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
          subtitle:
              '${strings.document} · ${strings.documentCategoryLabel(document.category)}',
          date: document.createdAt,
          route: '/pets/${pet.id}/documents',
          icon: Icons.folder_outlined,
          kind: _CalendarEventKind.document,
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
          title: '${strings.weight}: ${entry.weightKg.toStringAsFixed(1)} kg',
          subtitle: strings.weightEntry,
          date: entry.recordedAt,
          route: '/pets/${pet.id}/weight',
          icon: Icons.monitor_weight_outlined,
          kind: _CalendarEventKind.weight,
        ),
      );
    }

    for (final entry in healthEntries) {
      final pet = petById[entry.petId];

      if (pet == null) {
        continue;
      }

      final isSymptom = entry.type == HealthEntryType.symptom;

      events.add(
        _CalendarEvent(
          id: 'health-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.title,
          subtitle: isSymptom
              ? '${strings.symptom} · ${strings.symptomIntensityLabel(entry.symptomIntensity)}'
              : strings.healthDiary,
          date: entry.recordedAt,
          route: isSymptom
              ? '/pets/${pet.id}/symptoms'
              : '/pets/${pet.id}/health-diary',
          icon: isSymptom ? Icons.visibility_outlined : Icons.edit_note_outlined,
          kind:
              isSymptom ? _CalendarEventKind.symptom : _CalendarEventKind.diary,
        ),
      );
    }

    for (final entry in foodEntries) {
      final pet = petById[entry.petId];

      if (pet == null) {
        continue;
      }

      final quantity = entry.quantity == null || entry.quantity!.trim().isEmpty
          ? ''
          : ' · ${entry.quantity!}';

      events.add(
        _CalendarEvent(
          id: 'food-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.foodName,
          subtitle:
              '${strings.food} · ${strings.mealTypeLabel(entry.mealType)}$quantity',
          date: entry.recordedAt,
          route: '/pets/${pet.id}/food',
          icon: Icons.restaurant_outlined,
          kind: _CalendarEventKind.food,
        ),
      );
    }

    for (final entry in medicationEntries) {
      final pet = petById[entry.petId];

      if (pet == null) {
        continue;
      }

      events.add(
        _CalendarEvent(
          id: 'medication-start-${entry.id}',
          petId: pet.id,
          petName: pet.name,
          petColorValue: pet.colorValue,
          title: entry.name,
          subtitle:
              '${strings.medicationStart} · ${strings.medicationStatusLabel(entry.status)}',
          date: entry.startDate,
          route: '/pets/${pet.id}/medications',
          icon: Icons.medication_outlined,
          kind: _CalendarEventKind.medication,
        ),
      );

      if (entry.endDate != null) {
        events.add(
          _CalendarEvent(
            id: 'medication-end-${entry.id}',
            petId: pet.id,
            petName: pet.name,
            petColorValue: pet.colorValue,
            title: entry.name,
            subtitle: strings.medicationEnd,
            date: entry.endDate!,
            route: '/pets/${pet.id}/medications',
            icon: Icons.medication_liquid_outlined,
            kind: _CalendarEventKind.medication,
          ),
        );
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
          subtitle:
              '${strings.visit} · ${strings.visitTypeLabel(entry.visitType)}',
          date: entry.visitDate,
          route: '/pets/${pet.id}/visits',
          icon: Icons.local_hospital_outlined,
          kind: _CalendarEventKind.visit,
        ),
      );

      if (entry.nextVisitDate != null) {
        events.add(
          _CalendarEvent(
            id: 'visit-next-${entry.id}',
            petId: pet.id,
            petName: pet.name,
            petColorValue: pet.colorValue,
            title: '${strings.nextVisit}: ${entry.reason}',
            subtitle: strings.nextVisit,
            date: entry.nextVisitDate!,
            route: '/pets/${pet.id}/visits',
            icon: Icons.event_available_outlined,
            kind: _CalendarEventKind.visit,
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
          subtitle:
              '${strings.expense} · ${strings.expenseCategoryLabel(entry.category)} · ${entry.amount.toStringAsFixed(2)} ${entry.currency}',
          date: entry.expenseDate,
          route: '/pets/${pet.id}/expenses',
          icon: Icons.receipt_long_outlined,
          kind: _CalendarEventKind.expense,
        ),
      );
    }

    events.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.title.compareTo(b.title);
    });

    return events;
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: Color(pet.colorValue),
                    ),
                    const SizedBox(width: 8),
                    Text(pet.name),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CalendarLegendCard extends StatelessWidget {
  const _CalendarLegendCard({
    required this.strings,
  });

  final _CalendarStrings strings;

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
              child: Text(strings.legend),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarMonthCard extends StatelessWidget {
  const _CalendarMonthCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.eventsByDay,
    required this.strings,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Map<DateTime, List<_CalendarEvent>> eventsByDay;
  final _CalendarStrings strings;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(locale).format(focusedMonth);
    final weekdayLabels = _weekdayLabels(locale);
    final dates = _visibleDates(focusedMonth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: strings.previousMonth,
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: strings.nextMonth,
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: weekdayLabels
                  .map(
                    (label) => Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.08,
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
        ),
      ),
    );
  }

  List<String> _weekdayLabels(String locale) {
    final monday = DateTime(2024, 1, 1);

    return List.generate(7, (index) {
      return DateFormat.E(locale).format(monday.add(Duration(days: index)));
    });
  }

  List<DateTime> _visibleDates(DateTime focusedMonth) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month);
    final daysBefore = firstDayOfMonth.weekday - DateTime.monday;
    final firstVisibleDay = firstDayOfMonth.subtract(Duration(days: daysBefore));

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
    final petColorValues = _petColorValues(dayEvents);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Center(
        child: CustomPaint(
          painter: _DayPetRingPainter(
            petColorValues: petColorValues,
            isSelected: isSelected,
            selectedColor: Theme.of(context).colorScheme.primary,
          ),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                  : isToday
                      ? Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.55)
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected || isToday
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: isCurrentMonth
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.34),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  List<int> _petColorValues(List<_CalendarEvent> events) {
    final colorValues = <int>[];

    for (final event in events) {
      if (!colorValues.contains(event.petColorValue)) {
        colorValues.add(event.petColorValue);
      }
    }

    return colorValues;
  }
}

class _DayPetRingPainter extends CustomPainter {
  const _DayPetRingPainter({
    required this.petColorValues,
    required this.isSelected,
    required this.selectedColor,
  });

  final List<int> petColorValues;
  final bool isSelected;
  final Color selectedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (petColorValues.isEmpty) {
      if (!isSelected) {
        return;
      }

      _drawFullRing(canvas, size, selectedColor, 2.5);
      return;
    }

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);

    if (petColorValues.length == 1) {
      _drawFullRing(canvas, size, Color(petColorValues.first), 4);
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final segmentSweep = (math.pi * 2) / petColorValues.length;
    const gap = 0.08;

    for (var index = 0; index < petColorValues.length; index++) {
      paint.color = Color(petColorValues[index]);
      final startAngle = -math.pi / 2 + (segmentSweep * index) + gap;
      final sweepAngle = segmentSweep - (gap * 2);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawFullRing(
    Canvas canvas,
    Size size,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.shortestSide / 2) - 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DayPetRingPainter oldDelegate) {
    return oldDelegate.petColorValues != petColorValues ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.selectedColor != selectedColor;
  }
}

class _CalendarListHeader extends StatelessWidget {
  const _CalendarListHeader({
    required this.strings,
    required this.selectedDate,
    required this.focusedMonth,
    required this.eventCount,
    required this.onClearSelectedDate,
  });

  final _CalendarStrings strings;
  final DateTime? selectedDate;
  final DateTime focusedMonth;
  final int eventCount;
  final VoidCallback? onClearSelectedDate;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = selectedDate == null
        ? '${strings.monthEvents}: ${DateFormat.yMMMM(locale).format(focusedMonth)}'
        : '${strings.dayEvents}: ${DateFormat.yMMMd(locale).format(selectedDate!)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title · $eventCount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          if (onClearSelectedDate != null)
            TextButton(
              onPressed: onClearSelectedDate,
              child: Text(strings.showWholeMonth),
            ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.event,
    required this.onTap,
  });

  final _CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(context, event.date);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: Color(event.petColorValue),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Color(event.petColorValue).withValues(alpha: 0.16),
                        child: Icon(
                          event.icon,
                          color: Color(event.petColorValue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(event.petName),
                            Text(event.subtitle),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
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

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return dateFormat.format(date);
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

enum _CalendarEventKind {
  reminder,
  document,
  weight,
  diary,
  symptom,
  food,
  medication,
  visit,
  expense,
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
    required this.kind,
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
  final _CalendarEventKind kind;
}

class _CalendarStrings {
  const _CalendarStrings({
    required this.legend,
    required this.previousMonth,
    required this.nextMonth,
    required this.monthEvents,
    required this.dayEvents,
    required this.showWholeMonth,
    required this.reminder,
    required this.document,
    required this.weight,
    required this.weightEntry,
    required this.healthDiary,
    required this.symptom,
    required this.food,
    required this.medicationStart,
    required this.medicationEnd,
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
    required this.mild,
    required this.moderate,
    required this.high,
    required this.unknown,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.routine,
    required this.followUp,
    required this.urgent,
    required this.cancelled,
    required this.paused,
    required this.vet,
    required this.accessories,
  });

  final String legend;
  final String previousMonth;
  final String nextMonth;
  final String monthEvents;
  final String dayEvents;
  final String showWholeMonth;
  final String reminder;
  final String document;
  final String weight;
  final String weightEntry;
  final String healthDiary;
  final String symptom;
  final String food;
  final String medicationStart;
  final String medicationEnd;
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
  final String mild;
  final String moderate;
  final String high;
  final String unknown;
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snack;
  final String routine;
  final String followUp;
  final String urgent;
  final String cancelled;
  final String paused;
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

  String symptomIntensityLabel(SymptomIntensity? intensity) {
    return switch (intensity) {
      SymptomIntensity.mild => mild,
      SymptomIntensity.moderate => moderate,
      SymptomIntensity.high => high,
      null => unknown,
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

  String medicationStatusLabel(MedicationStatus status) {
    return switch (status) {
      MedicationStatus.active => active,
      MedicationStatus.completed => completed,
      MedicationStatus.paused => paused,
    };
  }

  String visitTypeLabel(VisitType type) {
    return switch (type) {
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
        legend:
            'Calendar days are marked with pet colors. If multiple pets have items on the same day, the circle is split into colored segments. This is an organizational view only and does not provide diagnosis, triage or medical advice.',
        previousMonth: 'Previous month',
        nextMonth: 'Next month',
        monthEvents: 'Month events',
        dayEvents: 'Day events',
        showWholeMonth: 'Show whole month',
        reminder: 'Reminder',
        document: 'Document',
        weight: 'Weight',
        weightEntry: 'Weight entry',
        healthDiary: 'Health diary',
        symptom: 'Symptom',
        food: 'Food',
        medicationStart: 'Medication start',
        medicationEnd: 'Medication end',
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
        mild: 'Mild',
        moderate: 'Moderate',
        high: 'High',
        unknown: 'Unknown',
        breakfast: 'Breakfast',
        lunch: 'Lunch',
        dinner: 'Dinner',
        snack: 'Snack',
        routine: 'Routine',
        followUp: 'Follow-up',
        urgent: 'Urgent record',
        cancelled: 'Cancelled',
        paused: 'Paused',
        vet: 'Vet',
        accessories: 'Accessories',
      );
    }

    return const _CalendarStrings(
      legend:
          'I giorni del calendario sono marcati con i colori dei pet. Se più animali hanno elementi nello stesso giorno, il cerchio viene diviso in segmenti colorati. Questa vista è solo organizzativa e non fornisce diagnosi, triage o consigli medici.',
      previousMonth: 'Mese precedente',
      nextMonth: 'Mese successivo',
      monthEvents: 'Eventi del mese',
      dayEvents: 'Eventi del giorno',
      showWholeMonth: 'Mostra tutto il mese',
      reminder: 'Promemoria',
      document: 'Documento',
      weight: 'Peso',
      weightEntry: 'Registrazione peso',
      healthDiary: 'Diario salute',
      symptom: 'Sintomo',
      food: 'Alimentazione',
      medicationStart: 'Inizio farmaco',
      medicationEnd: 'Fine farmaco',
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
      healthRecord: 'Cartella clinica',
      labReport: 'Referto',
      prescription: 'Prescrizione',
      invoice: 'Fattura',
      other: 'Altro',
      mild: 'Lieve',
      moderate: 'Moderato',
      high: 'Alto',
      unknown: 'Non specificato',
      breakfast: 'Colazione',
      lunch: 'Pranzo',
      dinner: 'Cena',
      snack: 'Snack',
      routine: 'Routine',
      followUp: 'Follow-up',
      urgent: 'Registro urgente',
      cancelled: 'Annullato',
      paused: 'In pausa',
      vet: 'Veterinario',
      accessories: 'Accessori',
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _calendarDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return 'calendar-day-${date.year}-$month-$day';
}