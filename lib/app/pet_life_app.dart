import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../generated/l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class PetLifeApp extends StatelessWidget {
  const PetLifeApp({
    super.key,
    this.locale,
  });

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pet Life',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: buildPetLifeTheme(),
      routerConfig: buildAppRouter(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}