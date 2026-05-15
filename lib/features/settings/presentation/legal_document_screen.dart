import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.type,
    super.key,
  });

  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final document = _legalDocument(l10n, type);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            document.icon,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            document.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  _LegalDocument _legalDocument(AppLocalizations l10n, String type) {
    return switch (type) {
      'terms' => _LegalDocument(
          title: l10n.termsOfService,
          body: l10n.termsOfServiceBody,
          icon: Icons.article_outlined,
        ),
      'disclaimer' => _LegalDocument(
          title: l10n.medicalDisclaimerTitle,
          body: l10n.medicalDisclaimerBody,
          icon: Icons.health_and_safety_outlined,
        ),
      _ => _LegalDocument(
          title: l10n.privacyPolicy,
          body: l10n.privacyPolicyBody,
          icon: Icons.privacy_tip_outlined,
        ),
    };
  }
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}