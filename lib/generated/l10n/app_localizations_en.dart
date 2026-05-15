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
  String get petUpdated => 'Pet updated';

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
  String get backToHome => 'Back to Home';

  @override
  String get petNotFound => 'Pet not found';

  @override
  String get retry => 'Retry';

  @override
  String get editPet => 'Edit pet';

  @override
  String get archivePet => 'Archive pet';

  @override
  String get archivePetConfirmTitle => 'Archive this pet?';

  @override
  String get archivePetConfirmMessage =>
      'The pet will no longer be visible on Home and future reminders will be disabled in upcoming phases. Data remains stored for consultation and export.';

  @override
  String get cancel => 'Cancel';

  @override
  String get archive => 'Archive';

  @override
  String get petArchived => 'Pet archived';

  @override
  String get activeProfile => 'Active profile';

  @override
  String get archivedProfile => 'Archived profile';

  @override
  String get petActions => 'Profile actions';

  @override
  String get petActionsDescription =>
      'You can update the pet’s main details or archive it if you no longer want to see it on Home.';

  @override
  String get noActivePetsTitle => 'No active pets';

  @override
  String get noActivePetsDescription =>
      'Add a pet to start organizing information, documents and reminders.';

  @override
  String get petDashboardChooseAction => 'What would you like to do?';

  @override
  String get moduleProfileTitle => 'Profile';

  @override
  String get moduleProfileDescription =>
      'Edit details, species, age, microchip and veterinarian.';

  @override
  String get moduleRemindersTitle => 'Reminders';

  @override
  String get moduleRemindersDescription =>
      'Manage due dates and recurring pet care tasks.';

  @override
  String get moduleDocumentsTitle => 'Documents';

  @override
  String get moduleHealthDiaryTitle => 'Health diary';

  @override
  String get moduleWeightTitle => 'Weight';

  @override
  String get moduleFoodTitle => 'Food';

  @override
  String get moduleSymptomsTitle => 'Symptoms';

  @override
  String get moduleMedicationsTitle => 'Medications';

  @override
  String get moduleVisitsTitle => 'Visits';

  @override
  String get moduleExpensesTitle => 'Expenses';

  @override
  String get moduleInsuranceTitle => 'Insurance';

  @override
  String get moduleReportsTitle => 'Reports';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get addReminder => 'Add reminder';

  @override
  String get addReminderTitle => 'New reminder';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get reminderTitleHint => 'E.g. Annual vaccine';

  @override
  String get reminderTitleRequired => 'Enter a title';

  @override
  String get reminderCategoryLabel => 'Category';

  @override
  String get reminderDateLabel => 'Date';

  @override
  String get reminderTimeLabel => 'Time';

  @override
  String get reminderNotesLabel => 'Notes';

  @override
  String get reminderNotesHint => 'Optional';

  @override
  String get saveReminder => 'Save reminder';

  @override
  String get reminderSaved => 'Reminder saved';

  @override
  String get noRemindersTitle => 'No reminders';

  @override
  String get noRemindersDescription =>
      'Add a due date to remember visits, vaccines, antiparasitics, medications or pet care tasks.';

  @override
  String get reminderCategoryVaccine => 'Vaccine';

  @override
  String get reminderCategoryAntiparasitic => 'Antiparasitic';

  @override
  String get reminderCategoryVetVisit => 'Vet visit';

  @override
  String get reminderCategoryCheckup => 'Checkup';

  @override
  String get reminderCategoryMedication => 'Medication';

  @override
  String get reminderCategoryInsurance => 'Insurance';

  @override
  String get reminderCategoryGrooming => 'Grooming';

  @override
  String get reminderCategoryCustom => 'Custom';

  @override
  String get reminderStatusActive => 'Active';

  @override
  String get reminderStatusCompleted => 'Completed';

  @override
  String get reminderStatusPostponed => 'Postponed';

  @override
  String get reminderStatusSkipped => 'Skipped';

  @override
  String get completeReminder => 'Complete';

  @override
  String get postponeReminder => 'Postpone 1 day';

  @override
  String get skipReminder => 'Skip';

  @override
  String get reminderCompleted => 'Reminder completed';

  @override
  String get reminderPostponed => 'Reminder postponed';

  @override
  String get reminderSkipped => 'Reminder skipped';
}
