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
  String get moduleDocumentsDescription =>
      'Archive reports, records, prescriptions and insurance files.';

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

  @override
  String get upcomingRemindersTitle => 'Upcoming due dates';

  @override
  String get noUpcomingReminders => 'No upcoming due dates';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarEmptyTitle => 'No due dates in calendar';

  @override
  String get calendarEmptyDescription =>
      'Create a reminder from a pet profile to see it here.';

  @override
  String get allPets => 'All pets';

  @override
  String get filterByPet => 'Filter by pet';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get addDocument => 'Add document';

  @override
  String get addDocumentTitle => 'New document';

  @override
  String get documentTitleLabel => 'Document title';

  @override
  String get documentTitleHint => 'E.g. Vaccination booklet';

  @override
  String get documentTitleRequired => 'Enter a title';

  @override
  String get documentCategoryLabel => 'Category';

  @override
  String get documentCategoryHealthRecord => 'Health record';

  @override
  String get documentCategoryLabReport => 'Lab report';

  @override
  String get documentCategoryPrescription => 'Prescription';

  @override
  String get documentCategoryInsurance => 'Insurance';

  @override
  String get documentCategoryInvoice => 'Invoice';

  @override
  String get documentCategoryOther => 'Other';

  @override
  String get selectDocumentFile => 'Select file';

  @override
  String get selectedDocumentFile => 'Selected file';

  @override
  String get documentFileRequired => 'Select a file';

  @override
  String get documentNotesLabel => 'Notes';

  @override
  String get documentNotesHint => 'Optional';

  @override
  String get saveDocument => 'Save document';

  @override
  String get documentSaved => 'Document saved';

  @override
  String get noDocumentsTitle => 'No documents';

  @override
  String get noDocumentsDescription =>
      'Archive useful files such as health records, lab reports, prescriptions, invoices or insurance documents.';

  @override
  String get openDocument => 'Open';

  @override
  String get deleteDocument => 'Delete';

  @override
  String get deleteDocumentConfirmTitle => 'Delete this document?';

  @override
  String get deleteDocumentConfirmMessage =>
      'The document will be removed from Pet Life’s local archive.';

  @override
  String get documentDeleted => 'Document deleted';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLegalSection => 'Legal information';

  @override
  String get settingsDataSection => 'Data management';

  @override
  String get settingsSubscriptionSection => 'Subscription';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get medicalDisclaimerTitle => 'Medical-veterinary disclaimer';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataDescription =>
      'Create a JSON file with local data, pets, reminders and documents.';

  @override
  String get exportReadyTitle => 'Export complete';

  @override
  String get exportReadyMessage =>
      'The JSON file was created at this local path:';

  @override
  String get copyPath => 'Copy path';

  @override
  String get pathCopied => 'Path copied';

  @override
  String get deleteLocalData => 'Delete local data';

  @override
  String get deleteLocalDataDescription =>
      'Removes pets, reminders, documents and archived files from this device.';

  @override
  String get deleteLocalDataConfirmTitle => 'Delete all local data?';

  @override
  String get deleteLocalDataConfirmMessage =>
      'This action removes all data saved on this device. It cannot be undone.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get localDataDeleted => 'Local data deleted';

  @override
  String get ok => 'OK';

  @override
  String get privacyPolicyBody =>
      'Pet Life stores user-entered data mainly on the device. Data may include pet profiles, reminders, local documents, notes and organizational information. This version does not create a cloud account. The user can export local data as JSON and delete it from the device in Settings. Pet Life does not sell personal data and does not use data to provide diagnoses, triage, prescriptions or medical advice.';

  @override
  String get termsOfServiceBody =>
      'Pet Life is provided as an intelligent diary, organizer and document archive for pet care. The user is responsible for the accuracy of the data entered and how saved information is used. The app does not replace a veterinarian and must not be used for emergencies, diagnoses, prescriptions or clinical decisions. Reminder and archive features are organizational tools.';

  @override
  String get medicalDisclaimerBody =>
      'Pet Life does not provide medical or veterinary diagnoses, triage, prescriptions, treatments, dosages or clinical advice. Information saved in the app is only used to organize the pet’s life and prepare better for visits. For concerning symptoms, health doubts, medications, dosages or emergencies, always contact your veterinarian.';

  @override
  String get notificationPermissionStatus => 'Notification permission status';

  @override
  String get notificationPermissionGranted => 'Enabled';

  @override
  String get notificationPermissionDenied => 'Disabled';

  @override
  String get notificationPermissionUnknown => 'Not checked';

  @override
  String get requestNotificationPermission => 'Enable notifications';

  @override
  String get notificationPermissionDescription =>
      'Pet Life uses notifications only to remind you about reminders and due dates you created.';

  @override
  String get notificationPermissionGrantedMessage => 'Notifications enabled';

  @override
  String get notificationPermissionDeniedMessage =>
      'Notifications not enabled. You can enable them from system settings.';

  @override
  String get notificationPermissionStoreReviewNote =>
      'Pet Life does not send promotional notifications in this version.';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get currentPlan => 'Current plan';

  @override
  String get freePlan => 'Free';

  @override
  String get premiumPlan => 'Premium';

  @override
  String get premiumMonthlyPrice => '€3.99/month';

  @override
  String get premiumAnnualPrice => '€29.99/year';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get viewPremium => 'Explore Premium';

  @override
  String get paywallTitle => 'Pet Life Premium';

  @override
  String get paywallSubtitle =>
      'More space and advanced tools to better organize your pet’s life.';

  @override
  String get premiumBenefitUnlimitedPets => 'More pets and organized archive';

  @override
  String get premiumBenefitAdvancedReports =>
      'Advanced reports to prepare vet visits';

  @override
  String get premiumBenefitDocumentArchive => 'More complete document archive';

  @override
  String get premiumBenefitSmartReminders => 'Smart reminders and summaries';

  @override
  String get monthlyPlan => 'Monthly';

  @override
  String get annualPlan => 'Annual';

  @override
  String get bestValue => 'Best value';

  @override
  String get storePurchasesNotEnabled =>
      'Store purchases are not enabled in this build yet.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get subscriptionDisclaimer =>
      'Pet Life Premium improves organization, archive and reports. It does not add diagnoses, triage, prescriptions or dosage calculation.';
}
