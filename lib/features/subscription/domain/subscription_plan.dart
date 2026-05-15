enum SubscriptionTier {
  free,
  premium,
}

enum BillingPeriod {
  free,
  monthly,
  annual,
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.billingPeriod,
    required this.priceLabel,
    required this.storeProductId,
  });

  final String id;
  final SubscriptionTier tier;
  final BillingPeriod billingPeriod;
  final String priceLabel;
  final String? storeProductId;

  static const free = SubscriptionPlan(
    id: 'free',
    tier: SubscriptionTier.free,
    billingPeriod: BillingPeriod.free,
    priceLabel: '€0',
    storeProductId: null,
  );

  static const premiumMonthly = SubscriptionPlan(
    id: 'premium_monthly',
    tier: SubscriptionTier.premium,
    billingPeriod: BillingPeriod.monthly,
    priceLabel: '€3,99/mese',
    storeProductId: 'pet_life_premium_monthly',
  );

  static const premiumAnnual = SubscriptionPlan(
    id: 'premium_annual',
    tier: SubscriptionTier.premium,
    billingPeriod: BillingPeriod.annual,
    priceLabel: '€29,99/anno',
    storeProductId: 'pet_life_premium_annual',
  );

  static const premiumPlans = [
    premiumMonthly,
    premiumAnnual,
  ];
}