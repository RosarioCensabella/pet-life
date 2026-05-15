import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/subscription_status.dart';

final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionStatus>(
  (ref) => SubscriptionController(),
);

class SubscriptionController extends StateNotifier<SubscriptionStatus> {
  SubscriptionController() : super(SubscriptionStatus.free);

  bool get isPremium => state.isPremium;
}