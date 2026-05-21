import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../application/reminder_controller.dart';
import '../domain/reminder.dart';

enum _ReminderFilter {
  active,
  completed,
  all,
}

enum _ReminderAction {
  complete,
  postpone,
  skip,
}

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({
    this.petId,
    super.key,
  });

  final String? petId;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  _ReminderFilter _filter = _ReminderFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _ReminderDesignStrings.of(context);
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      backgroundColor: _ReminderPalette.background,
      body: SafeArea(
        child: remindersState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (reminders) {
            final visibleSource = widget.petId == null
                ? reminders
                : reminders
                    .where((reminder) => reminder.petId == widget.petId)
                    .toList(growable: false);

            final sortedReminders = [...visibleSource]
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final activeCount = sortedReminders
                .where((reminder) => reminder.status == ReminderStatus.active)
                .length;

            final filteredReminders = _filteredReminders(sortedReminders);

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                _ReminderHeader(
                  title: l10n.remindersTitle,
                  subtitle: widget.petId == null
                      ? '$activeCount ${strings.active} · tutti gli animali'
                      : '$activeCount ${strings.active}',
                  addLabel: l10n.addReminder,
                  onAdd: _openAddReminder,
                ),
                const SizedBox(height: 12),
                _FilterRow(
                  selectedFilter: _filter,
                  strings: strings,
                  onChanged: (filter) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                ),
                const SizedBox(height: 14),
                if (filteredReminders.isEmpty)
                  _EmptyReminderList(
                    title: _emptyTitle(l10n, strings),
                    description: _emptyDescription(l10n, strings),
                    buttonLabel: l10n.addReminder,
                    onAdd: _openAddReminder,
                  )
                else
                  ...filteredReminders.map(
                    (reminder) => _ReminderTile(
                      reminder: reminder,
                      dateLabel: _formatDate(context, reminder.scheduledAt),
                      postponedLabel: _statusLabel(
                        l10n,
                        ReminderStatus.postponed,
                      ).toLowerCase(),
                      completedLabel: _statusLabel(
                        l10n,
                        ReminderStatus.completed,
                      ).toLowerCase(),
                      skippedLabel: _statusLabel(
                        l10n,
                        ReminderStatus.skipped,
                      ).toLowerCase(),
                      completeLabel: l10n.completeReminder,
                      postponeLabel: l10n.postponeReminder,
                      skipLabel: l10n.skipReminder,
                      onActionSelected: (action) {
                        switch (action) {
                          case _ReminderAction.complete:
                            _completeReminder(reminder);
                          case _ReminderAction.postpone:
                            _postponeReminder(reminder);
                          case _ReminderAction.skip:
                            _skipReminder(reminder);
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _ReminderBottomNavigation(),
    );
  }

  List<Reminder> _filteredReminders(List<Reminder> reminders) {
    return switch (_filter) {
      _ReminderFilter.active => reminders
          .where((reminder) => reminder.status == ReminderStatus.active)
          .toList(growable: false),
      _ReminderFilter.completed => reminders
          .where((reminder) => reminder.status != ReminderStatus.active)
          .toList(growable: false),
      _ReminderFilter.all => reminders,
    };
  }

  String _emptyTitle(AppLocalizations l10n, _ReminderDesignStrings strings) {
    return switch (_filter) {
      _ReminderFilter.active => l10n.noRemindersTitle,
      _ReminderFilter.completed => strings.noCompletedTitle,
      _ReminderFilter.all => l10n.noRemindersTitle,
    };
  }

  String _emptyDescription(
    AppLocalizations l10n,
    _ReminderDesignStrings strings,
  ) {
    return switch (_filter) {
      _ReminderFilter.active => l10n.noRemindersDescription,
      _ReminderFilter.completed => strings.noCompletedDescription,
      _ReminderFilter.all => l10n.noRemindersDescription,
    };
  }

  void _openAddReminder() {
    final petId = widget.petId;

    if (petId == null) {
      context.push('/reminders/new');
      return;
    }

    context.push('/pets/$petId/reminders/new');
  }

  Future<void> _completeReminder(Reminder reminder) async {
    final l10n = AppLocalizations.of(context)!;

    await ref
        .read(reminderControllerProvider.notifier)
        .completeReminder(reminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderCompleted)),
    );
  }

  Future<void> _postponeReminder(Reminder reminder) async {
    final l10n = AppLocalizations.of(context)!;

    await ref
        .read(reminderControllerProvider.notifier)
        .postponeReminderByOneDay(reminder.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderPostponed)),
    );
  }

  Future<void> _skipReminder(Reminder reminder) async {
    final l10n = AppLocalizations.of(context)!;

    await ref.read(reminderControllerProvider.notifier).skipReminder(
          reminder.id,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.reminderSkipped)),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('EEE d MMM', locale).format(date);
    final timeLabel = DateFormat.Hm(locale).format(date);

    return '${_capitalize(dayLabel)} · $timeLabel';
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

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader({
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: _ReminderPalette.darkText,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ReminderPalette.secondaryText,
                    ),
              ),
            ],
          ),
        ),
        Material(
          color: _ReminderPalette.chip,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAdd,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 23,
                    color: _ReminderPalette.darkText,
                  ),
                  Opacity(
                    opacity: 0,
                    child: Text(addLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedFilter,
    required this.strings,
    required this.onChanged,
  });

  final _ReminderFilter selectedFilter;
  final _ReminderDesignStrings strings;
  final ValueChanged<_ReminderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: strings.activePlural,
          selected: selectedFilter == _ReminderFilter.active,
          onTap: () => onChanged(_ReminderFilter.active),
        ),
        const SizedBox(width: 7),
        _FilterChipButton(
          label: strings.completedPlural,
          selected: selectedFilter == _ReminderFilter.completed,
          onTap: () => onChanged(_ReminderFilter.completed),
        ),
        const SizedBox(width: 7),
        _FilterChipButton(
          label: strings.all,
          selected: selectedFilter == _ReminderFilter.all,
          onTap: () => onChanged(_ReminderFilter.all),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        selected ? _ReminderPalette.darkText : _ReminderPalette.chip;
    final foreground = selected ? Colors.white : _ReminderPalette.secondaryText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.dateLabel,
    required this.postponedLabel,
    required this.completedLabel,
    required this.skippedLabel,
    required this.completeLabel,
    required this.postponeLabel,
    required this.skipLabel,
    required this.onActionSelected,
  });

  final Reminder reminder;
  final String dateLabel;
  final String postponedLabel;
  final String completedLabel;
  final String skippedLabel;
  final String completeLabel;
  final String postponeLabel;
  final String skipLabel;
  final ValueChanged<_ReminderAction> onActionSelected;

  bool get _isCompleted {
    return reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.skipped;
  }

  bool get _canComplete {
    return reminder.status == ReminderStatus.active ||
        reminder.status == ReminderStatus.postponed;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColorForCategory(reminder.category);
    final rowOpacity = _isCompleted ? 0.56 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _ReminderPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ReminderPalette.outline),
        boxShadow: [
          BoxShadow(
            color: _ReminderPalette.darkText.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  _StatusCircle(
                    status: reminder.status,
                    accent: accent,
                    canComplete: _canComplete,
                    onTap: _canComplete
                        ? () => onActionSelected(_ReminderAction.complete)
                        : null,
                  ),
                  const SizedBox(width: 11),
                  Opacity(
                    opacity: rowOpacity,
                    child: _CategoryIcon(
                      category: reminder.category,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: rowOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 1.12,
                                  fontWeight: FontWeight.w900,
                                  color: _ReminderPalette.darkText,
                                  decoration: _isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationThickness: 1.8,
                                  decorationColor:
                                      _ReminderPalette.secondaryText,
                                ),
                          ),
                          const SizedBox(height: 4),
                          _ReminderMetaLine(
                            petName: reminder.petName,
                            dateLabel: dateLabel,
                            status: reminder.status,
                            postponedLabel: postponedLabel,
                            completedLabel: completedLabel,
                            skippedLabel: skippedLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MoreButton(
                    completeLabel: completeLabel,
                    postponeLabel: postponeLabel,
                    skipLabel: skipLabel,
                    canComplete: _canComplete,
                    onSelected: onActionSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColorForCategory(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => const Color(0xFFF3A83B),
      ReminderCategory.antiparasitic => const Color(0xFFF3A83B),
      ReminderCategory.vetVisit => const Color(0xFF80B894),
      ReminderCategory.checkup => const Color(0xFF80B894),
      ReminderCategory.medication => const Color(0xFFA876E8),
      ReminderCategory.insurance => const Color(0xFF7E8EA3),
      ReminderCategory.grooming => const Color(0xFFF3A83B),
      ReminderCategory.custom => const Color(0xFFA876E8),
    };
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({
    required this.status,
    required this.accent,
    required this.canComplete,
    required this.onTap,
  });

  final ReminderStatus status;
  final Color accent;
  final bool canComplete;
  final VoidCallback? onTap;

  bool get _isDone {
    return status == ReminderStatus.completed ||
        status == ReminderStatus.skipped;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _isDone ? accent.withValues(alpha: 0.62) : Colors.white;
    final borderColor =
        _isDone ? Colors.transparent : _ReminderPalette.outlineStrong;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: _isDone
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 15,
                )
              : null,
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.category,
    required this.accent,
  });

  final ReminderCategory category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _iconForCategory(category),
        color: accent,
        size: 17,
      ),
    );
  }

  IconData _iconForCategory(ReminderCategory category) {
    return switch (category) {
      ReminderCategory.vaccine => Icons.health_and_safety_outlined,
      ReminderCategory.antiparasitic => Icons.water_drop_outlined,
      ReminderCategory.vetVisit => Icons.medical_services_outlined,
      ReminderCategory.checkup => Icons.health_and_safety_outlined,
      ReminderCategory.medication => Icons.medication_outlined,
      ReminderCategory.insurance => Icons.verified_user_outlined,
      ReminderCategory.grooming => Icons.content_cut_outlined,
      ReminderCategory.custom => Icons.notifications_active_outlined,
    };
  }
}

class _ReminderMetaLine extends StatelessWidget {
  const _ReminderMetaLine({
    required this.petName,
    required this.dateLabel,
    required this.status,
    required this.postponedLabel,
    required this.completedLabel,
    required this.skippedLabel,
  });

  final String petName;
  final String dateLabel;
  final ReminderStatus status;
  final String postponedLabel;
  final String completedLabel;
  final String skippedLabel;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (status) {
      ReminderStatus.postponed => postponedLabel,
      ReminderStatus.completed => completedLabel,
      ReminderStatus.skipped => skippedLabel,
      ReminderStatus.active => null,
    };

    return Wrap(
      spacing: 5,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          petName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.15,
                color: _ReminderPalette.secondaryText,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          '·',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.15,
                color: _ReminderPalette.secondaryText,
              ),
        ),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                height: 1.15,
                color: _ReminderPalette.secondaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (statusText != null) ...[
          Text(
            '·',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.15,
                  color: _ReminderPalette.secondaryText,
                ),
          ),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.15,
                  color: status == ReminderStatus.postponed
                      ? _ReminderPalette.postponed
                      : _ReminderPalette.secondaryText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({
    required this.completeLabel,
    required this.postponeLabel,
    required this.skipLabel,
    required this.canComplete,
    required this.onSelected,
  });

  final String completeLabel;
  final String postponeLabel;
  final String skipLabel;
  final bool canComplete;
  final ValueChanged<_ReminderAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReminderAction>(
      tooltip: 'Azioni',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return [
          if (canComplete)
            PopupMenuItem(
              value: _ReminderAction.complete,
              child: Text(completeLabel),
            ),
          if (canComplete)
            PopupMenuItem(
              value: _ReminderAction.postpone,
              child: Text(postponeLabel),
            ),
          PopupMenuItem(
            value: _ReminderAction.skip,
            child: Text(skipLabel),
          ),
        ];
      },
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _ReminderPalette.chip,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: _ReminderPalette.darkText,
        ),
      ),
    );
  }
}

class _EmptyReminderList extends StatelessWidget {
  const _EmptyReminderList({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onAdd,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ReminderPalette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ReminderPalette.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: _ReminderPalette.secondaryText,
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _ReminderPalette.darkText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _ReminderPalette.secondaryText,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderBottomNavigation extends StatelessWidget {
  const _ReminderBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/calendar');
          case 2:
            context.go('/reminders');
          case 3:
            context.go('/settings');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Calendario',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_rounded),
          label: 'Promem.',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz_rounded),
          selectedIcon: Icon(Icons.more_horiz_rounded),
          label: 'Altro',
        ),
      ],
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
          style: const TextStyle(color: _ReminderPalette.darkText),
        ),
      ),
    );
  }
}

class _ReminderPalette {
  const _ReminderPalette._();

  static const background = Color(0xFFF8F1E2);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF3E8D1);
  static const outline = Color(0xFFE3D2B4);
  static const outlineStrong = Color(0xFFE0C89D);

  static const darkText = Color(0xFF2D2418);
  static const secondaryText = Color(0xFF8B7A63);
  static const postponed = Color(0xFFA876E8);
}

class _ReminderDesignStrings {
  const _ReminderDesignStrings({
    required this.active,
    required this.activePlural,
    required this.completedPlural,
    required this.all,
    required this.noCompletedTitle,
    required this.noCompletedDescription,
  });

  final String active;
  final String activePlural;
  final String completedPlural;
  final String all;
  final String noCompletedTitle;
  final String noCompletedDescription;

  static _ReminderDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _ReminderDesignStrings(
        active: 'active',
        activePlural: 'Active',
        completedPlural: 'Completed',
        all: 'All',
        noCompletedTitle: 'No completed reminders',
        noCompletedDescription:
            'Completed, postponed or skipped reminders will appear here.',
      );
    }

    return const _ReminderDesignStrings(
      active: 'attivi',
      activePlural: 'Attivi',
      completedPlural: 'Completati',
      all: 'Tutti',
      noCompletedTitle: 'Nessun promemoria completato',
      noCompletedDescription:
          'Qui vedrai i promemoria completati, rimandati o saltati.',
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}