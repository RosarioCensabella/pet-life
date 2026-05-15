import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final remindersState = ref.watch(reminderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.remindersTitle),
      ),
      body: remindersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (reminders) {
          final petReminders = reminders
              .where((reminder) => reminder.petId == petId)
              .toList(growable: false);

          if (petReminders.isEmpty) {
            return _EmptyRemindersState(
              title: l10n.noRemindersTitle,
              description: l10n.noRemindersDescription,
              buttonLabel: l10n.addReminder,
              onPressed: () => context.push('/pets/$petId/reminders/new'),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ...petReminders.map(
                (reminder) => _ReminderCard(
                  reminder: reminder,
                  categoryLabel: _categoryLabel(l10n, reminder.category),
                  statusLabel: _statusLabel(l10n, reminder.status),
                  dateLabel: _formatDate(context, reminder.scheduledAt),
                  completeLabel: l10n.completeReminder,
                  postponeLabel: l10n.postponeReminder,
                  skipLabel: l10n.skipReminder,
                  onComplete: () => _completeReminder(context, ref, reminder),
                  onPostpone: () => _postponeReminder(context, ref, reminder),
                  onSkip: () => _skipReminder(context, ref, reminder),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/pets/$petId/reminders/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addReminder),
                ),
              ),
            ],
          );
        },
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
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 8),
            Text(categoryLabel),
            Text(dateLabel),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes),
            ],
            if (_canAct) ...[
              const SizedBox(height: 16),
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
    );
  }
}