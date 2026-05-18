import '../domain/notification_permission_status.dart';

abstract class NotificationPermissionService {
  Future<NotificationPermissionStatus> getStatus();

  Future<NotificationPermissionStatus> requestPermission();
}