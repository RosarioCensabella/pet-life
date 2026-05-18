import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/food_entry.dart';

class FoodLocalStorage {
  FoodLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const foodEntriesKey = 'pet_life_food_entries_v1';

  final SharedPreferences _preferences;

  List<FoodEntry> getEntries() {
    final rawEntries = _preferences.getString(foodEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => FoodEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<FoodEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(foodEntriesKey, encoded);
  }
}