import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/medication_entry.dart';

class MedicationLocalStorage {
  MedicationLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const medicationEntriesKey = 'pet_life_medication_entries_v1';

  final SharedPreferences _preferences;

  List<MedicationEntry> getEntries() {
    final rawEntries = _preferences.getString(medicationEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => MedicationEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<MedicationEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(medicationEntriesKey, encoded);
  }
}