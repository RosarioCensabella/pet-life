import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feature_flags.dart';

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return defaultFeatureFlags;
});