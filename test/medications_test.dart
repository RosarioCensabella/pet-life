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

  testWidgets(
    'User can add editable medication and recurring automatic reminders without dosage advice',
    (tester) async {
      final scheduler = FakeReminderNotificationScheduler();

      await _pumpApp(
        tester,
        scheduler: scheduler,
      );

      await tester.tap(find.text('Accetta e continua'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Farmaci'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Farmaci'), findsOneWidget);

      await tester.tap(find.text('Farmaci'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun farmaco'), findsOneWidget);
      expect(find.textContaining('non prescrive farmaci'), findsOneWidget);
      expect(find.textContaining('non calcola dosaggi'), findsOneWidget);
      expect(
        find.textContaining('promemoria giornalieri automatici'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Antibiotico');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Dott.ssa Bianchi',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Come indicato dal veterinario',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Dopo il pasto',
      );

      await tester.ensureVisible(find.text('Salva farmaco'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Salva farmaco'));
      await tester.pumpAndSettle();

      expect(find.text('Antibiotico'), findsOneWidget);
      expect(find.textContaining('Dott.ssa Bianchi'), findsOneWidget);
      expect(
        find.textContaining('Come indicato dal veterinario'),
        findsOneWidget,
      );
      expect(find.text('Dopo il pasto'), findsOneWidget);
      expect(find.textContaining('Orari giornalieri promemoria'), findsWidgets);
      expect(find.text('Farmaco salvato e promemoria creati'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      expect(scheduler.scheduledReminders.length, greaterThan(1));
      expect(
        scheduler.scheduledReminders.every(
          (reminder) => reminder.category == ReminderCategory.medication,
        ),
        isTrue,
      );
      expect(
        scheduler.scheduledReminders.every(
          (reminder) => reminder.title == 'Farmaco: Antibiotico',
        ),
        isTrue,
      );

      final preferences = await SharedPreferences.getInstance();
      final rawReminders = preferences.getString('pet_life_reminders_v1');

      expect(rawReminders, isNotNull);

      final reminders = jsonDecode(rawReminders!) as List<dynamic>;

      expect(reminders.length, greaterThan(1));

      final firstMedicationReminder = reminders.first as Map<String, dynamic>;

      expect(firstMedicationReminder['category'], 'medication');
      expect(firstMedicationReminder['title'], 'Farmaco: Antibiotico');

      final rawMedications =
          preferences.getString('pet_life_medication_entries_v1');

      expect(rawMedications, isNotNull);

      final medications = jsonDecode(rawMedications!) as List<dynamic>;
      final medication = medications.single as Map<String, dynamic>;
      final reminderTimes = medication['reminderTimes'] as List<dynamic>;
      final automaticReminderIds =
          medication['automaticReminderIds'] as List<dynamic>;

      expect(reminderTimes, hasLength(1));
      expect(automaticReminderIds.length, scheduler.scheduledReminders.length);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Modifica farmaco'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifica farmaco'), findsOneWidget);
      expect(find.text('Aggiorna farmaco'), findsOneWidget);
      expect(find.text('Annulla modifica'), findsOneWidget);

      await tester.tap(find.text('Annulla modifica'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_outline),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final scheduledReminderCount = scheduler.scheduledReminders.length;

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Eliminare questo farmaco?'), findsOneWidget);

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun farmaco'), findsOneWidget);
      expect(scheduler.cancelledReminderIds.length, scheduledReminderCount);
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeReminderNotificationScheduler scheduler,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reminderNotificationSchedulerProvider.overrideWithValue(scheduler),
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
      'profileImagePath': null,
      'colorValue': 0xFF20B486,
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
  final scheduledReminders = <Reminder>[];
  final cancelledReminderIds = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<void> scheduleReminder({
    required Reminder reminder,
  }) async {
    scheduledReminders.add(reminder);
  }

  @override
  Future<void> cancelReminder(String reminderId) async {
    cancelledReminderIds.add(reminderId);
  }
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