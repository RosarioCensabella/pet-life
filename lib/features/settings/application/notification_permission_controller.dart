import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_notification_permission_service.dart';
import '../domain/notification_permission_status.dart';
import 'notification_permission_service.dart';

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
  return LocalNotificationPermissionService();
});

final notificationPermissionControllerProvider = StateNotifierProvider<
    NotificationPermissionController,
    AsyncValue<NotificationPermissionStatus>>((ref) {
  final controller = NotificationPermissionController(ref: ref);
  controller.loadStatus();

  return controller;
});

class NotificationPermissionController
    extends StateNotifier<AsyncValue<NotificationPermissionStatus>> {
  NotificationPermissionController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadStatus() async {
    try {
      final status =
          await _ref.read(notificationPermissionServiceProvider).getStatus();

      state = AsyncValue.data(status);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    state = const AsyncValue.loading();

    try {
      final status = await _ref
          .read(notificationPermissionServiceProvider)
          .requestPermission();

      state = AsyncValue.data(status);

      return status;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);

      return NotificationPermissionStatus.unknown;
    }
  }
}