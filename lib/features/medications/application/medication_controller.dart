import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/medication_local_storage.dart';
import '../domain/medication_entry.dart';

final medicationLocalStorageProvider = FutureProvider<MedicationLocalStorage>(
  (ref) async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return MedicationLocalStorage(preferences: preferences);
  },
);

final medicationControllerProvider = StateNotifierProvider<
    MedicationController,
    AsyncValue<List<MedicationEntry>>>(
  (ref) {
    final controller = MedicationController(ref: ref);
    controller.loadEntries();
    return controller;
  },
);

class MedicationController
    extends StateNotifier<AsyncValue<List<MedicationEntry>>> {
  MedicationController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadEntries() async {
    try {
      final storage = await _ref.read(medicationLocalStorageProvider.future);
      final entries = storage.getEntries();
      state = AsyncValue.data(_sortEntries(entries));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<MedicationEntry> entriesForPet(String petId) {
    final entries = state.valueOrNull ?? const <MedicationEntry>[];

    return entries
        .where((entry) => entry.petId == petId)
        .toList(growable: false);
  }

  MedicationEntry? entryForReminder(String reminderId) {
    final entries = state.valueOrNull ?? const <MedicationEntry>[];

    for (final entry in entries) {
      if (entry.automaticReminderIds.contains(reminderId)) {
        return entry;
      }
    }

    return null;
  }

  Future<void> addEntry(MedicationEntry entry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];
    final updatedEntries = [...currentEntries, entry];

    await _saveAndEmit(updatedEntries);
  }

  Future<void> updateEntry(MedicationEntry updatedEntry) async {
    await _ensureLoaded();

    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];

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

    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];

    final updatedEntries = currentEntries
        .where((entry) => entry.id != entryId)
        .toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> markReminderTaken(String reminderId) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];
    var didUpdate = false;

    final updatedEntries = currentEntries.map((entry) {
      if (!entry.automaticReminderIds.contains(reminderId)) {
        return entry;
      }

      didUpdate = true;
      return entry.markReminderTaken(reminderId, now);
    }).toList(growable: false);

    if (didUpdate) {
      await _saveAndEmit(updatedEntries);
    }
  }

  Future<void> markReminderNotTaken(String reminderId) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];
    var didUpdate = false;

    final updatedEntries = currentEntries.map((entry) {
      if (!entry.automaticReminderIds.contains(reminderId)) {
        return entry;
      }

      didUpdate = true;
      return entry.markReminderNotTaken(reminderId, now);
    }).toList(growable: false);

    if (didUpdate) {
      await _saveAndEmit(updatedEntries);
    }
  }

  Future<void> suspendEntry(String entryId) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];

    final updatedEntries = currentEntries.map((entry) {
      if (entry.id != entryId) {
        return entry;
      }

      return entry.copyWith(
        status: MedicationStatus.paused,
        suspendedAt: now,
        updatedAt: now,
        clearCompletedAt: true,
      );
    }).toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> reinstateEntry(String entryId) async {
    await _ensureLoaded();

    final now = DateTime.now();
    final currentEntries = state.valueOrNull ?? const <MedicationEntry>[];

    final updatedEntries = currentEntries.map((entry) {
      if (entry.id != entryId) {
        return entry;
      }

      final nextStatus = entry.isCompletedByProgress
          ? MedicationStatus.completed
          : MedicationStatus.active;

      return entry.copyWith(
        status: nextStatus,
        updatedAt: now,
        clearSuspendedAt: true,
        clearCompletedAt: nextStatus == MedicationStatus.active,
      );
    }).toList(growable: false);

    await _saveAndEmit(updatedEntries);
  }

  Future<void> _ensureLoaded() async {
    if (state.isLoading || state.valueOrNull == null) {
      await loadEntries();
    }
  }

  Future<void> _saveAndEmit(List<MedicationEntry> entries) async {
    final sortedEntries = _sortEntries(entries);
    state = AsyncValue.data(sortedEntries);

    try {
      final storage = await _ref.read(medicationLocalStorageProvider.future);
      await storage.saveEntries(sortedEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<MedicationEntry> _sortEntries(List<MedicationEntry> entries) {
    final sorted = [...entries];

    sorted.sort((a, b) {
      final dateComparison = b.startDate.compareTo(a.startDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted;
  }
}