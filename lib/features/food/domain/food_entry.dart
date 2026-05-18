enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
  other,
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
  });

  final String id;
  final String petId;
  final String petName;
  final MealType mealType;
  final String foodName;
  final DateTime recordedAt;
  final DateTime createdAt;
  final String? quantity;
  final String? notes;

  Map<String, dynamic> toJson() {
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
    };
  }

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      mealType: MealType.values.byName(
        (json['mealType'] as String?) ?? MealType.other.name,
      ),
      foodName: json['foodName'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      quantity: json['quantity'] as String?,
      notes: json['notes'] as String?,
    );
  }
}