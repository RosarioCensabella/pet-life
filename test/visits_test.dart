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
    'User can add, calendar-sync, complete and delete a vet visit',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Accetta e continua'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Visite'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Visite'));
      await tester.pumpAndSettle();

      expect(find.text('Visite'), findsOneWidget);
      expect(find.text('Nessuna visita'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi visita'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Controllo annuale',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Dott.ssa Bianchi',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Clinica Pet Life',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Verifica generale e vaccini',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Salva visita'));
      await tester.pumpAndSettle();

      expect(find.text('Controllo annuale'), findsOneWidget);
      expect(find.textContaining('Dott.ssa Bianchi'), findsOneWidget);
      expect(find.textContaining('Clinica Pet Life'), findsOneWidget);
      expect(find.textContaining('Verifica generale e vaccini'), findsOneWidget);
      expect(find.text('Aggiungi al calendario'), findsOneWidget);
      expect(find.text('Svolta'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Aggiungi al calendario'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Rimuovi'), findsOneWidget);

      await tester.tap(find.text('Rimuovi'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi al calendario'), findsOneWidget);

      await _tapVisible(tester, find.text('Svolta'));
      await tester.pumpAndSettle();

      expect(find.text('Chiudi visita'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '65',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Tutto ok. Controllo tra un anno.',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Svolta'));
      await tester.pumpAndSettle();

      expect(find.text('SVOLTA'), findsOneWidget);
      expect(find.text('65,00 €'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Tutto ok'), findsOneWidget);
      expect(find.text('Aggiungi al calendario'), findsNothing);
      expect(find.text('Rimuovi'), findsNothing);

      await tester.tap(find.text('⋯').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifica'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica visita'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Controllo annuale aggiornato',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Aggiorna visita'));
      await tester.pumpAndSettle();

      expect(find.text('Controllo annuale aggiornato'), findsOneWidget);

      await tester.tap(find.text('⋯').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminare questa visita?'), findsOneWidget);

      await tester.tap(find.text('Elimina').last);
      await tester.pumpAndSettle();

      expect(find.text('Nessuna visita'), findsOneWidget);
      expect(find.text('Controllo annuale aggiornato'), findsNothing);
    },
  );

  testWidgets(
    'User can add a past vet visit with amount',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Accetta e continua'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Visite'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Visite'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Visita ortopedica',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Dr. Marini',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Clinica San Rocco',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Zoppia leggera',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Questa visita è già stata svolta'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(4),
        'Articolazione anteriore ok',
      );
      await tester.enterText(
        find.byType(TextFormField).at(5),
        '85',
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Salva visita'));
      await tester.pumpAndSettle();

      expect(find.text('SVOLTA'), findsOneWidget);
      expect(find.text('Visita ortopedica'), findsOneWidget);
      expect(find.textContaining('Dr. Marini'), findsOneWidget);
      expect(find.textContaining('Clinica San Rocco'), findsOneWidget);
      expect(find.textContaining('Articolazione anteriore ok'), findsOneWidget);
      expect(find.text('85,00 €'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Speso in visite'), findsOneWidget);
    },
  );
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder,
) async {
  expect(finder, findsAtLeastNWidgets(1));

  final target = finder.last;

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();

  await tester.tap(target);
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1500));

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
      'breed': 'Meticcio',
      'sex': 'female',
      'microchip': '123456789',
      'vetName': 'Dott.ssa Bianchi',
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