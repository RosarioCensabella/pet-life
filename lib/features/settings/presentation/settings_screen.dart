import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_flags_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/presentation/pet_life_navigation_bar.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../expenses/application/expense_controller.dart';
import '../../food/application/food_controller.dart';
import '../../health/application/health_controller.dart';
import '../../medications/application/medication_controller.dart';
import '../../pets/application/pet_controller.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../subscription/application/subscription_controller.dart';
import '../../subscription/domain/subscription_plan.dart';
import '../../visits/application/visit_controller.dart';
import '../../weight/application/weight_controller.dart';
import '../application/app_data_service_provider.dart';
import '../application/notification_permission_controller.dart';
import '../domain/notification_permission_status.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

  Future<void> _requestNotificationPermission() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final status = await ref
        .read(notificationPermissionControllerProvider.notifier)
        .requestPermission();

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          status == NotificationPermissionStatus.granted
              ? l10n.notificationPermissionGrantedMessage
              : l10n.notificationPermissionDeniedMessage,
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isExporting = true;
    });

    try {
      final appDataService = await ref.read(appDataServiceProvider.future);
      final result = await appDataService.exportLocalData();

      if (!mounted) {
        return;
      }

      setState(() {
        _isExporting = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.exportReadyTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.exportReadyMessage),
                const SizedBox(height: 12),
                SelectableText(result.filePath),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(dialogContext);

                  await Clipboard.setData(
                    ClipboardData(text: result.filePath),
                  );

                  if (!mounted || !dialogContext.mounted) {
                    return;
                  }

                  navigator.pop();

                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.pathCopied)),
                  );
                },
                child: Text(l10n.copyPath),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted && _isExporting) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _deleteLocalData() async {
    final l10n = AppLocalizations.of(context)!;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteLocalDataConfirmTitle),
          content: Text(l10n.deleteLocalDataConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteAll),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final appDataService = await ref.read(appDataServiceProvider.future);
      await appDataService.clearLocalData();

      ref.invalidate(petControllerProvider);
      ref.invalidate(reminderControllerProvider);
      ref.invalidate(petDocumentControllerProvider);
      ref.invalidate(weightControllerProvider);
      ref.invalidate(healthControllerProvider);
      ref.invalidate(foodControllerProvider);
      ref.invalidate(medicationControllerProvider);
      ref.invalidate(visitControllerProvider);
      ref.invalidate(expenseControllerProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.localDataDeleted)),
      );

      context.go('/home');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final featureFlags = ref.watch(featureFlagsProvider);
    final subscriptionStatus = ref.watch(subscriptionControllerProvider);
    final notificationPermissionState =
        ref.watch(notificationPermissionControllerProvider);

    final planLabel = subscriptionStatus.currentTier == SubscriptionTier.premium
        ? l10n.premiumPlan
        : l10n.freePlan;

    final notificationStatusLabel = notificationPermissionState.when(
      data: (status) => _notificationStatusLabel(l10n, status),
      error: (error, stackTrace) => l10n.notificationPermissionUnknown,
      loading: () => l10n.notificationPermissionUnknown,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (featureFlags.subscriptionModuleEnabled)
            _SettingsSection(
              title: l10n.settingsSubscriptionSection,
              children: [
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.viewPremium,
                  subtitle: '${l10n.currentPlan}: $planLabel',
                  onTap: () => context.push('/subscription'),
                ),
              ],
            ),
          _SettingsSection(
            title: l10n.settingsNotificationsSection,
            children: [
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.notificationPermissionStatus,
                subtitle: notificationStatusLabel,
                onTap: () => ref
                    .read(notificationPermissionControllerProvider.notifier)
                    .loadStatus(),
              ),
              _SettingsTile(
                icon: Icons.notification_add_outlined,
                title: l10n.requestNotificationPermission,
                subtitle: l10n.notificationPermissionDescription,
                isBusy: notificationPermissionState.isLoading,
                onTap: notificationPermissionState.isLoading
                    ? null
                    : _requestNotificationPermission,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  l10n.notificationPermissionStoreReviewNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsLegalSection,
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => context.push('/settings/legal/privacy'),
              ),
              _SettingsTile(
                icon: Icons.article_outlined,
                title: l10n.termsOfService,
                onTap: () => context.push('/settings/legal/terms'),
              ),
              _SettingsTile(
                icon: Icons.health_and_safety_outlined,
                title: l10n.medicalDisclaimerTitle,
                onTap: () => context.push('/settings/legal/disclaimer'),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsDataSection,
            children: [
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: l10n.exportData,
                subtitle: l10n.exportDataDescription,
                isBusy: _isExporting,
                onTap: _isExporting ? null : _exportData,
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: l10n.deleteLocalData,
                subtitle: l10n.deleteLocalDataDescription,
                isBusy: _isDeleting,
                onTap: _isDeleting ? null : _deleteLocalData,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const PetLifeNavigationBar(
        selectedDestination: PetLifeDestination.settings,
      ),
    );
  }

  String _notificationStatusLabel(
    AppLocalizations l10n,
    NotificationPermissionStatus status,
  ) {
    return switch (status) {
      NotificationPermissionStatus.granted =>
        l10n.notificationPermissionGranted,
      NotificationPermissionStatus.denied => l10n.notificationPermissionDenied,
      NotificationPermissionStatus.unknown =>
        l10n.notificationPermissionUnknown,
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isBusy = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: isBusy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}