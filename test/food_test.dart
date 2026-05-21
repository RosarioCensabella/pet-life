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
    'User can manage feeding stock and current feeding plan',
    (tester) async {
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

      expect(find.text('SCORTE'), findsOneWidget);
      expect(find.text('Royal Canin Sterilised'), findsWidgets);
      expect(find.textContaining('~66 giorni'), findsOneWidget);
      expect(find.text('Piano alimentare'), findsOneWidget);
      expect(find.text('Crocchette'), findsOneWidget);
      expect(find.text('25 g'), findsOneWidget);
      expect(find.text('07:30'), findsOneWidget);
      expect(find.text('Umido + crocc.'), findsOneWidget);
      expect(find.text('30 g + 5 g'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      expect(find.text('Snack e premi'), findsOneWidget);
      expect(
        find.textContaining('Cambi di dieta e quantità precise'),
        findsOneWidget,
      );

      await tester.tap(find.text('Gestisci'));
      await tester.pumpAndSettle();

      expect(find.text('Gestisci scorte'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Modifica scorta'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(1),
        '2',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Aggiungi scorta'));
      await tester.pumpAndSettle();

      expect(find.text('Nuova scorta'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Umido lattine',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '12',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(find.text('Royal Canin Sterilised'), findsWidgets);
      expect(find.text('Umido lattine'), findsOneWidget);

      await _tapVisible(tester, find.text('Salva scorte'));
      await tester.pumpAndSettle();

      expect(find.text('SCORTE'), findsOneWidget);
      expect(find.text('Royal Canin Sterilised'), findsWidgets);
      expect(find.text('Umido lattine'), findsOneWidget);
      expect(find.textContaining('~33 giorni'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Modifica piano alimentare'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Gastrointestinal',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Crocchette digestive',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Snack sospesi per 7 giorni',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Salva piano'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Gastrointestinal'), findsOneWidget);
      expect(find.textContaining('Crocchette digestive'), findsOneWidget);
      expect(find.text('Snack sospesi per 7 giorni'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_active_rounded).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      await tester.tap(find.text('Nuovo piano'));
      await tester.pumpAndSettle();

      expect(find.text('Nuovo piano alimentare'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Renal support',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Nuovo piano concordato',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Solo premi approvati',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Crea piano'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Renal support'), findsOneWidget);
      expect(find.textContaining('Nuovo piano concordato'), findsOneWidget);
      expect(find.text('Solo premi approvati'), findsOneWidget);
      expect(find.text('1 piani alimentari passati'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.archive_outlined).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Nessun piano alimentare in corso'), findsOneWidget);
      expect(find.text('2 piani alimentari passati'), findsOneWidget);

      await tester.tap(find.text('2 piani alimentari passati'));
      await tester.pumpAndSettle();

      expect(find.text('Piani alimentari passati'), findsOneWidget);
      expect(find.text('Renal support'), findsOneWidget);
      expect(find.text('Gastrointestinal'), findsOneWidget);

      await tester.tap(find.text('Gastrointestinal'));
      await tester.pumpAndSettle();

      expect(find.text('Gastrointestinal'), findsOneWidget);
      expect(find.text('Renal support'), findsNothing);
    },
  );
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder,
) async {
  expect(finder, findsOneWidget);

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();

  await tester.tap(finder);
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));

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
      'profileImagePath': null,
      'colorValue': 0xFFB084E8,
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