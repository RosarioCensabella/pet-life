import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_flags_provider.dart';
import '../../../app/theme.dart';
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
    final strings = _SettingsDesignStrings.of(context);
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _TopBar(title: l10n.settingsTitle),
            const SizedBox(height: 12),
            _HeroCard(
              title: l10n.settingsTitle,
              subtitle: strings.heroSubtitle,
              planLabel: planLabel,
              notificationStatusLabel:
                  '${l10n.settingsNotificationsSection}: $notificationStatusLabel',
            ),
            const SizedBox(height: 12),
            _PrivacyNoticeCard(text: strings.privacyNotice),
            const SizedBox(height: 14),
            if (featureFlags.subscriptionModuleEnabled)
              _SettingsSection(
                title: l10n.settingsSubscriptionSection,
                subtitle: strings.subscriptionSubtitle,
                icon: Icons.workspace_premium_outlined,
                color: const Color(0xFFE49D4F),
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
              subtitle: strings.notificationsSubtitle,
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFF5A8BB8),
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
                _InlineNote(
                  icon: Icons.storefront_outlined,
                  text: l10n.notificationPermissionStoreReviewNote,
                ),
              ],
            ),
            _SettingsSection(
              title: l10n.settingsLegalSection,
              subtitle: strings.legalSubtitle,
              icon: Icons.privacy_tip_outlined,
              color: const Color(0xFF72A980),
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  subtitle: strings.privacySubtitle,
                  onTap: () => context.push('/settings/legal/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.article_outlined,
                  title: l10n.termsOfService,
                  subtitle: strings.termsSubtitle,
                  onTap: () => context.push('/settings/legal/terms'),
                ),
                _SettingsTile(
                  icon: Icons.health_and_safety_outlined,
                  title: l10n.medicalDisclaimerTitle,
                  subtitle: strings.medicalDisclaimerSubtitle,
                  onTap: () => context.push('/settings/legal/disclaimer'),
                ),
              ],
            ),
            _SettingsSection(
              title: l10n.settingsDataSection,
              subtitle: strings.dataSubtitle,
              icon: Icons.folder_outlined,
              color: const Color(0xFF9C6ADE),
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
                  isDanger: true,
                  onTap: _isDeleting ? null : _deleteLocalData,
                ),
              ],
            ),
          ],
        ),
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
      NotificationPermissionStatus.granted => l10n.notificationPermissionGranted,
      NotificationPermissionStatus.denied => l10n.notificationPermissionDenied,
      NotificationPermissionStatus.unknown => l10n.notificationPermissionUnknown,
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final strings = _SettingsDesignStrings.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PetLifeDesign.softSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.topSubtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
    required this.planLabel,
    required this.notificationStatusLabel,
  });

  final String title;
  final String subtitle;
  final String planLabel;
  final String notificationStatusLabel;

  @override
  Widget build(BuildContext context) {
    final strings = _SettingsDesignStrings.of(context);

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
                Icons.tune_outlined,
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
                        icon: Icons.workspace_premium_outlined,
                        label: '${strings.plan}: $planLabel',
                      ),
                      _DarkPill(
                        icon: Icons.notifications_active_outlined,
                        label: notificationStatusLabel,
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard({
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
              Icons.lock_outline_rounded,
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isBusy;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDanger ? PetLifeDesign.danger : PetLifeDesign.primaryBrown;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: PetLifeDesign.softSurface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: isDanger
                                      ? PetLifeDesign.danger
                                      : null,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isBusy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onTap == null
                        ? Theme.of(context).disabledColor
                        : PetLifeDesign.secondaryBrown,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
        border: Border.all(color: const Color(0xFFF0D6BF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFFB87841),
            ),
            const SizedBox(width: 10),
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

class _SettingsDesignStrings {
  const _SettingsDesignStrings({
    required this.topSubtitle,
    required this.heroSubtitle,
    required this.plan,
    required this.privacyNotice,
    required this.subscriptionSubtitle,
    required this.notificationsSubtitle,
    required this.legalSubtitle,
    required this.privacySubtitle,
    required this.termsSubtitle,
    required this.medicalDisclaimerSubtitle,
    required this.dataSubtitle,
  });

  final String topSubtitle;
  final String heroSubtitle;
  final String plan;
  final String privacyNotice;
  final String subscriptionSubtitle;
  final String notificationsSubtitle;
  final String legalSubtitle;
  final String privacySubtitle;
  final String termsSubtitle;
  final String medicalDisclaimerSubtitle;
  final String dataSubtitle;

  static _SettingsDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _SettingsDesignStrings(
        topSubtitle: 'Manage privacy, notifications and local data.',
        heroSubtitle:
            'Control your Pet Life experience, notification permissions, legal information and local archive.',
        plan: 'Plan',
        privacyNotice:
            'Pet Life is designed as an organizational tool. Local data, exports and permissions remain under your control.',
        subscriptionSubtitle: 'Manage plan and premium access.',
        notificationsSubtitle:
            'Check permission status and enable reminder notifications.',
        legalSubtitle: 'Read app policies and the non-medical disclaimer.',
        privacySubtitle: 'How Pet Life handles privacy and app data.',
        termsSubtitle: 'Usage rules and service terms.',
        medicalDisclaimerSubtitle:
            'Pet Life does not replace your veterinarian.',
        dataSubtitle: 'Export or delete the local data stored on this device.',
      );
    }

    return const _SettingsDesignStrings(
      topSubtitle: 'Gestisci privacy, notifiche e dati locali.',
      heroSubtitle:
          'Controlla esperienza Pet Life, permessi notifiche, informazioni legali e archivio locale.',
      plan: 'Piano',
      privacyNotice:
          'Pet Life è pensata come strumento organizzativo. Dati locali, export e permessi restano sotto il tuo controllo.',
      subscriptionSubtitle: 'Gestisci piano e accesso premium.',
      notificationsSubtitle:
          'Controlla i permessi e abilita le notifiche dei promemoria.',
      legalSubtitle: 'Consulta policy, termini e disclaimer non medico.',
      privacySubtitle: 'Come Pet Life gestisce privacy e dati app.',
      termsSubtitle: 'Regole di utilizzo e condizioni del servizio.',
      medicalDisclaimerSubtitle:
          'Pet Life non sostituisce il veterinario.',
      dataSubtitle:
          'Esporta o elimina i dati locali salvati su questo dispositivo.',
    );
  }
}