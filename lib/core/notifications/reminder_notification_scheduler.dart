import '../../features/reminders/domain/reminder.dart';

abstract class ReminderNotificationScheduler {
  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<void> scheduleReminder({
    required Reminder reminder,
  });

  Future<void> cancelReminder(String reminderId);
}