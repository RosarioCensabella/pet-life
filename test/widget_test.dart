import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_life/app/feature_flags.dart';
import 'package:pet_life/app/feature_flags_provider.dart';
import 'package:pet_life/app/pet_life_app.dart';
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
      const ProviderScope(
        child: PetLifeApp(
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

  testWidgets('Dashboard hides reminders module while feature flag is off', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPet(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Profilo'), findsOneWidget);
    expect(find.text('Promemoria'), findsNothing);
    expect(find.text('Documenti'), findsNothing);
    expect(find.text('Diario salute'), findsNothing);
    expect(find.text('Farmaci'), findsNothing);
  });

  testWidgets('User can create and complete a reminder when feature flag is enabled', (
    tester,
  ) async {
    await _setLargeTestViewport(tester);
    await _createPetWithReminderFlag(tester);

    await tester.tap(find.text('Luna'));
    await tester.pumpAndSettle();

    expect(find.text('Promemoria'), findsOneWidget);

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

Future<void> _setLargeTestViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _pumpPetLifeApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: PetLifeApp(
        locale: Locale('it'),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpPetLifeAppWithReminderFlag(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureFlagsProvider.overrideWithValue(
          const FeatureFlags(
            petProfileModuleEnabled: true,
            remindersModuleEnabled: true,
            documentsModuleEnabled: false,
            healthDiaryModuleEnabled: false,
            weightModuleEnabled: false,
            foodModuleEnabled: false,
            symptomsModuleEnabled: false,
            medicationsModuleEnabled: false,
            visitsModuleEnabled: false,
            expensesModuleEnabled: false,
            insuranceModuleEnabled: false,
            reportsModuleEnabled: false,
          ),
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

Future<void> _openHomeWithReminderFlag(WidgetTester tester) async {
  await _pumpPetLifeAppWithReminderFlag(tester);

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

Future<void> _createPetWithReminderFlag(WidgetTester tester) async {
  await _openHomeWithReminderFlag(tester);

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