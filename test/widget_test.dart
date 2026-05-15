import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_life/app/pet_life_app.dart';

void main() {
  testWidgets('Pet Life shows Italian onboarding disclaimer and navigates to home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PetLifeApp(
        locale: Locale('it'),
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
      const PetLifeApp(
        locale: Locale('en'),
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
}