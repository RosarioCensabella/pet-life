import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In it, this message translates to:
  /// **'Pet Life'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In it, this message translates to:
  /// **'I tuoi animali'**
  String get homeTitle;

  /// No description provided for @addPet.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi pet'**
  String get addPet;

  /// No description provided for @welcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutta la vita del tuo pet, ordinata in un solo posto.'**
  String get welcomeTitle;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In it, this message translates to:
  /// **'Pet Life aiuta a organizzare informazioni e promemoria. Non fornisce diagnosi, terapie, prescrizioni o indicazioni mediche. Per sintomi preoccupanti o persistenti contatta il veterinario.'**
  String get medicalDisclaimer;

  /// No description provided for @acceptAndContinue.
  ///
  /// In it, this message translates to:
  /// **'Accetta e continua'**
  String get acceptAndContinue;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @calendar.
  ///
  /// In it, this message translates to:
  /// **'Calendario'**
  String get calendar;

  /// No description provided for @documents.
  ///
  /// In it, this message translates to:
  /// **'Documenti'**
  String get documents;

  /// No description provided for @reports.
  ///
  /// In it, this message translates to:
  /// **'Report'**
  String get reports;

  /// No description provided for @addFirstPetTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi il tuo primo animale'**
  String get addFirstPetTitle;

  /// No description provided for @addFirstPetDescription.
  ///
  /// In it, this message translates to:
  /// **'Crea il profilo del pet per iniziare a organizzare promemoria, documenti, diario salute e visite.'**
  String get addFirstPetDescription;

  /// No description provided for @nextStepCreatePet.
  ///
  /// In it, this message translates to:
  /// **'Prossimo step: creazione profilo pet'**
  String get nextStepCreatePet;

  /// No description provided for @addPetTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi pet'**
  String get addPetTitle;

  /// No description provided for @editPetTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica pet'**
  String get editPetTitle;

  /// No description provided for @petNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get petNameLabel;

  /// No description provided for @petNameHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Luna'**
  String get petNameHint;

  /// No description provided for @petNameRequired.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il nome del pet'**
  String get petNameRequired;

  /// No description provided for @speciesLabel.
  ///
  /// In it, this message translates to:
  /// **'Specie'**
  String get speciesLabel;

  /// No description provided for @speciesDog.
  ///
  /// In it, this message translates to:
  /// **'Cane'**
  String get speciesDog;

  /// No description provided for @speciesCat.
  ///
  /// In it, this message translates to:
  /// **'Gatto'**
  String get speciesCat;

  /// No description provided for @speciesOther.
  ///
  /// In it, this message translates to:
  /// **'Altro animale'**
  String get speciesOther;

  /// No description provided for @estimatedAgeLabel.
  ///
  /// In it, this message translates to:
  /// **'Età stimata'**
  String get estimatedAgeLabel;

  /// No description provided for @estimatedAgeHint.
  ///
  /// In it, this message translates to:
  /// **'Es. 3'**
  String get estimatedAgeHint;

  /// No description provided for @estimatedAgeRequired.
  ///
  /// In it, this message translates to:
  /// **'Inserisci l\'età stimata'**
  String get estimatedAgeRequired;

  /// No description provided for @estimatedAgeInvalid.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un numero valido'**
  String get estimatedAgeInvalid;

  /// No description provided for @yearsSuffix.
  ///
  /// In it, this message translates to:
  /// **'anni'**
  String get yearsSuffix;

  /// No description provided for @breedLabel.
  ///
  /// In it, this message translates to:
  /// **'Razza'**
  String get breedLabel;

  /// No description provided for @breedHint.
  ///
  /// In it, this message translates to:
  /// **'Opzionale'**
  String get breedHint;

  /// No description provided for @sexLabel.
  ///
  /// In it, this message translates to:
  /// **'Sesso'**
  String get sexLabel;

  /// No description provided for @sexUnknown.
  ///
  /// In it, this message translates to:
  /// **'Non specificato'**
  String get sexUnknown;

  /// No description provided for @sexFemale.
  ///
  /// In it, this message translates to:
  /// **'Femmina'**
  String get sexFemale;

  /// No description provided for @sexMale.
  ///
  /// In it, this message translates to:
  /// **'Maschio'**
  String get sexMale;

  /// No description provided for @microchipLabel.
  ///
  /// In it, this message translates to:
  /// **'Microchip'**
  String get microchipLabel;

  /// No description provided for @microchipHint.
  ///
  /// In it, this message translates to:
  /// **'Opzionale'**
  String get microchipHint;

  /// No description provided for @vetNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Veterinario'**
  String get vetNameLabel;

  /// No description provided for @vetNameHint.
  ///
  /// In it, this message translates to:
  /// **'Opzionale'**
  String get vetNameHint;

  /// No description provided for @savePet.
  ///
  /// In it, this message translates to:
  /// **'Salva pet'**
  String get savePet;

  /// No description provided for @petSaved.
  ///
  /// In it, this message translates to:
  /// **'Pet salvato'**
  String get petSaved;

  /// No description provided for @petUpdated.
  ///
  /// In it, this message translates to:
  /// **'Pet aggiornato'**
  String get petUpdated;

  /// No description provided for @loadingPets.
  ///
  /// In it, this message translates to:
  /// **'Caricamento animali...'**
  String get loadingPets;

  /// No description provided for @openPetDashboard.
  ///
  /// In it, this message translates to:
  /// **'Apri dashboard'**
  String get openPetDashboard;

  /// No description provided for @petDashboardTitle.
  ///
  /// In it, this message translates to:
  /// **'Dashboard pet'**
  String get petDashboardTitle;

  /// No description provided for @petProfileSection.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get petProfileSection;

  /// No description provided for @petProfileDescription.
  ///
  /// In it, this message translates to:
  /// **'Dati principali del pet salvati localmente su questo dispositivo.'**
  String get petProfileDescription;

  /// No description provided for @backToHome.
  ///
  /// In it, this message translates to:
  /// **'Torna alla Home'**
  String get backToHome;

  /// No description provided for @petNotFound.
  ///
  /// In it, this message translates to:
  /// **'Pet non trovato'**
  String get petNotFound;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @editPet.
  ///
  /// In it, this message translates to:
  /// **'Modifica pet'**
  String get editPet;

  /// No description provided for @archivePet.
  ///
  /// In it, this message translates to:
  /// **'Archivia pet'**
  String get archivePet;

  /// No description provided for @archivePetConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Archiviare questo pet?'**
  String get archivePetConfirmTitle;

  /// No description provided for @archivePetConfirmMessage.
  ///
  /// In it, this message translates to:
  /// **'Il pet non sarà più visibile nella Home e i promemoria futuri verranno disattivati nelle prossime fasi. I dati restano conservati per consultazione ed export.'**
  String get archivePetConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @archive.
  ///
  /// In it, this message translates to:
  /// **'Archivia'**
  String get archive;

  /// No description provided for @petArchived.
  ///
  /// In it, this message translates to:
  /// **'Pet archiviato'**
  String get petArchived;

  /// No description provided for @activeProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo attivo'**
  String get activeProfile;

  /// No description provided for @archivedProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo archiviato'**
  String get archivedProfile;

  /// No description provided for @petActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni profilo'**
  String get petActions;

  /// No description provided for @petActionsDescription.
  ///
  /// In it, this message translates to:
  /// **'Puoi aggiornare i dati principali del pet o archiviarlo se non vuoi più vederlo nella Home.'**
  String get petActionsDescription;

  /// No description provided for @noActivePetsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun pet attivo'**
  String get noActivePetsTitle;

  /// No description provided for @noActivePetsDescription.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi un pet per iniziare a organizzare informazioni, documenti e promemoria.'**
  String get noActivePetsDescription;

  /// No description provided for @petDashboardChooseAction.
  ///
  /// In it, this message translates to:
  /// **'Cosa vuoi fare?'**
  String get petDashboardChooseAction;

  /// No description provided for @moduleProfileTitle.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get moduleProfileTitle;

  /// No description provided for @moduleProfileDescription.
  ///
  /// In it, this message translates to:
  /// **'Modifica dati, specie, età, microchip e veterinario.'**
  String get moduleProfileDescription;

  /// No description provided for @moduleRemindersTitle.
  ///
  /// In it, this message translates to:
  /// **'Promemoria'**
  String get moduleRemindersTitle;

  /// No description provided for @moduleDocumentsTitle.
  ///
  /// In it, this message translates to:
  /// **'Documenti'**
  String get moduleDocumentsTitle;

  /// No description provided for @moduleHealthDiaryTitle.
  ///
  /// In it, this message translates to:
  /// **'Diario salute'**
  String get moduleHealthDiaryTitle;

  /// No description provided for @moduleWeightTitle.
  ///
  /// In it, this message translates to:
  /// **'Peso'**
  String get moduleWeightTitle;

  /// No description provided for @moduleFoodTitle.
  ///
  /// In it, this message translates to:
  /// **'Alimentazione'**
  String get moduleFoodTitle;

  /// No description provided for @moduleSymptomsTitle.
  ///
  /// In it, this message translates to:
  /// **'Sintomi'**
  String get moduleSymptomsTitle;

  /// No description provided for @moduleMedicationsTitle.
  ///
  /// In it, this message translates to:
  /// **'Farmaci'**
  String get moduleMedicationsTitle;

  /// No description provided for @moduleVisitsTitle.
  ///
  /// In it, this message translates to:
  /// **'Visite'**
  String get moduleVisitsTitle;

  /// No description provided for @moduleExpensesTitle.
  ///
  /// In it, this message translates to:
  /// **'Spese'**
  String get moduleExpensesTitle;

  /// No description provided for @moduleInsuranceTitle.
  ///
  /// In it, this message translates to:
  /// **'Assicurazione'**
  String get moduleInsuranceTitle;

  /// No description provided for @moduleReportsTitle.
  ///
  /// In it, this message translates to:
  /// **'Report'**
  String get moduleReportsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
