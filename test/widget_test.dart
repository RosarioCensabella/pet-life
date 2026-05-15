import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_life/app/pet_life_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pet Life shows Italian onboarding disclaimer and navigates to home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PetLifeApp(
          locale: Locale('it'),
        ),
      ),
    );

    await tester.pumpAndSettle();

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
    await tester.pumpWidget(
      const ProviderScope(
        child: PetLifeApp(
          locale: Locale('it'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Accetta e continua'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aggiungi pet'));
    await tester.pumpAndSettle();

    expect(find.text('Aggiungi pet'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'Luna');
    await tester.enterText(find.byType(TextFormField).at(1), '3');
    await tester.enterText(find.byType(TextFormField).at(2), 'Europeo');

    await tester.ensureVisible(find.text('Salva pet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva pet'));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi animali'), findsWidgets);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.textContaining('Europeo'), findsOneWidget);
  });
}