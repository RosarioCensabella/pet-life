enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other,
}

enum FoodStockUnit {
  kg,
  cans,
}

class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.mealType,
    required this.foodName,
    required this.recordedAt,
    required this.createdAt,
    this.quantity,
    this.notes,
    this.updatedAt,
    this.currentPlanId,
    this.stocks = const [],
    this.plans = const [],
  });

  final String id;
  final String petId;
  final String petName;

  // Campi legacy mantenuti per compatibilità con vecchi dati/test.
  final MealType mealType;
  final String foodName;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? quantity;
  final String? notes;

  // Nuova struttura alimentazione.
  final DateTime? updatedAt;
  final String? currentPlanId;
  final List<FoodStock> stocks;
  final List<FeedingPlan> plans;

  FeedingPlan? get currentPlan {
    if (plans.isEmpty) {
      return null;
    }

    final selectedId = currentPlanId;

    if (selectedId == null) {
      return null;
    }

    for (final plan in plans) {
      if (plan.id == selectedId && plan.endedAt == null) {
        return plan;
      }
    }

    return null;
  }

  List<FeedingPlan> get pastPlans {
    final current = currentPlan;

    final sorted = plans
        .where(
          (plan) => current == null || plan.id != current.id,
        )
        .toList(growable: false);

    sorted.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return sorted;
  }

  FoodEntry copyWith({
    String? id,
    String? petId,
    String? petName,
    MealType? mealType,
    String? foodName,
    DateTime? recordedAt,
    DateTime? createdAt,
    String? quantity,
    String? notes,
    DateTime? updatedAt,
    String? currentPlanId,
    List<FoodStock>? stocks,
    List<FeedingPlan>? plans,
    bool clearQuantity = false,
    bool clearNotes = false,
    bool clearCurrentPlanId = false,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      notes: clearNotes ? null : notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPlanId:
          clearCurrentPlanId ? null : currentPlanId ?? this.currentPlanId,
      stocks: stocks ?? this.stocks,
      plans: plans ?? this.plans,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'mealType': mealType.name,
      'foodName': foodName,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'quantity': quantity,
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
      'currentPlanId': currentPlanId,
      'stocks': stocks.map((stock) => stock.toJson()).toList(growable: false),
      'plans': plans.map((plan) => plan.toJson()).toList(growable: false),
    };
  }

  factory FoodEntry.fromJson(Map<String, Object?> json) {
    final updatedAtRaw = json['updatedAt'] as String?;
    final stocksRaw = json['stocks'] as List?;
    final plansRaw = json['plans'] as List?;

    final legacyMealType = MealType.values.byName(
      (json['mealType'] as String?) ?? MealType.other.name,
    );

    final foodName = (json['foodName'] as String?) ?? 'Alimentazione';
    final petId = json['petId'] as String;
    final petName = (json['petName'] as String?) ?? 'Pet';
    final createdAt = DateTime.parse(json['createdAt'] as String);
    final recordedAt = DateTime.parse(json['recordedAt'] as String);

    final stocks = stocksRaw == null
        ? const <FoodStock>[]
        : stocksRaw
            .map(
              (item) => FoodStock.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(growable: false);

    var plans = plansRaw == null
        ? const <FeedingPlan>[]
        : plansRaw
            .map(
              (item) => FeedingPlan.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(growable: false);

    // Compatibilità: se arrivano vecchie voci alimentazione,
    // le mostriamo come storico/piano base invece di perdere i dati.
    if (plans.isEmpty && foodName.trim().isNotEmpty) {
      plans = [
        FeedingPlan(
          id: 'legacy-plan-${json['id']}',
          title: foodName,
          description: json['quantity'] as String?,
          snacks: json['notes'] as String?,
          startedAt: recordedAt,
          createdAt: createdAt,
          endedAt: recordedAt,
          meals: [
            FeedingMeal(
              id: 'legacy-meal-${json['id']}',
              name: foodName,
              quantityLabel: json['quantity'] as String?,
              hour: 9,
              minute: 0,
            ),
          ],
        ),
      ];
    }

    return FoodEntry(
      id: json['id'] as String,
      petId: petId,
      petName: petName,
      mealType: legacyMealType,
      foodName: foodName,
      recordedAt: recordedAt,
      createdAt: createdAt,
      quantity: json['quantity'] as String?,
      notes: json['notes'] as String?,
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
      currentPlanId: json['currentPlanId'] as String?,
      stocks: stocks,
      plans: plans,
    );
  }
}

class FoodStock {
  const FoodStock({
    required this.id,
    required this.name,
    required this.unit,
    required this.amount,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final FoodStockUnit unit;
  final double amount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodStock copyWith({
    String? id,
    String? name,
    FoodStockUnit? unit,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodStock(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit.name,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FoodStock.fromJson(Map<String, Object?> json) {
    final updatedAtRaw = json['updatedAt'] as String?;

    return FoodStock(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: FoodStockUnit.values.byName(
        (json['unit'] as String?) ?? FoodStockUnit.kg.name,
      ),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
    );
  }
}

class FeedingPlan {
  const FeedingPlan({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.createdAt,
    this.description,
    this.snacks,
    this.endedAt,
    this.updatedAt,
    this.addToReminders = false,
    this.automaticReminderIds = const [],
    this.meals = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? snacks;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool addToReminders;
  final List<String> automaticReminderIds;
  final List<FeedingMeal> meals;

  double get dailyGrams {
    var total = 0.0;

    for (final meal in meals) {
      total += meal.grams ?? 0;
    }

    return total;
  }

  double get dailyCans {
    var total = 0.0;

    for (final meal in meals) {
      total += meal.cans ?? 0;
    }

    return total;
  }

  FeedingPlan copyWith({
    String? id,
    String? title,
    String? description,
    String? snacks,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? addToReminders,
    List<String>? automaticReminderIds,
    List<FeedingMeal>? meals,
    bool clearDescription = false,
    bool clearSnacks = false,
    bool clearEndedAt = false,
  }) {
    return FeedingPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : description ?? this.description,
      snacks: clearSnacks ? null : snacks ?? this.snacks,
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      addToReminders: addToReminders ?? this.addToReminders,
      automaticReminderIds:
          automaticReminderIds ?? this.automaticReminderIds,
      meals: meals ?? this.meals,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'snacks': snacks,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'addToReminders': addToReminders,
      'automaticReminderIds': automaticReminderIds,
      'meals': meals.map((meal) => meal.toJson()).toList(growable: false),
    };
  }

  factory FeedingPlan.fromJson(Map<String, Object?> json) {
    final endedAtRaw = json['endedAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;
    final remindersRaw = json['automaticReminderIds'] as List?;
    final mealsRaw = json['meals'] as List?;

    return FeedingPlan(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      snacks: json['snacks'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: endedAtRaw == null ? null : DateTime.parse(endedAtRaw),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: updatedAtRaw == null ? null : DateTime.parse(updatedAtRaw),
      addToReminders: (json['addToReminders'] as bool?) ?? false,
      automaticReminderIds: remindersRaw == null
          ? const []
          : remindersRaw.cast<String>().toList(growable: false),
      meals: mealsRaw == null
          ? const []
          : mealsRaw
              .map(
                (item) => FeedingMeal.fromJson(
                  Map<String, Object?>.from(item as Map),
                ),
              )
              .toList(growable: false),
    );
  }
}

class FeedingMeal {
  const FeedingMeal({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.quantityLabel,
    this.grams,
    this.cans,
  });

  final String id;
  final String name;
  final String? quantityLabel;
  final double? grams;
  final double? cans;
  final int hour;
  final int minute;

  FeedingMeal copyWith({
    String? id,
    String? name,
    String? quantityLabel,
    double? grams,
    double? cans,
    int? hour,
    int? minute,
    bool clearQuantityLabel = false,
    bool clearGrams = false,
    bool clearCans = false,
  }) {
    return FeedingMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      quantityLabel:
          clearQuantityLabel ? null : quantityLabel ?? this.quantityLabel,
      grams: clearGrams ? null : grams ?? this.grams,
      cans: clearCans ? null : cans ?? this.cans,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'quantityLabel': quantityLabel,
      'grams': grams,
      'cans': cans,
      'hour': hour,
      'minute': minute,
    };
  }

  factory FeedingMeal.fromJson(Map<String, Object?> json) {
    return FeedingMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      quantityLabel: json['quantityLabel'] as String?,
      grams: (json['grams'] as num?)?.toDouble(),
      cans: (json['cans'] as num?)?.toDouble(),
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
    );
  }
}