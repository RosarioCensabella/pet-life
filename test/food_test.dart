import 'dart:convert';

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
    _seedPet();
  });

  testWidgets('User can add and delete a food entry', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentazione'), findsOneWidget);

    await tester.ensureVisible(find.text('Alimentazione'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Alimentazione'));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna voce alimentazione'), findsOneWidget);
    expect(find.textContaining('non crea diete'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Crocchette');
    await tester.enterText(find.byType(TextFormField).at(1), '80 g');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Pasto mattutino',
    );

    await tester.tap(find.text('Salva alimento'));
    await tester.pumpAndSettle();

    expect(find.text('Crocchette'), findsOneWidget);
    expect(find.text('Quantità: 80 g'), findsOneWidget);
    expect(find.text('Pasto mattutino'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Eliminare questa voce?'), findsOneWidget);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna voce alimentazione'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
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
          FakeNotificationPermissionService(),
        ),
      ],
      child: const PetLifeApp(
        locale: Locale('it'),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _seedPet() {
  final createdAt = DateTime.now().subtract(const Duration(days: 1));

  final petsJson = jsonEncode([
    {
      'id': 'pet-1',
      'name': 'Luna',
      'species': 'dog',
      'estimatedAgeYears': 3,
      'createdAt': createdAt.toIso8601String(),
      'breed': 'Europeo',
      'sex': 'unknown',
      'microchip': null,
      'vetName': null,
      'archivedAt': null,
    }
  ]);

  SharedPreferences.setMockInitialValues({
    'pet_life_pets_v1': petsJson,
  });
}

class FakeNotificationPermissionService
    implements NotificationPermissionService {
  @override
  Future<NotificationPermissionStatus> getStatus() async {
    return NotificationPermissionStatus.denied;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    return NotificationPermissionStatus.granted;
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