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

      expect(find.text('Nessun farmaco attivo'), findsOneWidget);
      expect(find.textContaining('non prescrive farmaci'), findsNothing);
      expect(
        find.textContaining(
          'Dosi, durata e farmaci li decide solo il veterinario',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Nuovo farmaco'), findsOneWidget);
      expect(
        find.textContaining('promemoria giornalieri automatici'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Antibiotico',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '1 compressa',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '0',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Dott.ssa Bianchi',
      );
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'Come indicato dal veterinario',
      );
      await tester.enterText(
        find.byType(TextFormField).at(5),
        'Dopo il pasto',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _scrollModalUntilVisible(
        tester,
        find.text('Salva farmaco'),
      );

      await tester.tap(find.text('Salva farmaco'));
      await tester.pumpAndSettle();

      expect(find.text('Antibiotico'), findsOneWidget);
      expect(find.textContaining('Dott.ssa Bianchi'), findsOneWidget);
      expect(
        find.textContaining('Come indicato dal veterinario'),
        findsOneWidget,
      );
      expect(find.text('Dopo il pasto'), findsOneWidget);
      expect(find.textContaining('0 di'), findsOneWidget);
      expect(find.textContaining('rimaste'), findsOneWidget);
      expect(find.text('Farmaco salvato e promemoria creati'), findsOneWidget);
      expect(find.text('Sospendi'), findsOneWidget);
      expect(find.text('Modifica'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
      expect(find.text('Presa'), findsOneWidget);

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

      final reminders = jsonDecode(rawReminders!) as List;
      expect(reminders.length, greaterThan(1));

      final firstMedicationReminder = reminders.first as Map;
      expect(firstMedicationReminder['category'], 'medication');
      expect(firstMedicationReminder['title'], 'Farmaco: Antibiotico');

      final rawMedications =
          preferences.getString('pet_life_medication_entries_v1');
      expect(rawMedications, isNotNull);

      final medications = jsonDecode(rawMedications!) as List;
      final medication = medications.single as Map;
      final reminderTimes = medication['reminderTimes'] as List;
      final automaticReminderIds = medication['automaticReminderIds'] as List;
      final takenReminderIds = medication['takenReminderIds'] as List;

      expect(reminderTimes, hasLength(1));
      expect(automaticReminderIds.length, reminders.length);
      expect(takenReminderIds, isEmpty);

      await tester.tap(find.text('Presa'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 di'), findsOneWidget);

      final rawMedicationsAfterTaken =
          preferences.getString('pet_life_medication_entries_v1');
      expect(rawMedicationsAfterTaken, isNotNull);

      final medicationsAfterTaken =
          jsonDecode(rawMedicationsAfterTaken!) as List;
      final medicationAfterTaken = medicationsAfterTaken.single as Map;
      final takenReminderIdsAfterTaken =
          medicationAfterTaken['takenReminderIds'] as List;

      expect(takenReminderIdsAfterTaken, hasLength(1));

      final rawRemindersAfterTaken =
          preferences.getString('pet_life_reminders_v1');
      expect(rawRemindersAfterTaken, isNotNull);

      final remindersAfterTaken = jsonDecode(rawRemindersAfterTaken!) as List;
      final completedMedicationReminders = remindersAfterTaken.where((item) {
        final reminder = item as Map;
        return reminder['category'] == 'medication' &&
            reminder['status'] == 'completed';
      }).toList();

      expect(completedMedicationReminders, hasLength(1));

      await tester.tap(find.text('Annulla'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('0 di'), findsOneWidget);

      final rawMedicationsAfterUndo =
          preferences.getString('pet_life_medication_entries_v1');
      expect(rawMedicationsAfterUndo, isNotNull);

      final medicationsAfterUndo = jsonDecode(rawMedicationsAfterUndo!) as List;
      final medicationAfterUndo = medicationsAfterUndo.single as Map;
      final takenReminderIdsAfterUndo =
          medicationAfterUndo['takenReminderIds'] as List;

      expect(takenReminderIdsAfterUndo, isEmpty);

      final rawRemindersAfterUndo =
          preferences.getString('pet_life_reminders_v1');
      expect(rawRemindersAfterUndo, isNotNull);

      final remindersAfterUndo = jsonDecode(rawRemindersAfterUndo!) as List;
      final completedMedicationRemindersAfterUndo =
          remindersAfterUndo.where((item) {
        final reminder = item as Map;
        return reminder['category'] == 'medication' &&
            reminder['status'] == 'completed';
      }).toList();

      expect(completedMedicationRemindersAfterUndo, isEmpty);

      await tester.tap(find.text('Presa'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 di'), findsOneWidget);

      await tester.tap(find.text('Sospendi'));
      await tester.pumpAndSettle();

      expect(find.text('Reintegra'), findsOneWidget);

      await tester.tap(find.text('Reintegra'));
      await tester.pumpAndSettle();

      expect(find.text('Sospendi'), findsOneWidget);

      await tester.tap(find.text('Modifica'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica farmaco'), findsOneWidget);
      expect(find.text('Cura di Luna. Pet Life crea promemoria giornalieri automatici e aggiorna l’avanzamento quando segni una presa.'), findsOneWidget);

      await _scrollModalUntilVisible(
        tester,
        find.text('Aggiorna farmaco'),
      );

      expect(find.text('Aggiorna farmaco'), findsOneWidget);
      expect(find.text('Elimina cura'), findsOneWidget);

      await tester.tap(find.text('Elimina cura'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminare questo farmaco?'), findsOneWidget);

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun farmaco attivo'), findsOneWidget);

      for (final reminderId in automaticReminderIds.cast<String>()) {
        expect(scheduler.cancelledReminderIds, contains(reminderId));
      }

      final rawMedicationsAfterDelete =
          preferences.getString('pet_life_medication_entries_v1');
      expect(rawMedicationsAfterDelete, isNotNull);

      final medicationsAfterDelete =
          jsonDecode(rawMedicationsAfterDelete!) as List;
      expect(medicationsAfterDelete, isEmpty);
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

Future<void> _scrollModalUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  for (var attempt = 0; attempt < 18 && finder.evaluate().isEmpty; attempt++) {
    await tester.dragFrom(
      const Offset(450, 1120),
      const Offset(0, -360),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }

  expect(finder, findsOneWidget);

  await tester.ensureVisible(finder);
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
    },
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