import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/visit_entry.dart';

class VisitLocalStorage {
  VisitLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const visitEntriesKey = 'pet_life_visit_entries_v1';

  final SharedPreferences _preferences;

  List<VisitEntry> getEntries() {
    final rawEntries = _preferences.getString(visitEntriesKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;

    return decoded
        .map(
          (item) => VisitEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveEntries(List<VisitEntry> entries) async {
    final encoded = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );

    await _preferences.setString(visitEntriesKey, encoded);
  }
}