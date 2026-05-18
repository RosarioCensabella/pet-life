import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weight_entry.dart';

class WeightLocalStorage {
  WeightLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const weightEntriesKey = 'pet_life_weight_entries_v1';

  final SharedPreferences _preferences;

  List<WeightEntry> getEntries() {
    final rawEntries = _preferences.getString(weightEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => WeightEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<WeightEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(weightEntriesKey, encoded);
  }
}