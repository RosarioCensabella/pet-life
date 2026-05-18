class FeatureFlags {
  const FeatureFlags({
    required this.petProfileModuleEnabled,
    required this.remindersModuleEnabled,
    required this.documentsModuleEnabled,
    required this.healthDiaryModuleEnabled,
    required this.weightModuleEnabled,
    required this.foodModuleEnabled,
    required this.symptomsModuleEnabled,
    required this.medicationsModuleEnabled,
    required this.visitsModuleEnabled,
    required this.expensesModuleEnabled,
    required this.insuranceModuleEnabled,
    required this.reportsModuleEnabled,
    required this.subscriptionModuleEnabled,
    required this.storePurchaseActionsEnabled,
  });

  final bool petProfileModuleEnabled;
  final bool remindersModuleEnabled;
  final bool documentsModuleEnabled;
  final bool healthDiaryModuleEnabled;
  final bool weightModuleEnabled;
  final bool foodModuleEnabled;
  final bool symptomsModuleEnabled;
  final bool medicationsModuleEnabled;
  final bool visitsModuleEnabled;
  final bool expensesModuleEnabled;
  final bool insuranceModuleEnabled;
  final bool reportsModuleEnabled;
  final bool subscriptionModuleEnabled;
  final bool storePurchaseActionsEnabled;
}

const defaultFeatureFlags = FeatureFlags(
  petProfileModuleEnabled: true,
  remindersModuleEnabled: true,
  documentsModuleEnabled: true,
  healthDiaryModuleEnabled: false,
  weightModuleEnabled: true,
  foodModuleEnabled: false,
  symptomsModuleEnabled: false,
  medicationsModuleEnabled: false,
  visitsModuleEnabled: false,
  expensesModuleEnabled: false,
  insuranceModuleEnabled: false,
  reportsModuleEnabled: false,
  subscriptionModuleEnabled: true,
  storePurchaseActionsEnabled: false,
);