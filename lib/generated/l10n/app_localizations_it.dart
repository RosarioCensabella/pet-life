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

  @override
  String get addPetTitle => 'Aggiungi pet';

  @override
  String get editPetTitle => 'Modifica pet';

  @override
  String get petNameLabel => 'Nome';

  @override
  String get petNameHint => 'Es. Luna';

  @override
  String get petNameRequired => 'Inserisci il nome del pet';

  @override
  String get speciesLabel => 'Specie';

  @override
  String get speciesDog => 'Cane';

  @override
  String get speciesCat => 'Gatto';

  @override
  String get speciesOther => 'Altro animale';

  @override
  String get estimatedAgeLabel => 'Età stimata';

  @override
  String get estimatedAgeHint => 'Es. 3';

  @override
  String get estimatedAgeRequired => 'Inserisci l\'età stimata';

  @override
  String get estimatedAgeInvalid => 'Inserisci un numero valido';

  @override
  String get yearsSuffix => 'anni';

  @override
  String get breedLabel => 'Razza';

  @override
  String get breedHint => 'Opzionale';

  @override
  String get sexLabel => 'Sesso';

  @override
  String get sexUnknown => 'Non specificato';

  @override
  String get sexFemale => 'Femmina';

  @override
  String get sexMale => 'Maschio';

  @override
  String get microchipLabel => 'Microchip';

  @override
  String get microchipHint => 'Opzionale';

  @override
  String get vetNameLabel => 'Veterinario';

  @override
  String get vetNameHint => 'Opzionale';

  @override
  String get savePet => 'Salva pet';

  @override
  String get petSaved => 'Pet salvato';

  @override
  String get loadingPets => 'Caricamento animali...';

  @override
  String get openPetDashboard => 'Apri dashboard';

  @override
  String get petDashboardTitle => 'Dashboard pet';

  @override
  String get petProfileSection => 'Profilo';

  @override
  String get petProfileDescription =>
      'Dati principali del pet salvati localmente su questo dispositivo.';

  @override
  String get petCareModulesHiddenTitle => 'Moduli cura pet';

  @override
  String get petCareModulesHiddenDescription =>
      'Promemoria, documenti, diario salute, visite, spese, assicurazione e report saranno attivati solo quando completi e testati.';

  @override
  String get backToHome => 'Torna alla Home';

  @override
  String get petNotFound => 'Pet non trovato';

  @override
  String get retry => 'Riprova';
}
