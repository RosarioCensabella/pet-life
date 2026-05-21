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
    final entries = state.valueOrNull ?? const <FoodEntry>[];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  FoodEntry? entryForPet(String petId) {
    final entries = state.valueOrNull ?? const <FoodEntry>[];

    for (final entry in entries) {
      if (entry.petId == petId) {
        return entry;
      }
    }

    return null;
  }

  Future<void> addEntry(FoodEntry entry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <FoodEntry>[];
    final updatedEntries = [...currentEntries, entry];

    await _saveAndEmit(updatedEntries);
  }

  Future<void> updateEntry(FoodEntry updatedEntry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <FoodEntry>[];
    var wasUpdated = false;

    final updatedEntries = currentEntries.map((entry) {
      if (entry.id == updatedEntry.id) {
        wasUpdated = true;
        return updatedEntry;
      }

      return entry;
    }).toList(growable: false);

    if (!wasUpdated) {
      await _saveAndEmit([...updatedEntries, updatedEntry]);
      return;
    }

    await _saveAndEmit(updatedEntries);
  }

  Future<void> upsertEntry(FoodEntry entry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <FoodEntry>[];
    final exists = currentEntries.any((item) => item.id == entry.id);

    if (exists) {
      await updateEntry(entry);
      return;
    }

    await addEntry(entry);
  }

  Future<void> deleteEntry(String entryId) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <FoodEntry>[];

    final updatedEntries = currentEntries
        .where((entry) => entry.id != entryId)
        .toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> _ensureLoaded() async {
    if (state.isLoading || state.valueOrNull == null) {
      await loadEntries();
    }
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

    sorted.sort((a, b) {
      final first = b.updatedAt ?? b.createdAt;
      final second = a.updatedAt ?? a.createdAt;

      return first.compareTo(second);
    });

    return sorted;
  }
}