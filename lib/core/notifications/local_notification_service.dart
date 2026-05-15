import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/reminder.dart';
import 'reminder_notification_scheduler.dart';

class LocalNotificationService implements ReminderNotificationScheduler {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _androidChannelId = 'pet_life_reminders';
  static const _androidChannelName = 'Pet Life reminders';
  static const _androidChannelDescription =
      'Reminders created by the user for pet care organization.';

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      tz_data.initializeTimeZones();
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initializationSettings,
      );

      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();

    var androidGranted = true;
    var iosGranted = true;

    try {
      androidGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
    } catch (_) {
      androidGranted = true;
    }

    try {
      iosGranted = await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          true;
    } catch (_) {
      iosGranted = true;
    }

    return androidGranted && iosGranted;
  }

  @override
  Future<void> scheduleReminder({
    required Reminder reminder,
  }) async {
    await initialize();

    final notificationId = _stableNotificationId(reminder.id);

    await cancelReminder(reminder.id);

    if (reminder.status != ReminderStatus.active &&
        reminder.status != ReminderStatus.postponed) {
      return;
    }

    if (reminder.scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    try {
      await requestPermissions();

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Pet Life · ${reminder.petName}',
        body: reminder.title,
        scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'reminder:${reminder.id}:pet:${reminder.petId}',
      );
    } catch (_) {
      // Non blocchiamo il salvataggio del promemoria se il sistema operativo
      // nega permessi o scheduling. La UI resta consistente e il dato è salvato.
    }
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    try {
      await initialize();

      await _plugin.cancel(
        id: _stableNotificationId(reminderId),
      );
    } catch (_) {
      // Safe no-op.
    }
  }

  int _stableNotificationId(String value) {
    var hash = 0x811c9dc5;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }

    return hash & 0x7fffffff;
  }
}