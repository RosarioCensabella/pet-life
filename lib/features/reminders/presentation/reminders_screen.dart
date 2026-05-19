import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../application/reminder_controller.dart';
import '../domain/reminder.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _ReminderDesignStrings.of(context);
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: remindersState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (reminders) {
            final petReminders = reminders
                .where((reminder) => reminder.petId == petId)
                .toList(growable: false)
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final activeCount = petReminders.where((reminder) {
              return reminder.status == ReminderStatus.active ||
                  reminder.status == ReminderStatus.postponed;
            }).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _TopBar(
                  title: l10n.remindersTitle,
                  onBack: () => context.go('/pets/$petId'),
                ),
                const SizedBox(height: 12),
                _HeroCard(
                  title: l10n.remindersTitle,
                  subtitle: strings.heroSubtitle,
                  count: activeCount,
                  countLabel: strings.active,
                  onAdd: () => context.push('/pets/$petId/reminders/new'),
                  addLabel: l10n.addReminder,
                ),
                const SizedBox(height: 12),
                _DisclaimerCard(text: strings.disclaimer),
                const SizedBox(height: 12),
                if (petReminders.isEmpty)
                  _EmptyRemindersState(
                    title: l10n.noRemindersTitle,
                    description: l10n.noRemindersDescription,
                    buttonLabel: l10n.addReminder,
                    onPressed: () => context.push('/pets/$petId/reminders/new'),
                  )
                else ...[
                  _SectionHeader(
                    title: strings.listTitle,
                    count: petReminders.length,
                  ),
                  const SizedBox(height: 8),
                  ...petReminders.map(
                    (reminder) => _ReminderCard(
                      reminder: reminder,
                      categoryLabel: _categoryLabel(l10n, reminder.category),
                      statusLabel: _statusLabel(l10n, reminder.status),
                      dateLabel: _formatDate(context, reminder.scheduledAt),
                      completeLabel: l10n.completeReminder,
                      postponeLabel: l10n.postponeReminder,
                      skipLabel: l10n.skipReminder,
                      onComplete: () => _completeReminder(
                        context,
                        ref,
                        reminder,
                      ),
                      onPostpone: () => _postponeReminder(
                        context,
                        ref,
                        reminder,
                      ),
                      onSkip: () => _skipReminder(
                        context,
                        ref,
                        reminder,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/pets/$petId/reminders/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addReminder),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pets/$petId/reminders/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addReminder),
      ),
    );
  }

  Future<void> _completeReminder(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await ref
        .read(reminderControllerProvider.notifier)
        .completeReminder(reminder.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderCompleted)),
    );
  }

  Future<void> _postponeReminder(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await ref
        .read(reminderControllerProvider.notifier)
        .postponeReminderByOneDay(reminder.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderPostponed)),
    );
  }

  Future<void> _skipReminder(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    await ref.read(reminderControllerProvider.notifier).skipReminder(
          reminder.id,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderSkipped)),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return dateFormat.format(date);
  }

  String _categoryLabel(AppLocalizations l10n, ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => l10n.reminderCategoryVaccine,
      ReminderCategory.antiparasitic => l10n.reminderCategoryAntiparasitic,
      ReminderCategory.vetVisit => l10n.reminderCategoryVetVisit,
      ReminderCategory.checkup => l10n.reminderCategoryCheckup,
      ReminderCategory.medication => l10n.reminderCategoryMedication,
      ReminderCategory.insurance => l10n.reminderCategoryInsurance,
      ReminderCategory.grooming => l10n.reminderCategoryGrooming,
      ReminderCategory.custom => l10n.reminderCategoryCustom,
    };
  }

  String _statusLabel(AppLocalizations l10n, ReminderStatus status) {
    return switch (status) {
      ReminderStatus.active => l10n.reminderStatusActive,
      ReminderStatus.completed => l10n.reminderStatusCompleted,
      ReminderStatus.postponed => l10n.reminderStatusPostponed,
      ReminderStatus.skipped => l10n.reminderStatusSkipped,
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final strings = _ReminderDesignStrings.of(context);

    return Row(
      children: [
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: strings.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.onAdd,
    required this.addLabel,
  });

  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.primaryBrown,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        boxShadow: [PetLifeDesign.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DarkPill(
                        icon: Icons.schedule_outlined,
                        label: '$count $countLabel',
                      ),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: onAdd,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: PetLifeDesign.primaryBrown,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  addLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: PetLifeDesign.primaryBrown,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: const Color(0xFFF0D6BF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB87841),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PetLifeDesign.softSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRemindersState extends StatelessWidget {
  const _EmptyRemindersState({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PetLifeDesign.infoLilac,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 34,
                color: Color(0xFF9C6ADE),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.categoryLabel,
    required this.statusLabel,
    required this.dateLabel,
    required this.completeLabel,
    required this.postponeLabel,
    required this.skipLabel,
    required this.onComplete,
    required this.onPostpone,
    required this.onSkip,
  });

  final Reminder reminder;
  final String categoryLabel;
  final String statusLabel;
  final String dateLabel;
  final String completeLabel;
  final String postponeLabel;
  final String skipLabel;
  final VoidCallback onComplete;
  final VoidCallback onPostpone;
  final VoidCallback onSkip;

  bool get _canAct {
    return reminder.status == ReminderStatus.active ||
        reminder.status == ReminderStatus.postponed;
  }

  @override
  Widget build(BuildContext context) {
    final notes = reminder.notes?.trim();
    final accentColor = _accentColorForCategory(reminder.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(PetLifeDesign.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _iconForCategory(reminder.category),
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                categoryLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: statusLabel,
                          status: reminder.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          color: PetLifeDesign.secondaryBrown,
                          icon: Icons.schedule_outlined,
                          label: dateLabel,
                        ),
                        _InfoPill(
                          color: accentColor,
                          icon: Icons.pets_outlined,
                          label: reminder.petName,
                        ),
                      ],
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        notes,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_canAct) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: onComplete,
                            child: Text(completeLabel),
                          ),
                          OutlinedButton(
                            onPressed: onPostpone,
                            child: Text(postponeLabel),
                          ),
                          TextButton(
                            onPressed: onSkip,
                            child: Text(skipLabel),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColorForCategory(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => const Color(0xFF72A980),
      ReminderCategory.antiparasitic => const Color(0xFFE49D4F),
      ReminderCategory.vetVisit => const Color(0xFF5A8BB8),
      ReminderCategory.checkup => const Color(0xFF8F7AE5),
      ReminderCategory.medication => const Color(0xFFC85B4A),
      ReminderCategory.insurance => const Color(0xFF7A6B5B),
      ReminderCategory.grooming => const Color(0xFFCC8E4A),
      ReminderCategory.custom => const Color(0xFF9C6ADE),
    };
  }

  IconData _iconForCategory(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => Icons.vaccines_outlined,
      ReminderCategory.antiparasitic => Icons.bug_report_outlined,
      ReminderCategory.vetVisit => Icons.local_hospital_outlined,
      ReminderCategory.checkup => Icons.event_available_outlined,
      ReminderCategory.medication => Icons.medication_outlined,
      ReminderCategory.insurance => Icons.verified_user_outlined,
      ReminderCategory.grooming => Icons.content_cut_outlined,
      ReminderCategory.custom => Icons.notifications_active_outlined,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.status,
  });

  final String label;
  final ReminderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }

  Color _colorForStatus(ReminderStatus status) {
    return switch (status) {
      ReminderStatus.active => PetLifeDesign.success,
      ReminderStatus.completed => PetLifeDesign.secondaryBrown,
      ReminderStatus.postponed => const Color(0xFFE49D4F),
      ReminderStatus.skipped => PetLifeDesign.danger,
    };
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ReminderDesignStrings {
  const _ReminderDesignStrings({
    required this.back,
    required this.heroSubtitle,
    required this.active,
    required this.disclaimer,
    required this.listTitle,
  });

  final String back;
  final String heroSubtitle;
  final String active;
  final String disclaimer;
  final String listTitle;

  static _ReminderDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _ReminderDesignStrings(
        back: 'Back',
        heroSubtitle:
            'Keep important dates visible, calm and easy to manage.',
        active: 'active',
        disclaimer:
            'Reminders are organizational tools only. Pet Life does not provide diagnosis, triage or medical advice.',
        listTitle: 'Reminder list',
      );
    }

    return const _ReminderDesignStrings(
      back: 'Indietro',
      heroSubtitle:
          'Tieni le scadenze importanti visibili, ordinate e facili da gestire.',
      active: 'attivi',
      disclaimer:
          'I promemoria sono strumenti organizzativi. Pet Life non fornisce diagnosi, triage o consigli medici.',
      listTitle: 'Lista promemoria',
    );
  }
}