// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Pet Life';

  @override
  String get homeTitle => 'I tuoi animali';

  @override
  String get addPet => 'Aggiungi pet';

  @override
  String get welcomeTitle =>
      'Tutta la vita del tuo pet, ordinata in un solo posto.';

  @override
  String get medicalDisclaimer =>
      'Pet Life aiuta a organizzare informazioni e promemoria. Non fornisce diagnosi, terapie, prescrizioni o indicazioni mediche. Per sintomi preoccupanti o persistenti contatta il veterinario.';

  @override
  String get acceptAndContinue => 'Accetta e continua';

  @override
  String get settings => 'Impostazioni';

  @override
  String get calendar => 'Calendario';

  @override
  String get documents => 'Documenti';

  @override
  String get reports => 'Report';

  @override
  String get addFirstPetTitle => 'Aggiungi il tuo primo animale';

  @override
  String get addFirstPetDescription =>
      'Crea il profilo del pet per iniziare a organizzare promemoria, documenti, diario salute e visite.';

  @override
  String get nextStepCreatePet => 'Prossimo step: creazione profilo pet';
}
