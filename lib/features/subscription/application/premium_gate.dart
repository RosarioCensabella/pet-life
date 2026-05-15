import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subscription_controller.dart';

final isPremiumUserProvider = Provider<bool>((ref) {
  final subscriptionStatus = ref.watch(subscriptionControllerProvider);

  return subscriptionStatus.isPremium;
});