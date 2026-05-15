import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_notification_service.dart';
import 'reminder_notification_scheduler.dart';

final reminderNotificationSchedulerProvider =
    Provider<ReminderNotificationScheduler>((ref) {
  return LocalNotificationService.instance;
});