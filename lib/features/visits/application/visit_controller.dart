import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/visit_local_storage.dart';
import '../domain/visit_entry.dart';

final visitLocalStorageProvider = FutureProvider<VisitLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);

    return VisitLocalStorage(preferences: preferences);
  },
);

final visitControllerProvider =
    StateNotifierProvider<VisitController, AsyncValue<List<VisitEntry>>>(
  (ref) {
    final controller = VisitController(ref: ref);
    controller.loadEntries();

    return controller;
  },
);

class VisitController extends StateNotifier<AsyncValue<List<VisitEntry>>> {
  VisitController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(visitLocalStorageProvider.future);
      final entries = storage.getEntries();

      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<VisitEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const [];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  Future<void> addEntry(VisitEntry entry) async {
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

  Future<void> _saveAndEmit(List<VisitEntry> entries) async {
    final sortedEntries = _sortEntries(entries);

    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(visitLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<VisitEntry> _sortEntries(List<VisitEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return sorted;
  }
}