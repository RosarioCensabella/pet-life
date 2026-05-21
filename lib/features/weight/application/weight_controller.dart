import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/weight_local_storage.dart';
import '../domain/weight_entry.dart';

final weightLocalStorageProvider = FutureProvider<WeightLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return WeightLocalStorage(preferences: preferences);
  },
);

final weightControllerProvider =
    StateNotifierProvider<WeightController, AsyncValue<List<WeightEntry>>>(
  (ref) {
    final controller = WeightController(ref: ref);
    controller.loadEntries();
    return controller;
  },
);

class WeightController extends StateNotifier<AsyncValue<List<WeightEntry>>> {
  WeightController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(weightLocalStorageProvider.future);
      final entries = storage.getEntries();

      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<WeightEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const <WeightEntry>[];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  Future<void> addEntry(WeightEntry entry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <WeightEntry>[];
    final updatedEntries = [...currentEntries, entry];

    await _saveAndEmit(updatedEntries);
  }

  Future<void> updateEntry(WeightEntry updatedEntry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <WeightEntry>[];

    final updatedEntries = currentEntries.map((entry) {
      if (entry.id == updatedEntry.id) {
        return updatedEntry;
      }

      return entry;
    }).toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> deleteEntry(String entryId) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <WeightEntry>[];

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

  Future<void> _saveAndEmit(List<WeightEntry> entries) async {
    final sortedEntries = _sortEntries(entries);
    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(weightLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<WeightEntry> _sortEntries(List<WeightEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted;
  }
}