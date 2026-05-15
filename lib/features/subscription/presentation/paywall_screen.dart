import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/feature_flags_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final featureFlags = ref.watch(featureFlagsProvider);
    final storeActionsEnabled = featureFlags.storePurchaseActionsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.paywallTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.paywallSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _BenefitTile(text: l10n.premiumBenefitUnlimitedPets),
          _BenefitTile(text: l10n.premiumBenefitAdvancedReports),
          _BenefitTile(text: l10n.premiumBenefitDocumentArchive),
          _BenefitTile(text: l10n.premiumBenefitSmartReminders),
          const SizedBox(height: 24),
          _PlanCard(
            title: l10n.monthlyPlan,
            price: l10n.premiumMonthlyPrice,
          ),
          _PlanCard(
            title: l10n.annualPlan,
            price: l10n.premiumAnnualPrice,
            badge: l10n.bestValue,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.subscriptionDisclaimer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (storeActionsEnabled) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {},
              child: Text(l10n.premiumPlan),
            ),
            TextButton(
              onPressed: () {},
              child: Text(l10n.restorePurchases),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(text),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    this.badge,
  });

  final String title;
  final String price;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text(badge!)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
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