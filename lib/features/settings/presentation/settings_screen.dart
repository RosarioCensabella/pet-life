import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../shared/presentation/pet_life_navigation_bar.dart';
import '../../documents/application/pet_document_controller.dart';
import '../../pets/application/pet_controller.dart';
import '../../reminders/application/reminder_controller.dart';
import '../application/app_data_service_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isDeleting = false;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
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