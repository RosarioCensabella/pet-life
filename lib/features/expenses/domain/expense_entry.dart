enum ExpenseCategory {
  vet,
  medication,
  food,
  grooming,
  insurance,
  documents,
  accessories,
  other,
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.petId,
    required this.petName,
    required this.category,
    required this.description,
    required this.amount,
    required this.currency,
    required this.expenseDate,
    required this.createdAt,
    this.vendor,
    this.notes,
  });

  final String id;
  final String petId;
  final String petName;
  final ExpenseCategory category;
  final String description;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String? vendor;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'category': category.name,
      'description': description,
      'amount': amount,
      'currency': currency,
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'vendor': vendor,
      'notes': notes,
    };
  }

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      category: ExpenseCategory.values.byName(
        (json['category'] as String?) ?? ExpenseCategory.other.name,
      ),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'EUR',
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      vendor: json['vendor'] as String?,
      notes: json['notes'] as String?,
    );
  }
}