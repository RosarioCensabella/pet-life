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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pet Life shows Italian onboarding disclaimer and navigates to home', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _pumpPetLifeApp(tester);

    expect(
      find.text('Tutta la vita del tuo pet, ordinata in un solo posto.'),
      findsOneWidget,
    );

    expect(
      find.textContaining('Pet Life aiuta a organizzare informazioni'),
      findsOneWidget,
    );

    expect(
      find.text('Accetta e continua'),
      findsOneWidget,
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Aggiungi il tuo primo animale'), findsOneWidget);
  });

  testWidgets('Pet Life supports English onboarding copy', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderNotificationSchedulerProvider.overrideWithValue(
            FakeReminderNotificationScheduler(),
          ),
          documentFileServiceProvider.overrideWithValue(
            FakeDocumentFileService(),
          ),
        ],
        child: const PetLifeApp(
          locale: Locale('en'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Your pet’s life, organized in one place.'),
      findsOneWidget,
    );

    expect(
      find.textContaining('Pet Life helps organize information'),
      findsOneWidget,
    );

    expect(
      find.text('Accept and continue'),
      findsOneWidget,
    );
  });

  testWidgets('User can add a pet and see it in Home', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _openHome(tester);

    await tester.tap(find.text('Aggiungi pet'));
    await tester.pumpAndSettle();

    expect(find.text('Aggiungi pet'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'Luna');
    await tester.enterText(find.byType(TextFormField).at(1), '3');
    await tester.enterText(find.byType(TextFormField).at(2), 'Europeo');

    await _tapSavePet(tester);

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.textContaining('Europeo'), findsOneWidget);
  });

  testWidgets('Dashboard shows enabled complete modules only', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);
    expect(find.text('Promemoria'), findsOneWidget);
    expect(find.text('Documenti'), findsOneWidget);
    expect(find.text('Diario salute'), findsNothing);
    expect(find.text('Farmaci'), findsNothing);
  });

  testWidgets('User can create and complete a reminder', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Promemoria'));
    await tester.pumpAndSettle();

    expect(find.text('Nessun promemoria'), findsOneWidget);

    await tester.tap(find.text('Aggiungi promemoria').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Vaccino annuale');
    await tester.enterText(find.byType(TextFormField).at(1), 'Portare libretto');

    await tester.ensureVisible(find.text('Salva promemoria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva promemoria'));
    await tester.pumpAndSettle();

    expect(find.text('Vaccino annuale'), findsOneWidget);
    expect(find.text('Attivo'), findsOneWidget);

    await tester.tap(find.text('Completa'));
    await tester.pumpAndSettle();

    expect(find.text('Completato'), findsOneWidget);
  });

  testWidgets('Home and calendar show upcoming reminders', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    _seedPetWithUpcomingReminder();

    await _openHome(tester);

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Prossime scadenze'), findsOneWidget);
    expect(find.text('Vaccino annuale'), findsOneWidget);

    await tester.tap(find.text('Calendario').first);
    await tester.pumpAndSettle();

    expect(find.text('Calendario'), findsWidgets);
    expect(find.text('Filtra per pet'), findsOneWidget);
    expect(find.text('Tutti i pet'), findsOneWidget);
    expect(find.text('Vaccino annuale'), findsOneWidget);
    expect(find.text('Luna'), findsWidgets);
  });

  testWidgets('User can add, open and delete a document', (
    tester,
  ) async {
    final fakeDocumentFileService = FakeDocumentFileService();

    await _setLargeTestViewport(tester);
    await _pumpPetLifeApp(
      tester,
      documentFileService: fakeDocumentFileService,
    );

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiungi pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Luna');
    await tester.enterText(find.byType(TextFormField).at(1), '3');

    await _tapSavePet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documenti'));
    await tester.pumpAndSettle();

    expect(find.text('Nessun documento'), findsOneWidget);

    await tester.tap(find.text('Aggiungi documento').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Libretto vaccinale',
    );

    await tester.tap(find.text('Seleziona file'));
    await tester.pumpAndSettle();

    expect(find.textContaining('libretto.pdf'), findsOneWidget);

    await tester.ensureVisible(find.text('Salva documento'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva documento'));
    await tester.pumpAndSettle();

    expect(find.text('Libretto vaccinale'), findsOneWidget);
    expect(find.text('libretto.pdf'), findsOneWidget);

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(fakeDocumentFileService.openedPaths, isNotEmpty);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminare questo documento?'), findsOneWidget);

    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();

    expect(find.text('Nessun documento'), findsOneWidget);
    expect(fakeDocumentFileService.deletedPaths, isNotEmpty);
  });

  testWidgets('User can postpone and skip reminders', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Promemoria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiungi promemoria').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Antiparassitario');

    await tester.ensureVisible(find.text('Salva promemoria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva promemoria'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rimanda 1 giorno'));
    await tester.pumpAndSettle();

    expect(find.text('Rimandato'), findsOneWidget);

    await tester.tap(find.text('Salta'));
    await tester.pumpAndSettle();

    expect(find.text('Saltato'), findsOneWidget);
  });

  testWidgets('User can edit a pet profile through profile module', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profilo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Milo');
    await tester.enterText(find.byType(TextFormField).at(1), '4');

    await _tapSavePet(tester);

    expect(find.text('Milo'), findsWidgets);
    expect(find.textContaining('4 anni'), findsOneWidget);
  });

  testWidgets('User can archive a pet and hide it from Home', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Archivia pet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archivia pet'));
    await tester.pumpAndSettle();

    expect(find.text('Archiviare questo pet?'), findsOneWidget);

    await tester.tap(find.text('Archivia'));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Luna'), findsNothing);
    expect(find.text('Aggiungi il tuo primo animale'), findsOneWidget);
  });
}

void _seedPetWithUpcomingReminder() {
  final now = DateTime.now();
  final createdAt = now.subtract(const Duration(days: 1));
  final scheduledAt = now.add(const Duration(days: 1));

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

  final remindersJson = jsonEncode([
    {
      'id': 'reminder-1',
      'petId': 'pet-1',
      'petName': 'Luna',
      'category': 'vaccine',
      'title': 'Vaccino annuale',
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': 'active',
      'createdAt': createdAt.toIso8601String(),
      'notes': null,
      'completedAt': null,
      'updatedAt': null,
    }
  ]);

  SharedPreferences.setMockInitialValues({
    'pet_life_pets_v1': petsJson,
    'pet_life_reminders_v1': remindersJson,
  });
}

Future<void> _setLargeTestViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _pumpPetLifeApp(
  WidgetTester tester, {
  DocumentFileService? documentFileService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reminderNotificationSchedulerProvider.overrideWithValue(
          FakeReminderNotificationScheduler(),
        ),
        documentFileServiceProvider.overrideWithValue(
          documentFileService ?? FakeDocumentFileService(),
        ),
      ],
      child: const PetLifeApp(
        locale: Locale('it'),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _openHome(WidgetTester tester) async {
  await _pumpPetLifeApp(tester);

  await tester.tap(find.text('Accetta e continua'));
  await tester.pumpAndSettle();
}

Future<void> _createPet(WidgetTester tester) async {
  await _openHome(tester);

  await tester.tap(find.text('Aggiungi pet'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Luna');
  await tester.enterText(find.byType(TextFormField).at(1), '3');
  await tester.enterText(find.byType(TextFormField).at(2), 'Europeo');

  await _tapSavePet(tester);

  expect(find.text('Luna'), findsOneWidget);
}

Future<void> _tapSavePet(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Salva pet');

  await tester.ensureVisible(saveButton);
  await tester.pumpAndSettle();

  await tester.tap(saveButton);
  await tester.pumpAndSettle();
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
  final openedPaths = <String>[];
  final deletedPaths = <String>[];

  @override
  Future<PickedLocalDocument?> pickAndCopyDocument({
    required String petId,
    required String documentId,
  }) async {
    return PickedLocalDocument(
      originalFileName: 'libretto.pdf',
      localPath: 'fake/path/$petId/$documentId/libretto.pdf',
      sizeBytes: 1024,
    );
  }

  @override
  Future<void> openDocument(String localPath) async {
    openedPaths.add(localPath);
  }

  @override
  Future<void> deleteDocument(String localPath) async {
    deletedPaths.add(localPath);
  }
}