import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/health_entry.dart';

class HealthLocalStorage {
  HealthLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const healthEntriesKey = 'pet_life_health_entries_v1';

  final SharedPreferences _preferences;

  List<HealthEntry> getEntries() {
    final rawEntries = _preferences.getString(healthEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => HealthEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<HealthEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(healthEntriesKey, encoded);
  }
}