import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_notification_scheduler_provider.dart';
import '../../pets/application/pet_controller.dart';
import '../data/reminder_local_storage.dart';
import '../domain/reminder.dart';

final reminderLocalStorageProvider =
    FutureProvider<ReminderLocalStorage>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);

  return ReminderLocalStorage(preferences: preferences);
});

final reminderControllerProvider =
    StateNotifierProvider<ReminderController, AsyncValue<List<Reminder>>>(
  (ref) {
    final controller = ReminderController(ref: ref);
    controller.loadReminders();
    return controller;
  },
);

class ReminderController extends StateNotifier<AsyncValue<List<Reminder>>> {
  ReminderController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadReminders() async {
    try {
      final storage = await _ref.read(reminderLocalStorageProvider.future);
      final reminders = storage.getReminders();
      state = AsyncValue.data(_sortReminders(reminders));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Reminder> remindersForPet(String petId) {
    final reminders = state.valueOrNull ?? const <Reminder>[];

    return reminders
        .where((reminder) => reminder.petId == petId)
        .toList(growable: false);
  }

  Future<void> addReminder(Reminder reminder) async {
    final currentReminders = state.valueOrNull ?? const <Reminder>[];
    final updatedReminders = [...currentReminders, reminder];

    await _saveAndEmit(updatedReminders);

    await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
          reminder: reminder,
        );
  }

  Future<void> completeReminder(String reminderId) async {
    final now = DateTime.now();

    final updatedReminders = _mapReminder(
      reminderId,
      (reminder) => reminder.copyWith(
        status: ReminderStatus.completed,
        completedAt: now,
        updatedAt: now,
      ),
    );

    await _saveAndEmit(updatedReminders);
    await _ref.read(reminderNotificationSchedulerProvider).cancelReminder(
          reminderId,
        );
  }

  Future<void> postponeReminderByOneDay(String reminderId) async {
    final now = DateTime.now();

    final updatedReminders = _mapReminder(
      reminderId,
      (reminder) => reminder.copyWith(
        status: ReminderStatus.postponed,
        scheduledAt: reminder.scheduledAt.add(const Duration(days: 1)),
        updatedAt: now,
        clearCompletedAt: true,
      ),
    );

    await _saveAndEmit(updatedReminders);

    final updatedReminder = _findReminder(reminderId);

    if (updatedReminder != null) {
      await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
            reminder: updatedReminder,
          );
    }
  }

  Future<void> skipReminder(String reminderId) async {
    final now = DateTime.now();

    final updatedReminders = _mapReminder(
      reminderId,
      (reminder) => reminder.copyWith(
        status: ReminderStatus.skipped,
        updatedAt: now,
        clearCompletedAt: true,
      ),
    );

    await _saveAndEmit(updatedReminders);
    await _ref.read(reminderNotificationSchedulerProvider).cancelReminder(
          reminderId,
        );
  }

  Reminder? _findReminder(String reminderId) {
    final reminders = state.valueOrNull ?? const <Reminder>[];

    for (final reminder in reminders) {
      if (reminder.id == reminderId) {
        return reminder;
      }
    }

    return null;
  }

  List<Reminder> _mapReminder(
    String reminderId,
    Reminder Function(Reminder reminder) update,
  ) {
    final currentReminders = state.valueOrNull ?? const <Reminder>[];

    return currentReminders.map((reminder) {
      if (reminder.id == reminderId) {
        return update(reminder);
      }

      return reminder;
    }).toList(growable: false);
  }

  Future<void> _saveAndEmit(List<Reminder> reminders) async {
    final sortedReminders = _sortReminders(reminders);

    state = AsyncValue.data(sortedReminders);

    try {
      final storage = await _ref.read(reminderLocalStorageProvider.future);
      await storage.saveReminders(sortedReminders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Reminder> _sortReminders(List<Reminder> reminders) {
    final sorted = [...reminders];

    sorted.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return sorted;
  }
}