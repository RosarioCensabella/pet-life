import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder.dart';

class ReminderLocalStorage {
  ReminderLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const _remindersKey = 'pet_life_reminders_v1';

  final SharedPreferences _preferences;

  List<Reminder> getReminders() {
    final rawReminders = _preferences.getString(_remindersKey);

    if (rawReminders == null || rawReminders.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawReminders) as List<dynamic>;

    return decoded
        .map((item) => Reminder.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final encoded = jsonEncode(
      reminders.map((reminder) => reminder.toJson()).toList(growable: false),
    );

    await _preferences.setString(_remindersKey, encoded);
  }
}