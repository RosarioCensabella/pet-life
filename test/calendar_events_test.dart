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
    _seedCalendarData();
  });

  testWidgets(
    'Calendar shows unified colored pet events from all modules',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Accetta e continua'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calendario').last);
      await tester.pumpAndSettle();

      await _expectVisibleByScrolling(
        tester,
        find.textContaining('Eventi del giorno'),
      );

      await _expectVisibleByScrolling(tester, find.text('Controllo Milo'));
      await _expectVisibleByScrolling(tester, find.text('Libretto sanitario'));
      await _expectVisibleByScrolling(tester, find.textContaining('12.4 kg'));
      await _expectVisibleByScrolling(tester, find.text('Nota appetito'));
      await _expectVisibleByScrolling(tester, find.text('Zoppia lieve'));
      await _expectVisibleByScrolling(tester, find.text('Pasto: Crocchette'));
      await _expectVisibleByScrolling(tester, find.text('Antibiotico'));
      await _expectVisibleByScrolling(tester, find.text('Controllo annuale'));
      await _expectVisibleByScrolling(tester, find.text('Visita veterinaria'));

      await _tapVisible(tester, find.text('Mostra tutto il mese'));
      await tester.pumpAndSettle();

      await _expectVisibleByScrolling(
        tester,
        find.textContaining('Eventi del mese'),
      );
      await _expectVisibleByScrolling(tester, find.text('Oggi'));

      await _expectVisibleByScrolling(tester, find.text('Controllo Milo'));
      await _expectVisibleByScrolling(tester, find.text('Libretto sanitario'));
      await _expectVisibleByScrolling(tester, find.textContaining('12.4 kg'));
      await _expectVisibleByScrolling(tester, find.text('Nota appetito'));
      await _expectVisibleByScrolling(tester, find.text('Zoppia lieve'));
      await _expectVisibleByScrolling(tester, find.text('Pasto: Crocchette'));
      await _expectVisibleByScrolling(tester, find.text('Antibiotico'));
      await _expectVisibleByScrolling(tester, find.text('Controllo annuale'));
      await _expectVisibleByScrolling(tester, find.text('Visita veterinaria'));
      await _expectVisibleByScrolling(tester, find.text('Vaccino annuale'));

      await _tapVisible(tester, find.text('Oggi'));
      await tester.pumpAndSettle();

      await _expectVisibleByScrolling(
        tester,
        find.textContaining('Eventi del giorno'),
      );
      await _expectVisibleByScrolling(tester, find.text('Mostra tutto il mese'));
    },
  );
}

Future<void> _expectVisibleByScrolling(
  WidgetTester tester,
  Finder finder,
) async {
  await _bringIntoViewIfNeeded(tester, finder);

  expect(finder, findsAtLeastNWidgets(1));
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await _bringIntoViewIfNeeded(tester, finder);

  expect(finder, findsAtLeastNWidgets(1));

  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _bringIntoViewIfNeeded(
  WidgetTester tester,
  Finder finder,
) async {
  for (var attempt = 0; attempt < 18; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pumpAndSettle();
      return;
    }

    final scrollables = find.byType(Scrollable);

    if (scrollables.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 120));
      continue;
    }

    await tester.drag(scrollables.first, const Offset(0, -450));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1800));

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

void _seedCalendarData() {
  final now = DateTime.now();
  final baseDate = DateTime(now.year, now.month, now.day, 9);

  SharedPreferences.setMockInitialValues({
    'pet_life_pets_v1': jsonEncode([
      {
        'id': 'pet-1',
        'name': 'Luna',
        'species': 'dog',
        'estimatedAgeYears': 3,
        'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
        'breed': 'Meticcio',
        'sex': 'female',
        'microchip': '123456789',
        'vetName': 'Dott.ssa Bianchi',
        'profileImagePath': null,
        'colorValue': 0xFF20B486,
        'archivedAt': null,
      },
      {
        'id': 'pet-2',
        'name': 'Milo',
        'species': 'cat',
        'estimatedAgeYears': 4,
        'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
        'breed': 'Europeo',
        'sex': 'male',
        'microchip': null,
        'vetName': null,
        'profileImagePath': null,
        'colorValue': 0xFFEF4444,
        'archivedAt': null,
      },
    ]),
    'pet_life_reminders_v1': jsonEncode([
      {
        'id': 'reminder-vaccine-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'vaccine',
        'title': 'Vaccino annuale',
        'scheduledAt': baseDate.add(const Duration(days: 1)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': null,
        'completedAt': null,
        'updatedAt': null,
      },
      {
        'id': 'reminder-checkup-1',
        'petId': 'pet-2',
        'petName': 'Milo',
        'category': 'checkup',
        'title': 'Controllo Milo',
        'scheduledAt': baseDate.toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': null,
        'completedAt': null,
        'updatedAt': null,
      },
      {
        'id': 'reminder-food-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'custom',
        'title': 'Pasto: Crocchette',
        'scheduledAt': baseDate.add(const Duration(hours: 5)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': 'Piano alimentare: Royal Canin Sterilised\nQuantità: 80 g',
        'completedAt': null,
        'updatedAt': null,
      },
      {
        'id': 'reminder-medication-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'medication',
        'title': 'Antibiotico',
        'scheduledAt': baseDate.add(const Duration(hours: 6)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': 'Farmaco inserito da utente',
        'completedAt': null,
        'updatedAt': null,
      },
      {
        'id': 'visit-visit-1-reminder',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'vetVisit',
        'title': 'Controllo annuale',
        'scheduledAt': baseDate.add(const Duration(hours: 7)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': 'visitId:visit-1',
        'completedAt': null,
        'updatedAt': null,
      },
    ]),
    'pet_life_documents_v1': jsonEncode([
      {
        'id': 'document-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'title': 'Libretto sanitario',
        'category': 'healthRecord',
        'originalFileName': 'libretto.pdf',
        'localPath': 'fake/path/libretto.pdf',
        'sizeBytes': 1200,
        'createdAt': baseDate.add(const Duration(hours: 1)).toIso8601String(),
        'notes': null,
      },
    ]),
    'pet_life_weight_entries_v1': jsonEncode([
      {
        'id': 'weight-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'weightKg': 12.4,
        'recordedAt': baseDate.add(const Duration(hours: 2)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'notes': null,
      },
    ]),
    'pet_life_health_entries_v1': jsonEncode([
      {
        'id': 'health-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'type': 'diary',
        'title': 'Nota appetito',
        'recordedAt': baseDate.add(const Duration(hours: 3)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'notes': null,
        'symptomIntensity': null,
      },
      {
        'id': 'symptom-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'type': 'symptom',
        'title': 'Zoppia lieve',
        'recordedAt': baseDate.add(const Duration(hours: 4)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'notes': null,
        'symptomIntensity': 'mild',
      },
    ]),
    'pet_life_expense_entries_v1': jsonEncode([
      {
        'id': 'expense-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'vet',
        'description': 'Visita veterinaria',
        'amount': 49.90,
        'currency': 'EUR',
        'expenseDate': baseDate.add(const Duration(hours: 8)).toIso8601String(),
        'createdAt': now.toIso8601String(),
        'vendor': 'Clinica Pet Life',
        'notes': null,
      },
    ]),
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