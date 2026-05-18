import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/expense_entry.dart';

class ExpenseLocalStorage {
  ExpenseLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const expenseEntriesKey = 'pet_life_expense_entries_v1';

  final SharedPreferences _preferences;

  List<ExpenseEntry> getEntries() {
    final rawEntries = _preferences.getString(expenseEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => ExpenseEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<ExpenseEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(expenseEntriesKey, encoded);
  }
}