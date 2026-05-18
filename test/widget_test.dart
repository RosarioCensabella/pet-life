import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_life/app/feature_flags.dart';
import 'package:pet_life/app/feature_flags_provider.dart';
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

  testWidgets('Pet Life shows Italian onboarding and opens Home', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(
      find.text('Tutta la vita del tuo pet, ordinata in un solo posto.'),
      findsOneWidget,
    );
    expect(find.text('Accetta e continua'), findsOneWidget);

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Aggiungi pet'), findsWidgets);
  });

  testWidgets('Pet Life supports English onboarding copy', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      locale: const Locale('en'),
    );

    expect(
      find.text('Your pet’s life, organized in one place.'),
      findsOneWidget,
    );
    expect(find.text('Accept and continue'), findsOneWidget);

    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your pets'), findsWidgets);
    expect(find.text('Add pet'), findsWidgets);
  });

  testWidgets('Home empty state is visible after onboarding', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Aggiungi pet'), findsWidgets);
  });

  testWidgets('Dashboard shows enabled complete modules only', (
    tester,
  ) async {
    _seedPet();

    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1800),
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Profilo'), findsWidgets);
    expect(find.text('Promemoria'), findsOneWidget);
    expect(find.text('Documenti'), findsOneWidget);
    expect(find.text('Diario salute'), findsOneWidget);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('Alimentazione'), findsOneWidget);
    expect(find.text('Sintomi'), findsOneWidget);
    expect(find.text('Farmaci'), findsOneWidget);
    expect(find.text('Visite'), findsOneWidget);
    expect(find.text('Spese'), findsOneWidget);

    expect(find.text('Assicurazione'), findsNothing);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('Settings shows legal, notification and data sections', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1600),
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni').last);
    await tester.pumpAndSettle();

    expect(find.text('Informazioni legali'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Termini di servizio'), findsOneWidget);
    expect(find.text('Disclaimer medico-veterinario'), findsOneWidget);

    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Stato permesso notifiche'), findsOneWidget);
    expect(find.text('Attiva notifiche'), findsOneWidget);

    expect(find.text('Gestione dati'), findsOneWidget);
    expect(find.text('Esporta dati'), findsOneWidget);
    expect(find.text('Elimina dati locali'), findsOneWidget);
  });

  testWidgets('Settings can request notification permission', (
    tester,
  ) async {
    final notificationPermissionService = FakeNotificationPermissionService();

    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1600),
      notificationPermissionService: notificationPermissionService,
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni').last);
    await tester.pumpAndSettle();

    expect(find.text('Disattivate'), findsOneWidget);

    await tester.tap(find.text('Attiva notifiche'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(notificationPermissionService.requestCalled, isTrue);
    expect(find.text('Attive'), findsOneWidget);
  });

  testWidgets('Settings shows Premium plans without fake purchase actions', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1600),
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scopri Premium'));
    await tester.pumpAndSettle();

    expect(find.text('Pet Life Premium'), findsOneWidget);
    expect(find.text('3,99 €/mese'), findsOneWidget);
    expect(find.text('29,99 €/anno'), findsOneWidget);

    expect(find.text('Ripristina acquisti'), findsNothing);
    expect(find.text('Acquista'), findsNothing);
  });

  testWidgets('Settings can export data', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1600),
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Esporta dati'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Export completato'), findsOneWidget);
    expect(
      find.textContaining('fake/path/pet_life_export.json'),
      findsOneWidget,
    );
  });

  testWidgets('Settings can delete local data', (
    tester,
  ) async {
    _seedPet();

    await _pumpApp(
      tester,
      surfaceSize: const Size(1000, 1600),
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);

    await tester.tap(find.text('Impostazioni').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina dati locali'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminare tutti i dati locali?'), findsOneWidget);

    await tester.tap(find.text('Elimina tutto'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dati locali eliminati'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('it'),
  Size surfaceSize = const Size(900, 1200),
  NotificationPermissionService? notificationPermissionService,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWithValue(defaultFeatureFlags),
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
          notificationPermissionService ?? FakeNotificationPermissionService(),
        ),
      ],
      child: PetLifeApp(
        locale: locale,
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
      'archivedAt': null,
    }
  ]);

  SharedPreferences.setMockInitialValues({
    'pet_life_pets_v1': petsJson,
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