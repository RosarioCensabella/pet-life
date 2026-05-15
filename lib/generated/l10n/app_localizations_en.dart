// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pet Life';

  @override
  String get homeTitle => 'Your pets';

  @override
  String get addPet => 'Add pet';

  @override
  String get welcomeTitle => 'Your pet’s life, organized in one place.';

  @override
  String get medicalDisclaimer =>
      'Pet Life helps organize information and reminders. It does not provide diagnoses, treatments, prescriptions, or medical advice. For concerning or persistent symptoms, contact your veterinarian.';

  @override
  String get acceptAndContinue => 'Accept and continue';

  @override
  String get settings => 'Settings';

  @override
  String get calendar => 'Calendar';

  @override
  String get documents => 'Documents';

  @override
  String get reports => 'Reports';

  @override
  String get addFirstPetTitle => 'Add your first pet';

  @override
  String get addFirstPetDescription =>
      'Create your pet profile to start organizing reminders, documents, health diary and vet visits.';

  @override
  String get nextStepCreatePet => 'Next step: pet profile creation';

  @override
  String get addPetTitle => 'Add pet';

  @override
  String get editPetTitle => 'Edit pet';

  @override
  String get petNameLabel => 'Name';

  @override
  String get petNameHint => 'E.g. Luna';

  @override
  String get petNameRequired => 'Enter the pet name';

  @override
  String get speciesLabel => 'Species';

  @override
  String get speciesDog => 'Dog';

  @override
  String get speciesCat => 'Cat';

  @override
  String get speciesOther => 'Other animal';

  @override
  String get estimatedAgeLabel => 'Estimated age';

  @override
  String get estimatedAgeHint => 'E.g. 3';

  @override
  String get estimatedAgeRequired => 'Enter the estimated age';

  @override
  String get estimatedAgeInvalid => 'Enter a valid number';

  @override
  String get yearsSuffix => 'years';

  @override
  String get breedLabel => 'Breed';

  @override
  String get breedHint => 'Optional';

  @override
  String get sexLabel => 'Sex';

  @override
  String get sexUnknown => 'Not specified';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexMale => 'Male';

  @override
  String get microchipLabel => 'Microchip';

  @override
  String get microchipHint => 'Optional';

  @override
  String get vetNameLabel => 'Veterinarian';

  @override
  String get vetNameHint => 'Optional';

  @override
  String get savePet => 'Save pet';

  @override
  String get petSaved => 'Pet saved';

  @override
  String get loadingPets => 'Loading pets...';

  @override
  String get openPetDashboard => 'Open dashboard';

  @override
  String get petDashboardTitle => 'Pet dashboard';

  @override
  String get petProfileSection => 'Profile';

  @override
  String get petProfileDescription =>
      'Main pet details saved locally on this device.';

  @override
  String get petCareModulesHiddenTitle => 'Pet care modules';

  @override
  String get petCareModulesHiddenDescription =>
      'Reminders, documents, health diary, visits, expenses, insurance and reports will be enabled only when complete and tested.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get petNotFound => 'Pet not found';

  @override
  String get retry => 'Retry';
}
