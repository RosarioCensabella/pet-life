import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../generated/l10n/app_localizations.dart';

enum PetLifeDestination {
  home,
  calendar,
  settings,
}

class PetLifeNavigationBar extends StatelessWidget {
  const PetLifeNavigationBar({
    required this.selectedDestination,
    super.key,
  });

  final PetLifeDestination selectedDestination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      selectedIndex: selectedDestination.index,
      onDestinationSelected: (index) {
        final destination = PetLifeDestination.values[index];

        switch (destination) {
          case PetLifeDestination.home:
            context.go('/home');
          case PetLifeDestination.calendar:
            context.go('/calendar');
          case PetLifeDestination.settings:
            context.go('/settings');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.homeTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: l10n.calendar,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}