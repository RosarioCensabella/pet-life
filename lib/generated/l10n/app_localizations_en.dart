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
}
