import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_life/app/pet_life_app.dart';
import 'package:pet_life/core/notifications/reminder_notification_scheduler.dart';
import 'package:pet_life/core/notifications/reminder_notification_scheduler_provider.dart';
import 'package:pet_life/features/documents/application/document_file_service.dart';
import 'package:pet_life/features/documents/application/document_file_service_provider.dart';
import 'package:pet_life/features/reminders/domain/reminder.dart';
import 'package:pet_life/features/settings/application/app_data_service.dart';
import 'package:pet_life/features/settings/application/app_data_service_provider.dart';
import 'package:pet_life/features/settings/application/notification_permission_controller.dart';
import 'package:pet_life/features/settings/application/notification_permission_service.dart';
import 'package:pet_life/features/settings/domain/app_data_export_result.dart';
import 'package:pet_life/features/settings/domain/notification_permission_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings can request notification permissions', (
    tester,
  ) async {
    final fakeNotificationPermissionService =
        FakeNotificationPermissionService();

    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderNotificationSchedulerProvider.overrideWithValue(
            FakeReminderNotificationScheduler(),
          ),
          documentFileServiceProvider.overrideWithValue(
            FakeDocumentFileService(),
          ),
          appDataServiceProvider.overrideWith(
            (ref) async => FakeAppDataService(),
          ),
          notificationPermissionServiceProvider.overrideWithValue(
            fakeNotificationPermissionService,
          ),
        ],
        child: const PetLifeApp(
          locale: Locale('it'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni').first);
    await tester.pumpAndSettle();

    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Stato permesso notifiche'), findsOneWidget);
    expect(find.text('Disattivate'), findsOneWidget);
    expect(find.text('Attiva notifiche'), findsOneWidget);

    await tester.tap(find.text('Attiva notifiche'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeNotificationPermissionService.requestCalled, isTrue);
    expect(find.text('Attive'), findsOneWidget);
  });
}

class FakeNotificationPermissionService
    implements NotificationPermissionService {
  bool requestCalled = false;
  NotificationPermissionStatus status = NotificationPermissionStatus.denied;

  @override
  Future<NotificationPermissionStatus> getStatus() async {
    return status;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requestCalled = true;
    status = NotificationPermissionStatus.granted;

    return status;
  }
}

class FakeReminderNotificationScheduler
    implements ReminderNotificationScheduler {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<void> scheduleReminder({
    required Reminder reminder,
  }) async {}

  @override
  Future<void> cancelReminder(String reminderId) async {}
}

class FakeDocumentFileService implements DocumentFileService {
  @override
  Future<PickedLocalDocument?> pickAndCopyDocument({
    required String petId,
    required String documentId,
  }) async {
    return null;
  }

  @override
  Future<void> openDocument(String localPath) async {}

  @override
  Future<void> deleteDocument(String localPath) async {}
}

class FakeAppDataService implements AppDataService {
  @override
  Future<AppDataExportResult> exportLocalData() async {
    return AppDataExportResult(
      filePath: 'fake/path/pet_life_export.json',
      jsonContent: '{"pets":[]}',
      exportedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clearLocalData() async {}
}