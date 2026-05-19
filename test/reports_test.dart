import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

String? _clipboardText;

void main() {
  setUp(() {
    _clipboardText = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final arguments = methodCall.arguments as Map<dynamic, dynamic>?;
          _clipboardText = arguments?['text'] as String?;
          return null;
        }

        if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{
            'text': _clipboardText,
          };
        }

        return null;
      },
    );

    _seedPetLifeData();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('User can open a non diagnostic report', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Report'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Report non diagnostico'), findsAtLeastNWidgets(1));
    expect(find.textContaining('diagnosi'), findsAtLeastNWidgets(1));
    expect(find.textContaining('veterinario'), findsAtLeastNWidgets(1));

    expect(find.text('Riepilogo pet'), findsOneWidget);
    expect(find.text('Luna'), findsAtLeastNWidgets(1));
    expect(find.text('Promemoria'), findsAtLeastNWidgets(1));
    expect(find.text('Peso'), findsAtLeastNWidgets(1));
    expect(find.text('Salute'), findsAtLeastNWidgets(1));
    expect(find.text('Farmaci'), findsAtLeastNWidgets(1));
    expect(find.text('Visite'), findsAtLeastNWidgets(1));
    expect(find.text('Spese'), findsAtLeastNWidgets(1));
    expect(find.text('Documenti'), findsAtLeastNWidgets(1));
  });

  testWidgets('User can copy a non diagnostic report', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Report'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Copia report'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Copia report'), findsOneWidget);

    await tester.tap(find.text('Copia report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_clipboardText, isNotNull);
    expect(_clipboardText, contains('Report non diagnostico'));
    expect(_clipboardText, contains('Luna'));
    expect(_clipboardText, contains('Promemoria'));
    expect(_clipboardText, contains('Farmaci'));
  });
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

void _seedPetLifeData() {
  final now = DateTime.now();

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
      }
    ]),
    'pet_life_reminders_v1': jsonEncode([
      {
        'id': 'reminder-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'category': 'vaccine',
        'title': 'Vaccino annuale',
        'scheduledAt': now.add(const Duration(days: 7)).toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'notes': null,
        'completedAt': null,
        'updatedAt': null,
      }
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
        'createdAt': now.toIso8601String(),
        'notes': null,
      }
    ]),
    'pet_life_weight_entries_v1': jsonEncode([
      {
        'id': 'weight-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'weightKg': 12.4,
        'recordedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'notes': null,
      }
    ]),
    'pet_life_health_entries_v1': jsonEncode([
      {
        'id': 'health-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'type': 'diary',
        'title': 'Nota appetito',
        'recordedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'notes': 'Ha mangiato regolarmente.',
        'symptomIntensity': null,
      }
    ]),
    'pet_life_food_entries_v1': jsonEncode([
      {
        'id': 'food-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'mealType': 'breakfast',
        'foodName': 'Crocchette',
        'recordedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'quantity': '80 g',
        'notes': null,
      }
    ]),
    'pet_life_medication_entries_v1': jsonEncode([
      {
        'id': 'medication-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'name': 'Antibiotico',
        'status': 'active',
        'startDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'endDate': now.add(const Duration(days: 5)).toIso8601String(),
        'prescribedBy': 'Dott.ssa Bianchi',
        'instructions': 'Secondo prescrizione veterinaria',
        'notes': null,
        'reminderTimes': [
          {
            'id': '12-00',
            'hour': 12,
            'minute': 0,
          }
        ],
        'automaticReminderIds': [],
      }
    ]),
    'pet_life_visit_entries_v1': jsonEncode([
      {
        'id': 'visit-1',
        'petId': 'pet-1',
        'petName': 'Luna',
        'visitType': 'routine',
        'reason': 'Controllo annuale',
        'visitDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'clinicName': 'Clinica Pet Life',
        'outcome': null,
        'nextVisitDate': null,
        'notes': null,
      }
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
        'expenseDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'vendor': 'Clinica Pet Life',
        'notes': null,
      }
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