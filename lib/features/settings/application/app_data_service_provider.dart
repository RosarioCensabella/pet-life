import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/local_app_data_service.dart';
import 'app_data_service.dart';

final appDataServiceProvider = FutureProvider<AppDataService>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);

  return LocalAppDataService(preferences: preferences);
});