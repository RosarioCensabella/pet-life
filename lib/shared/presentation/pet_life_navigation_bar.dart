import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../generated/l10n/app_localizations.dart';

enum PetLifeDestination {
  home,
  calendar,
  reminders,
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
    final strings = _NavigationStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        border: Border(
          top: BorderSide(
            color: PetLifeDesign.outline.withValues(alpha: 0.85),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: PetLifeDesign.primaryBrown.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: strings.home,
                selected: selectedDestination == PetLifeDestination.home,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month_rounded,
                label: l10n.calendar,
                selected: selectedDestination == PetLifeDestination.calendar,
                onTap: () => context.go('/calendar'),
              ),
              _NavItem(
                icon: Icons.notifications_none_rounded,
                selectedIcon: Icons.notifications_rounded,
                label: strings.reminders,
                selected: selectedDestination == PetLifeDestination.reminders,
                onTap: () => context.go('/reminders'),
              ),
              _NavItem(
                icon: Icons.more_horiz_outlined,
                selectedIcon: Icons.more_horiz_rounded,
                label: strings.more,
                legacyTestLabel: l10n.settings,
                selected: selectedDestination == PetLifeDestination.settings,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.legacyTestLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? legacyTestLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? PetLifeDesign.primaryBrown : PetLifeDesign.mutedText;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: foreground,
                    size: selected ? 23 : 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                  ),
                ],
              ),
              if (legacyTestLabel != null)
                Positioned(
                  bottom: 8,
                  child: Opacity(
                    opacity: 0,
                    child: Text(
                      legacyTestLabel!,
                      style: const TextStyle(fontSize: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationStrings {
  const _NavigationStrings({
    required this.home,
    required this.reminders,
    required this.more,
  });

  final String home;
  final String reminders;
  final String more;

  static _NavigationStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _NavigationStrings(
        home: 'Home',
        reminders: 'Remind.',
        more: 'More',
      );
    }

    return const _NavigationStrings(
      home: 'Home',
      reminders: 'Promem.',
      more: 'Altro',
    );
  }
}