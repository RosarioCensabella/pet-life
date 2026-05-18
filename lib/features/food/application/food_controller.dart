import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/food_local_storage.dart';
import '../domain/food_entry.dart';

final foodLocalStorageProvider = FutureProvider<FoodLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);

    return FoodLocalStorage(preferences: preferences);
  },
);

final foodControllerProvider =
    StateNotifierProvider<FoodController, AsyncValue<List<FoodEntry>>>(
  (ref) {
    final controller = FoodController(ref: ref);
    controller.loadEntries();

    return controller;
  },
);

class FoodController extends StateNotifier<AsyncValue<List<FoodEntry>>> {
  FoodController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(foodLocalStorageProvider.future);
      final entries = storage.getEntries();

      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<FoodEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const [];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  Future<void> addEntry(FoodEntry entry) async {
    final currentEntries = state.valueOrNull ?? const [];
    final updatedEntries = [...currentEntries, entry];

    await _saveAndEmit(updatedEntries);
  }

  Future<void> deleteEntry(String entryId) async {
    final currentEntries = state.valueOrNull ?? const [];
    final updatedEntries = currentEntries
        .where((entry) => entry.id != entryId)
        .toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> _saveAndEmit(List<FoodEntry> entries) async {
    final sortedEntries = _sortEntries(entries);

    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(foodLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<FoodEntry> _sortEntries(List<FoodEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted;
  }
}