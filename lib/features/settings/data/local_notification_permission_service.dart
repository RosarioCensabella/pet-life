import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../application/notification_permission_service.dart';
import '../domain/notification_permission_status.dart';

class LocalNotificationPermissionService
    implements NotificationPermissionService {
  LocalNotificationPermissionService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<NotificationPermissionStatus> getStatus() async {
    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final enabled = await androidPlugin?.areNotificationsEnabled();

      if (enabled == null) {
        return NotificationPermissionStatus.unknown;
      }

      return enabled
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } catch (_) {
      return NotificationPermissionStatus.unknown;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidPlugin?.requestNotificationsPermission();

      if (granted == null) {
        return getStatus();
      }

      return granted
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } catch (_) {
      return NotificationPermissionStatus.unknown;
    }
  }
}