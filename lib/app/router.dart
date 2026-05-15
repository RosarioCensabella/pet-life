import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/calendar_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/pets/presentation/add_pet_screen.dart';
import '../features/pets/presentation/edit_pet_screen.dart';
import '../features/pets/presentation/pet_dashboard_screen.dart';
import '../features/reminders/presentation/add_reminder_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';

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
    ],
  );
}