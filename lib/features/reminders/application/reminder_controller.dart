import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_notification_scheduler_provider.dart';
import '../../medications/application/medication_controller.dart';
import '../../pets/application/pet_controller.dart';
import '../data/reminder_local_storage.dart';
import '../domain/reminder.dart';

final reminderLocalStorageProvider = FutureProvider<ReminderLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return ReminderLocalStorage(preferences: preferences);
  },
);

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

  Reminder? reminderById(String reminderId) {
    return _findReminder(reminderId);
  }

  Future<void> addReminder(Reminder reminder) async {
    await _ensureLoaded();

    final currentReminders = state.valueOrNull ?? const <Reminder>[];
    final withoutDuplicate = currentReminders
        .where((item) => item.id != reminder.id)
        .toList(growable: false);

    final updatedReminders = [...withoutDuplicate, reminder];

    await _saveAndEmit(updatedReminders);

    if (_shouldSchedule(reminder)) {
      await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
            reminder: reminder,
          );
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    await _ensureLoaded();

    final currentReminders = state.valueOrNull ?? const <Reminder>[];

    final updatedReminders = currentReminders
        .where((reminder) => reminder.id != reminderId)
        .toList(growable: false);

    await _saveAndEmit(updatedReminders);
    await _ref.read(reminderNotificationSchedulerProvider).cancelReminder(
          reminderId,
        );
  }

  Future<void> deleteReminders(List<String> reminderIds) async {
    await _ensureLoaded();

    final ids = reminderIds.toSet();
    final currentReminders = state.valueOrNull ?? const <Reminder>[];

    final updatedReminders = currentReminders
        .where((reminder) => !ids.contains(reminder.id))
        .toList(growable: false);

    await _saveAndEmit(updatedReminders);

    for (final reminderId in ids) {
      await _ref.read(reminderNotificationSchedulerProvider).cancelReminder(
            reminderId,
          );
    }
  }

  Future<void> completeReminder(String reminderId) async {
    await _ensureLoaded();

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

    await _ref
        .read(medicationControllerProvider.notifier)
        .markReminderTaken(reminderId);
  }

  Future<void> reopenReminder(String reminderId) async {
    await _ensureLoaded();

    final now = DateTime.now();

    final updatedReminders = _mapReminder(
      reminderId,
      (reminder) => reminder.copyWith(
        status: ReminderStatus.active,
        updatedAt: now,
        clearCompletedAt: true,
      ),
    );

    await _saveAndEmit(updatedReminders);

    final reminder = _findReminder(reminderId);

    if (reminder != null && _shouldSchedule(reminder)) {
      await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
            reminder: reminder,
          );
    }

    await _ref
        .read(medicationControllerProvider.notifier)
        .markReminderNotTaken(reminderId);
  }

  Future<void> postponeReminderByOneDay(String reminderId) async {
    await _ensureLoaded();

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

    if (updatedReminder != null && _shouldSchedule(updatedReminder)) {
      await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
            reminder: updatedReminder,
          );
    }
  }

  Future<void> skipReminder(String reminderId) async {
    await _ensureLoaded();

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

  Future<void> pauseMedicationReminders(List<String> reminderIds) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final ids = reminderIds.toSet();

    final updatedReminders = (state.valueOrNull ?? const <Reminder>[]).map(
      (reminder) {
        if (!ids.contains(reminder.id)) {
          return reminder;
        }

        if (reminder.status == ReminderStatus.completed) {
          return reminder;
        }

        return reminder.copyWith(
          status: ReminderStatus.skipped,
          updatedAt: now,
          clearCompletedAt: true,
        );
      },
    ).toList(growable: false);

    await _saveAndEmit(updatedReminders);

    for (final reminderId in ids) {
      await _ref.read(reminderNotificationSchedulerProvider).cancelReminder(
            reminderId,
          );
    }
  }

  Future<void> reinstateMedicationReminders(List<String> reminderIds) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final ids = reminderIds.toSet();

    final updatedReminders = (state.valueOrNull ?? const <Reminder>[]).map(
      (reminder) {
        if (!ids.contains(reminder.id)) {
          return reminder;
        }

        if (reminder.status == ReminderStatus.completed) {
          return reminder;
        }

        return reminder.copyWith(
          status: ReminderStatus.active,
          updatedAt: now,
          clearCompletedAt: true,
        );
      },
    ).toList(growable: false);

    await _saveAndEmit(updatedReminders);

    for (final reminder in updatedReminders) {
      if (!ids.contains(reminder.id)) {
        continue;
      }

      if (_shouldSchedule(reminder)) {
        await _ref.read(reminderNotificationSchedulerProvider).scheduleReminder(
              reminder: reminder,
            );
      }
    }
  }

  Future<void> _ensureLoaded() async {
    if (state.isLoading || state.valueOrNull == null) {
      await loadReminders();
    }
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

  bool _shouldSchedule(Reminder reminder) {
    final isActionable = reminder.status == ReminderStatus.active ||
        reminder.status == ReminderStatus.postponed;

    return isActionable && reminder.scheduledAt.isAfter(DateTime.now());
  }
}