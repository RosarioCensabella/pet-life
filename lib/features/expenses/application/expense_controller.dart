import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/expense_local_storage.dart';
import '../domain/expense_entry.dart';

final expenseLocalStorageProvider = FutureProvider<ExpenseLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);

    return ExpenseLocalStorage(preferences: preferences);
  },
);

final expenseControllerProvider =
    StateNotifierProvider<ExpenseController, AsyncValue<List<ExpenseEntry>>>(
  (ref) {
    final controller = ExpenseController(ref: ref);
    controller.loadEntries();

    return controller;
  },
);

class ExpenseController extends StateNotifier<AsyncValue<List<ExpenseEntry>>> {
  ExpenseController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(expenseLocalStorageProvider.future);
      final entries = storage.getEntries();

      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<ExpenseEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const [];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  Future<void> addEntry(ExpenseEntry entry) async {
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

  Future<void> _saveAndEmit(List<ExpenseEntry> entries) async {
    final sortedEntries = _sortEntries(entries);

    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(expenseLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<ExpenseEntry> _sortEntries(List<ExpenseEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return sorted;
  }
}