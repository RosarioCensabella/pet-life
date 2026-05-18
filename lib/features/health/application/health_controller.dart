import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/health_local_storage.dart';
import '../domain/health_entry.dart';

final healthLocalStorageProvider = FutureProvider<HealthLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);

    return HealthLocalStorage(preferences: preferences);
  },
);

final healthControllerProvider =
    StateNotifierProvider<HealthController, AsyncValue<List<HealthEntry>>>(
  (ref) {
    final controller = HealthController(ref: ref);
    controller.loadEntries();

    return controller;
  },
);

class HealthController extends StateNotifier<AsyncValue<List<HealthEntry>>> {
  HealthController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(healthLocalStorageProvider.future);
      final entries = storage.getEntries();

      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<HealthEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const [];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  Future<void> addEntry(HealthEntry entry) async {
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

  Future<void> _saveAndEmit(List<HealthEntry> entries) async {
    final sortedEntries = _sortEntries(entries);

    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(healthLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<HealthEntry> _sortEntries(List<HealthEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return sorted;
  }
}