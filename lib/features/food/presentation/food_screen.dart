import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../pets/application/pet_controller.dart';
import '../../pets/domain/pet.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/domain/reminder.dart';
import '../application/food_controller.dart';
import '../domain/food_entry.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsState = ref.watch(petControllerProvider);
    final foodState = ref.watch(foodControllerProvider);

    return Scaffold(
      backgroundColor: _FoodPalette.background,
      body: SafeArea(
        child: petsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (pets) {
            final pet = _findPet(pets, petId);

            if (pet == null) {
              return const _ErrorState(error: 'Pet non trovato');
            }

            return foodState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(error: error),
              data: (entries) {
                final entry = _entryForPet(entries, pet);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  children: [
                    _Header(
                      petName: pet.name,
                      onBack: () => context.go('/pets/${pet.id}'),
                      onSettings: () => _openPlanEditor(
                        context: context,
                        ref: ref,
                        pet: pet,
                        entry: entry,
                        createNewPlan: false,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _StockSummaryCard(
                      entry: entry,
                      onTap: () => _openStockManager(
                        context: context,
                        ref: ref,
                        entry: entry,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'Piano alimentare',
                      actionLabel: 'Nuovo piano',
                      onAction: () => _openPlanEditor(
                        context: context,
                        ref: ref,
                        pet: pet,
                        entry: entry,
                        createNewPlan: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FeedingPlanCard(
                      entry: entry,
                      onEdit: () => _openPlanEditor(
                        context: context,
                        ref: ref,
                        pet: pet,
                        entry: entry,
                        createNewPlan: false,
                      ),
                      onArchive: () => _archiveCurrentPlan(
                        context: context,
                        ref: ref,
                        entry: entry,
                      ),
                      onToggleSync: () => _togglePlanSync(
                        context: context,
                        ref: ref,
                        pet: pet,
                        entry: entry,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PastPlansCard(
                      plans: entry.pastPlans,
                      onTap: () => _openPastPlans(
                        context: context,
                        ref: ref,
                        pet: pet,
                        entry: entry,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SnackCard(plan: entry.currentPlan),
                    const SizedBox(height: 16),
                    const _DisclaimerCard(),
                  ],
                );
              },
            );
          },
        ),
      ),
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

  FoodEntry _entryForPet(List<FoodEntry> entries, Pet pet) {
    for (final entry in entries) {
      if (entry.petId == pet.id) {
        return entry;
      }
    }

    final now = DateTime.now();

    return FoodEntry(
      id: 'food-profile-${pet.id}',
      petId: pet.id,
      petName: pet.name,
      mealType: MealType.other,
      foodName: 'Piano alimentare',
      recordedAt: now,
      createdAt: now,
      currentPlanId: 'default-plan-${pet.id}',
      stocks: [
        FoodStock(
          id: 'default-stock-${pet.id}',
          name: 'Royal Canin Sterilised',
          unit: FoodStockUnit.kg,
          amount: 4,
          createdAt: now,
        ),
      ],
      plans: [
        FeedingPlan(
          id: 'default-plan-${pet.id}',
          title: 'Royal Canin Sterilised',
          description: 'Crocchette + umido (split 2 pasti)',
          snacks: 'Max 5% del fabbisogno · ~3 Dreamies/giorno',
          startedAt: now,
          createdAt: now,
          meals: const [
            FeedingMeal(
              id: 'default-meal-1',
              name: 'Crocchette',
              quantityLabel: '25 g',
              grams: 25,
              hour: 7,
              minute: 30,
            ),
            FeedingMeal(
              id: 'default-meal-2',
              name: 'Umido + crocc.',
              quantityLabel: '30 g + 5 g',
              grams: 35,
              hour: 19,
              minute: 0,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveEntry({
    required WidgetRef ref,
    required FoodEntry entry,
  }) async {
    await ref.read(foodControllerProvider.notifier).upsertEntry(
          entry.copyWith(updatedAt: DateTime.now()),
        );
  }

  Future<void> _deletePlanReminders({
    required WidgetRef ref,
    required FeedingPlan plan,
  }) async {
    final remindersState = ref.read(reminderControllerProvider);
    final existingReminders = remindersState.valueOrNull ?? const <Reminder>[];

    final reminderIds = <String>{
      ...plan.automaticReminderIds,
      ...existingReminders
          .where(
            (reminder) =>
                reminder.id.startsWith('food-${plan.id}-') ||
                (reminder.notes?.contains('Piano alimentare: ${plan.title}') ??
                    false),
          )
          .map((reminder) => reminder.id),
    };

    if (reminderIds.isEmpty) {
      return;
    }

    await ref
        .read(reminderControllerProvider.notifier)
        .deleteReminders(reminderIds.toList(growable: false));
  }

  Future<void> _openStockManager({
    required BuildContext context,
    required WidgetRef ref,
    required FoodEntry entry,
  }) async {
    final updatedStocks = await showModalBottomSheet<List<FoodStock>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StockManagerSheet(
          stocks: entry.stocks,
          currentPlan: entry.currentPlan,
        );
      },
    );

    if (updatedStocks == null || !context.mounted) {
      return;
    }

    await _saveEntry(
      ref: ref,
      entry: entry.copyWith(
        stocks: updatedStocks,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _openPlanEditor({
    required BuildContext context,
    required WidgetRef ref,
    required Pet pet,
    required FoodEntry entry,
    required bool createNewPlan,
  }) async {
    final currentPlan = entry.currentPlan;

    final result = await showModalBottomSheet<_PlanEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PlanEditorSheet(
          plan: createNewPlan ? null : currentPlan,
          createNewPlan: createNewPlan,
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    switch (result.action) {
      case _PlanEditorAction.save:
        await _savePlanEditorResult(
          context: context,
          ref: ref,
          pet: pet,
          entry: entry,
          plan: result.plan!,
          createNewPlan: createNewPlan,
        );
      case _PlanEditorAction.delete:
        if (currentPlan == null) {
          return;
        }

        await _deletePlanReminders(
          ref: ref,
          plan: currentPlan,
        );

        final remainingPlans = entry.plans
            .where((plan) => plan.id != currentPlan.id)
            .toList(growable: false);

        await _saveEntry(
          ref: ref,
          entry: entry.copyWith(
            plans: remainingPlans,
            clearCurrentPlanId: true,
            updatedAt: DateTime.now(),
          ),
        );
    }
  }

  Future<void> _savePlanEditorResult({
    required BuildContext context,
    required WidgetRef ref,
    required Pet pet,
    required FoodEntry entry,
    required FeedingPlan plan,
    required bool createNewPlan,
  }) async {
    final now = DateTime.now();
    final previousCurrentPlan = entry.currentPlan;
    final reminderController = ref.read(reminderControllerProvider.notifier);

    var updatedPlans = [...entry.plans];

    if (previousCurrentPlan != null) {
      await _deletePlanReminders(
        ref: ref,
        plan: previousCurrentPlan,
      );
    }

    if (createNewPlan && previousCurrentPlan != null) {
      updatedPlans = updatedPlans.map((existingPlan) {
        if (existingPlan.id == previousCurrentPlan.id) {
          return existingPlan.copyWith(
            endedAt: now,
            addToReminders: false,
            automaticReminderIds: const [],
            updatedAt: now,
          );
        }

        return existingPlan;
      }).toList(growable: false);
    }

    var savedPlan = plan.copyWith(
      updatedAt: now,
      clearEndedAt: true,
    );

    if (savedPlan.addToReminders) {
      final reminders = _buildPlanReminders(
        pet: pet,
        plan: savedPlan,
      );

      savedPlan = savedPlan.copyWith(
        automaticReminderIds:
            reminders.map((reminder) => reminder.id).toList(growable: false),
      );

      for (final reminder in reminders) {
        await reminderController.addReminder(reminder);
      }
    } else {
      savedPlan = savedPlan.copyWith(
        automaticReminderIds: const [],
      );
    }

    var didReplace = false;

    updatedPlans = updatedPlans.map((existingPlan) {
      if (existingPlan.id == savedPlan.id) {
        didReplace = true;
        return savedPlan;
      }

      return existingPlan;
    }).toList(growable: false);

    if (!didReplace) {
      updatedPlans = [savedPlan, ...updatedPlans];
    }

    await _saveEntry(
      ref: ref,
      entry: entry.copyWith(
        plans: updatedPlans,
        currentPlanId: savedPlan.id,
        foodName: savedPlan.title,
        notes: savedPlan.snacks,
        updatedAt: now,
      ),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          createNewPlan
              ? 'Nuovo piano alimentare salvato'
              : 'Piano alimentare aggiornato',
        ),
      ),
    );
  }

  Future<void> _togglePlanSync({
    required BuildContext context,
    required WidgetRef ref,
    required Pet pet,
    required FoodEntry entry,
  }) async {
    final currentPlan = entry.currentPlan;

    if (currentPlan == null) {
      return;
    }

    final reminderController = ref.read(reminderControllerProvider.notifier);

    await _deletePlanReminders(
      ref: ref,
      plan: currentPlan,
    );

    var updatedPlan = currentPlan.copyWith(
      addToReminders: !currentPlan.addToReminders,
      automaticReminderIds: const [],
      updatedAt: DateTime.now(),
    );

    if (updatedPlan.addToReminders) {
      final reminders = _buildPlanReminders(
        pet: pet,
        plan: updatedPlan,
      );

      updatedPlan = updatedPlan.copyWith(
        automaticReminderIds:
            reminders.map((reminder) => reminder.id).toList(growable: false),
      );

      for (final reminder in reminders) {
        await reminderController.addReminder(reminder);
      }
    }

    final updatedPlans = entry.plans.map((plan) {
      if (plan.id == updatedPlan.id) {
        return updatedPlan;
      }

      return plan;
    }).toList(growable: false);

    await _saveEntry(
      ref: ref,
      entry: entry.copyWith(
        plans: updatedPlans,
        currentPlanId: updatedPlan.id,
        updatedAt: DateTime.now(),
      ),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedPlan.addToReminders
              ? 'Piano aggiunto a calendario e promemoria'
              : 'Piano rimosso da calendario e promemoria',
        ),
      ),
    );
  }

  Future<void> _archiveCurrentPlan({
    required BuildContext context,
    required WidgetRef ref,
    required FoodEntry entry,
  }) async {
    final currentPlan = entry.currentPlan;

    if (currentPlan == null) {
      return;
    }

    await _deletePlanReminders(
      ref: ref,
      plan: currentPlan,
    );

    final now = DateTime.now();

    final updatedPlans = entry.plans.map((plan) {
      if (plan.id == currentPlan.id) {
        return plan.copyWith(
          endedAt: now,
          addToReminders: false,
          automaticReminderIds: const [],
          updatedAt: now,
        );
      }

      return plan;
    }).toList(growable: false);

    await _saveEntry(
      ref: ref,
      entry: entry.copyWith(
        plans: updatedPlans,
        clearCurrentPlanId: true,
        updatedAt: now,
      ),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Piano alimentare archiviato'),
      ),
    );
  }

  Future<void> _openPastPlans({
    required BuildContext context,
    required WidgetRef ref,
    required Pet pet,
    required FoodEntry entry,
  }) async {
    final selectedPlan = await showModalBottomSheet<FeedingPlan>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PastPlansSheet(plans: entry.pastPlans);
      },
    );

    if (selectedPlan == null || !context.mounted) {
      return;
    }

    final currentPlan = entry.currentPlan;

    if (currentPlan != null) {
      await _deletePlanReminders(
        ref: ref,
        plan: currentPlan,
      );
    }

    final now = DateTime.now();

    final updatedPlans = entry.plans.map((plan) {
      if (currentPlan != null && plan.id == currentPlan.id) {
        return plan.copyWith(
          endedAt: now,
          addToReminders: false,
          automaticReminderIds: const [],
          updatedAt: now,
        );
      }

      if (plan.id == selectedPlan.id) {
        return plan.copyWith(
          clearEndedAt: true,
          addToReminders: false,
          automaticReminderIds: const [],
          updatedAt: now,
        );
      }

      return plan;
    }).toList(growable: false);

    await _saveEntry(
      ref: ref,
      entry: entry.copyWith(
        plans: updatedPlans,
        currentPlanId: selectedPlan.id,
        updatedAt: now,
      ),
    );
  }

  List<Reminder> _buildPlanReminders({
    required Pet pet,
    required FeedingPlan plan,
  }) {
    final reminders = <Reminder>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var dayOffset = 0; dayOffset < 30; dayOffset++) {
      final day = today.add(Duration(days: dayOffset));

      for (final meal in plan.meals) {
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          meal.hour,
          meal.minute,
        );

        if (!scheduledAt.isAfter(now)) {
          continue;
        }

        final dateKey =
            '${scheduledAt.year}${scheduledAt.month.toString().padLeft(2, '0')}${scheduledAt.day.toString().padLeft(2, '0')}';
        final timeKey =
            '${scheduledAt.hour.toString().padLeft(2, '0')}${scheduledAt.minute.toString().padLeft(2, '0')}';

        reminders.add(
          Reminder(
            id: 'food-${plan.id}-${meal.id}-$dateKey-$timeKey',
            petId: pet.id,
            petName: pet.name,
            category: ReminderCategory.custom,
            title: 'Pasto: ${meal.name}',
            scheduledAt: scheduledAt,
            status: ReminderStatus.active,
            createdAt: now,
            notes: 'Piano alimentare: ${plan.title}'
                '${meal.quantityLabel == null ? '' : '\nQuantità: ${meal.quantityLabel}'}',
          ),
        );
      }
    }

    return reminders;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.petName,
    required this.onBack,
    required this.onSettings,
  });

  final String petName;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.chevron_left_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alimentazione',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                        color: _FoodPalette.darkText,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  petName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _FoodPalette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.settings_outlined,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _FoodPalette.chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 20,
            color: _FoodPalette.darkText,
          ),
        ),
      ),
    );
  }
}

class _StockSummaryCard extends StatelessWidget {
  const _StockSummaryCard({
    required this.entry,
    required this.onTap,
  });

  final FoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plan = entry.currentPlan;
    final stocks = entry.stocks;

    return _FoodCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 82,
            height: 82,
            child: CustomPaint(
              painter: _BowlPainter(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: stocks.isEmpty
                ? const _NoStockContent()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCORTE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _FoodPalette.mutedText,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (var index = 0; index < stocks.length; index++) ...[
                        _StockSummaryLine(
                          stock: stocks[index],
                          plan: plan,
                        ),
                        if (index != stocks.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: _FoodPalette.outline,
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _FoodPalette.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _FoodPalette.outline),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text(
                            'Gestisci',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: _FoodPalette.darkText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static int? calculateRemainingDays({
    required FoodStock stock,
    required FeedingPlan plan,
  }) {
    if (stock.unit == FoodStockUnit.kg) {
      final gramsPerDay = plan.dailyGrams;

      if (gramsPerDay <= 0) {
        return null;
      }

      return math.max(0, ((stock.amount * 1000) / gramsPerDay).floor());
    }

    final cansPerDay = plan.dailyCans;

    if (cansPerDay <= 0) {
      return null;
    }

    return math.max(0, (stock.amount / cansPerDay).floor());
  }

  static String formatStockAmount(FoodStock stock) {
    final amount = stock.amount % 1 == 0
        ? stock.amount.toStringAsFixed(0)
        : stock.amount.toStringAsFixed(1);

    return stock.unit == FoodStockUnit.kg ? '$amount kg' : '$amount lattine';
  }
}

class _NoStockContent extends StatelessWidget {
  const _NoStockContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORTE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _FoodPalette.mutedText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          'Nessuna scorta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _FoodPalette.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          'Aggiungi una o più scorte',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _FoodPalette.purple,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: _FoodPalette.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _FoodPalette.outline),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            child: Text(
              'Aggiungi',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _FoodPalette.darkText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StockSummaryLine extends StatelessWidget {
  const _StockSummaryLine({
    required this.stock,
    required this.plan,
  });

  final FoodStock stock;
  final FeedingPlan? plan;

  @override
  Widget build(BuildContext context) {
    final amountLabel = _StockSummaryCard.formatStockAmount(stock);
    final selectedPlan = plan;
    final days = selectedPlan == null
        ? null
        : _StockSummaryCard.calculateRemainingDays(
            stock: stock,
            plan: selectedPlan,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stock.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _FoodPalette.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          days == null ? amountLabel : '$amountLabel · bastano per ~$days giorni',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _FoodPalette.purple,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _FoodPalette.darkText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _FeedingPlanCard extends StatelessWidget {
  const _FeedingPlanCard({
    required this.entry,
    required this.onEdit,
    required this.onArchive,
    required this.onToggleSync,
  });

  final FoodEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onToggleSync;

  @override
  Widget build(BuildContext context) {
    final plan = entry.currentPlan;

    if (plan == null) {
      return _FoodCard(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              const Icon(
                Icons.restaurant_menu_outlined,
                size: 38,
                color: _FoodPalette.secondaryText,
              ),
              const SizedBox(height: 12),
              Text(
                'Nessun piano alimentare in corso',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _FoodPalette.darkText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tocca “Nuovo piano” per crearne uno oppure apri i piani passati.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _FoodPalette.secondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return _FoodCard(
      onTap: onEdit,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Row(
              children: [
                Expanded(
                  child: _PlanTitle(plan: plan),
                ),
                const SizedBox(width: 8),
                _ArchiveButton(onTap: onArchive),
                const SizedBox(width: 8),
                _SyncButton(
                  enabled: plan.addToReminders,
                  onTap: onToggleSync,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _FoodPalette.outline),
          for (final meal in plan.meals) ...[
            _MealRow(meal: meal),
            if (meal.id != plan.meals.last.id)
              const Divider(height: 1, color: _FoodPalette.outline),
          ],
        ],
      ),
    );
  }
}

class _ArchiveButton extends StatelessWidget {
  const _ArchiveButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Archivia piano alimentare',
      child: Material(
        color: _FoodPalette.chip,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(
              Icons.archive_outlined,
              size: 18,
              color: _FoodPalette.darkText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTitle extends StatelessWidget {
  const _PlanTitle({
    required this.plan,
  });

  final FeedingPlan plan;

  @override
  Widget build(BuildContext context) {
    final grams = plan.dailyGrams;
    final cans = plan.dailyCans;

    final dailyLabel = [
      if (grams > 0) '${_formatNumber(grams)} g/giorno',
      if (cans > 0) '${_formatNumber(cans)} lattine/giorno',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MARCA ATTUALE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _FoodPalette.mutedText,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          plan.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _FoodPalette.darkText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
        ),
        if (plan.description != null && plan.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              [
                plan.description!.trim(),
                if (dailyLabel.isNotEmpty) dailyLabel,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _FoodPalette.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled
          ? 'Rimuovi da calendario e promemoria'
          : 'Aggiungi a calendario e promemoria',
      child: Material(
        color: enabled ? _FoodPalette.darkText : _FoodPalette.chip,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(
              enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: enabled ? Colors.white : _FoodPalette.darkText,
            ),
          ),
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
  });

  final FeedingMeal meal;

  @override
  Widget build(BuildContext context) {
    final time =
        '${meal.hour.toString().padLeft(2, '0')}:${meal.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _FoodPalette.lightPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: _FoodPalette.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _FoodPalette.darkText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (meal.quantityLabel != null &&
                    meal.quantityLabel!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      meal.quantityLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _FoodPalette.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _FoodPalette.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _PastPlansCard extends StatelessWidget {
  const _PastPlansCard({
    required this.plans,
    required this.onTap,
  });

  final List<FeedingPlan> plans;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FoodCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _FoodPalette.chip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: _FoodPalette.darkText,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              plans.isEmpty
                  ? 'Nessun piano alimentare passato'
                  : '${plans.length} piani alimentari passati',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _FoodPalette.darkText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _FoodPalette.secondaryText,
          ),
        ],
      ),
    );
  }
}

class _SnackCard extends StatelessWidget {
  const _SnackCard({
    required this.plan,
  });

  final FeedingPlan? plan;

  @override
  Widget build(BuildContext context) {
    final text = plan?.snacks?.trim().isNotEmpty == true
        ? plan!.snacks!.trim()
        : 'Nessuna indicazione su snack e premi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snack e premi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _FoodPalette.darkText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        _FoodCard(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _FoodPalette.chip,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: _FoodPalette.darkText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _FoodPalette.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _FoodPalette.warningBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _FoodPalette.warningBorder),
      ),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_rounded,
            color: _FoodPalette.warningIcon,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Cambi di dieta e quantità precise vanno concordati con il veterinario, soprattutto in caso di patologie.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _FoodPalette.warningText,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: _FoodPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FoodPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _StockManagerSheet extends StatefulWidget {
  const _StockManagerSheet({
    required this.stocks,
    required this.currentPlan,
  });

  final List<FoodStock> stocks;
  final FeedingPlan? currentPlan;

  @override
  State<_StockManagerSheet> createState() => _StockManagerSheetState();
}

class _StockManagerSheetState extends State<_StockManagerSheet> {
  late List<FoodStock> _stocks;

  @override
  void initState() {
    super.initState();
    _stocks = [...widget.stocks];
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Gestisci scorte',
      child: Column(
        children: [
          if (_stocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Nessuna scorta salvata'),
            )
          else
            for (final stock in _stocks)
              _EditableStockRow(
                stock: stock,
                days: widget.currentPlan == null
                    ? null
                    : _StockSummaryCard.calculateRemainingDays(
                        stock: stock,
                        plan: widget.currentPlan!,
                      ),
                onEdit: () => _editStock(stock),
                onDelete: () {
                  setState(() {
                    _stocks = _stocks
                        .where((item) => item.id != stock.id)
                        .toList(growable: false);
                  });
                },
              ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _editStock(null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Aggiungi scorta'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_stocks),
            child: const Text('Salva scorte'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStock(FoodStock? stock) async {
    final result = await showModalBottomSheet<FoodStock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StockEditorSheet(stock: stock);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = _stocks.indexWhere((item) => item.id == result.id);

      if (index == -1) {
        _stocks = [..._stocks, result];
      } else {
        final updated = [..._stocks];
        updated[index] = result;
        _stocks = updated;
      }
    });
  }
}

class _EditableStockRow extends StatelessWidget {
  const _EditableStockRow({
    required this.stock,
    required this.days,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodStock stock;
  final int? days;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amount = _StockSummaryCard.formatStockAmount(stock);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _FoodPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _FoodPalette.outline),
      ),
      child: ListTile(
        title: Text(stock.name),
        subtitle: Text(days == null ? amount : '$amount · ~$days giorni'),
        trailing: Wrap(
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockEditorSheet extends StatefulWidget {
  const _StockEditorSheet({
    this.stock,
  });

  final FoodStock? stock;

  @override
  State<_StockEditorSheet> createState() => _StockEditorSheetState();
}

class _StockEditorSheetState extends State<_StockEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  FoodStockUnit _unit = FoodStockUnit.kg;

  @override
  void initState() {
    super.initState();

    final stock = widget.stock;

    if (stock != null) {
      _nameController.text = stock.name;
      _amountController.text = _formatNumber(stock.amount);
      _unit = stock.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.stock == null ? 'Nuova scorta' : 'Modifica scorta',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome alimento',
                hintText: 'Es. Royal Canin Sterilised',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Inserisci il nome';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FoodStockUnit>(
              initialValue: _unit,
              decoration: const InputDecoration(
                labelText: 'Unità',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: FoodStockUnit.kg,
                  child: Text('Kg'),
                ),
                DropdownMenuItem(
                  value: FoodStockUnit.cans,
                  child: Text('Lattine'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _unit = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: InputDecoration(
                labelText: _unit == FoodStockUnit.kg
                    ? 'Kg disponibili'
                    : 'Lattine disponibili',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );

                if (parsed == null || parsed < 0) {
                  return 'Inserisci un valore valido';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();

    Navigator.of(context).pop(
      FoodStock(
        id: widget.stock?.id ?? 'stock-${now.microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        unit: _unit,
        amount: double.parse(
          _amountController.text.trim().replaceAll(',', '.'),
        ),
        createdAt: widget.stock?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}

class _PlanEditorSheet extends StatefulWidget {
  const _PlanEditorSheet({
    required this.plan,
    required this.createNewPlan,
  });

  final FeedingPlan? plan;
  final bool createNewPlan;

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _snacksController = TextEditingController();

  late bool _addToReminders;
  late List<FeedingMeal> _meals;

  @override
  void initState() {
    super.initState();

    final plan = widget.plan;

    _titleController.text = plan?.title ?? '';
    _descriptionController.text = plan?.description ?? '';
    _snacksController.text = plan?.snacks ?? '';
    _addToReminders = plan?.addToReminders ?? false;
    _meals = plan?.meals.toList(growable: false) ??
        const [
          FeedingMeal(
            id: 'meal-morning',
            name: 'Crocchette',
            quantityLabel: '25 g',
            grams: 25,
            hour: 7,
            minute: 30,
          ),
          FeedingMeal(
            id: 'meal-evening',
            name: 'Umido + crocc.',
            quantityLabel: '30 g + 5 g',
            grams: 35,
            hour: 19,
            minute: 0,
          ),
        ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _snacksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grams = _meals.fold<double>(
      0,
      (previous, meal) => previous + (meal.grams ?? 0),
    );
    final cans = _meals.fold<double>(
      0,
      (previous, meal) => previous + (meal.cans ?? 0),
    );

    return _SheetShell(
      title: widget.createNewPlan
          ? 'Nuovo piano alimentare'
          : 'Modifica piano alimentare',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Marca / piano',
                hintText: 'Es. Royal Canin Sterilised',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Inserisci il nome del piano';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                hintText: 'Es. Crocchette + umido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _snacksController,
              decoration: const InputDecoration(
                labelText: 'Snack e premi',
                hintText: 'Es. Max 5% del fabbisogno',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _addToReminders,
              onChanged: (value) {
                setState(() {
                  _addToReminders = value;
                });
              },
              title: const Text('Aggiungi a calendario e promemoria'),
              subtitle: const Text(
                'Crea promemoria automatici per i pasti dei prossimi 30 giorni.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pasti · ${_formatNumber(grams)} g/giorno'
                    '${cans > 0 ? ' · ${_formatNumber(cans)} lattine/giorno' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _FoodPalette.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editMeal(null),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Pasto'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final meal in _meals)
              _EditableMealRow(
                meal: meal,
                onEdit: () => _editMeal(meal),
                onDelete: () {
                  setState(() {
                    _meals = _meals
                        .where((item) => item.id != meal.id)
                        .toList(growable: false);
                  });
                },
              ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _save,
              child: Text(widget.createNewPlan ? 'Crea piano' : 'Salva piano'),
            ),
            if (!widget.createNewPlan && widget.plan != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(
                    _PlanEditorResult.delete(),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Elimina piano'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editMeal(FeedingMeal? meal) async {
    final result = await showModalBottomSheet<FeedingMeal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MealEditorSheet(meal: meal);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = _meals.indexWhere((item) => item.id == result.id);

      if (index == -1) {
        _meals = [..._meals, result];
      } else {
        final updated = [..._meals];
        updated[index] = result;
        _meals = updated;
      }

      _meals.sort((a, b) {
        final first = a.hour * 60 + a.minute;
        final second = b.hour * 60 + b.minute;

        return first.compareTo(second);
      });
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi almeno un pasto')),
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.plan;

    Navigator.of(context).pop(
      _PlanEditorResult.save(
        FeedingPlan(
          id: existing?.id ?? 'plan-${now.microsecondsSinceEpoch}',
          title: _titleController.text.trim(),
          description: _optionalText(_descriptionController.text),
          snacks: _optionalText(_snacksController.text),
          startedAt: widget.createNewPlan ? now : existing?.startedAt ?? now,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          addToReminders: _addToReminders,
          meals: _meals,
        ),
      ),
    );
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}

class _EditableMealRow extends StatelessWidget {
  const _EditableMealRow({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  final FeedingMeal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        '${meal.hour.toString().padLeft(2, '0')}:${meal.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _FoodPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _FoodPalette.outline),
      ),
      child: ListTile(
        title: Text(meal.name),
        subtitle: Text(
          [
            if (meal.quantityLabel != null) meal.quantityLabel!,
            time,
          ].join(' · '),
        ),
        trailing: Wrap(
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealEditorSheet extends StatefulWidget {
  const _MealEditorSheet({
    this.meal,
  });

  final FeedingMeal? meal;

  @override
  State<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends State<_MealEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gramsController = TextEditingController();
  final _cansController = TextEditingController();

  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();

    final meal = widget.meal;

    if (meal != null) {
      _nameController.text = meal.name;
      _quantityController.text = meal.quantityLabel ?? '';
      _gramsController.text =
          meal.grams == null ? '' : _formatNumber(meal.grams!);
      _cansController.text =
          meal.cans == null ? '' : _formatNumber(meal.cans!);
      _time = TimeOfDay(hour: meal.hour, minute: meal.minute);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _gramsController.dispose();
    _cansController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.meal == null ? 'Nuovo pasto' : 'Modifica pasto',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome pasto',
                hintText: 'Es. Crocchette',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Inserisci il nome del pasto';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Etichetta quantità',
                hintText: 'Es. 25 g oppure 1 lattina',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gramsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Grammi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cansController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Lattine',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                'Orario ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Salva pasto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _time = selectedTime;
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final now = DateTime.now();

    Navigator.of(context).pop(
      FeedingMeal(
        id: widget.meal?.id ?? 'meal-${now.microsecondsSinceEpoch}',
        name: _nameController.text.trim(),
        quantityLabel: _optionalText(_quantityController.text),
        grams: _optionalDouble(_gramsController.text),
        cans: _optionalDouble(_cansController.text),
        hour: _time.hour,
        minute: _time.minute,
      ),
    );
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  double? _optionalDouble(String value) {
    final trimmed = value.trim().replaceAll(',', '.');

    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed);
  }
}

class _PastPlansSheet extends StatelessWidget {
  const _PastPlansSheet({
    required this.plans,
  });

  final List<FeedingPlan> plans;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Piani alimentari passati',
      child: Column(
        children: [
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nessun piano passato'),
            )
          else
            for (final plan in plans)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _FoodPalette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _FoodPalette.outline),
                ),
                child: ListTile(
                  title: Text(plan.title),
                  subtitle: Text(
                    DateFormat('d MMM yyyy', 'it').format(plan.startedAt),
                  ),
                  trailing: const Icon(Icons.restart_alt_rounded),
                  onTap: () => Navigator.of(context).pop(plan),
                ),
              ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _FoodPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _FoodPalette.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

enum _PlanEditorAction {
  save,
  delete,
}

class _PlanEditorResult {
  const _PlanEditorResult._({
    required this.action,
    this.plan,
  });

  factory _PlanEditorResult.save(FeedingPlan plan) {
    return _PlanEditorResult._(
      action: _PlanEditorAction.save,
      plan: plan,
    );
  }

  factory _PlanEditorResult.delete() {
    return const _PlanEditorResult._(
      action: _PlanEditorAction.delete,
    );
  }

  final _PlanEditorAction action;
  final FeedingPlan? plan;
}

class _BowlPainter extends CustomPainter {
  const _BowlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bowlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _FoodPalette.darkText
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final foodPaint = Paint()
      ..color = _FoodPalette.lightPurple
      ..style = PaintingStyle.fill;

    final bowlRect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.38,
      size.width * 0.64,
      size.height * 0.36,
    );

    final foodRect = Rect.fromLTWH(
      bowlRect.left + 3,
      bowlRect.top + bowlRect.height * 0.55,
      bowlRect.width - 6,
      bowlRect.height * 0.34,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        bowlRect.left,
        bowlRect.top - 5,
        bowlRect.width,
        12,
      ),
      bowlPaint,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        bowlRect.left,
        bowlRect.top - 5,
        bowlRect.width,
        12,
      ),
      borderPaint,
    );

    final bowlPath = Path()
      ..moveTo(bowlRect.left, bowlRect.top)
      ..lineTo(bowlRect.left + 8, bowlRect.bottom)
      ..lineTo(bowlRect.right - 8, bowlRect.bottom)
      ..lineTo(bowlRect.right, bowlRect.top)
      ..close();

    canvas.drawPath(bowlPath, bowlPaint);
    canvas.drawPath(bowlPath, borderPaint);

    canvas.drawRect(foodRect, foodPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
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

class _FoodPalette {
  const _FoodPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF0E6D0);
  static const outline = Color(0xFFE3D2B4);
  static const lightPurple = Color(0xFFF1E7FF);

  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);
  static const mutedText = Color(0xFFB4A48F);
  static const purple = Color(0xFFB084E8);

  static const warningBackground = Color(0xFFFFEBD8);
  static const warningBorder = Color(0xFFF2C7A4);
  static const warningIcon = Color(0xFFD06E4A);
  static const warningText = Color(0xFF8A5E41);
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}