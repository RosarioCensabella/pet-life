import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/calendar_screen.dart';
import '../features/documents/presentation/add_document_screen.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/food/presentation/food_screen.dart';
import '../features/health/domain/health_entry.dart';
import '../features/health/presentation/health_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/medications/presentation/medications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/pets/presentation/add_pet_screen.dart';
import '../features/pets/presentation/edit_pet_screen.dart';
import '../features/pets/presentation/pet_dashboard_screen.dart';
import '../features/reminders/presentation/add_reminder_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/settings/presentation/legal_document_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/subscription/presentation/paywall_screen.dart';
import '../features/weight/presentation/weight_screen.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/legal/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'privacy';

          return LegalDocumentScreen(type: type);
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/pets/new',
        builder: (context, state) => const AddPetScreen(),
      ),
      GoRoute(
        path: '/pets/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return PetDashboardScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/edit',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return EditPetScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/reminders',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return RemindersScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/reminders/new',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return AddReminderScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/documents',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return DocumentsScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/documents/new',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return AddDocumentScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/weight',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return WeightScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/health-diary',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return HealthScreen(
            petId: petId,
            initialType: HealthEntryType.diary,
          );
        },
      ),
      GoRoute(
        path: '/pets/:petId/symptoms',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return HealthScreen(
            petId: petId,
            initialType: HealthEntryType.symptom,
          );
        },
      ),
      GoRoute(
        path: '/pets/:petId/food',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return FoodScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pets/:petId/medications',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;

          return MedicationsScreen(petId: petId);
        },
      ),
    ],
  );
}