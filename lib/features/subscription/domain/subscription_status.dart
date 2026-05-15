import 'subscription_plan.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.currentTier,
    required this.isStoreConfigured,
    this.activePlanId,
    this.expiresAt,
  });

  final SubscriptionTier currentTier;
  final bool isStoreConfigured;
  final String? activePlanId;
  final DateTime? expiresAt;

  bool get isPremium => currentTier == SubscriptionTier.premium;

  static const free = SubscriptionStatus(
    currentTier: SubscriptionTier.free,
    isStoreConfigured: false,
  );
}