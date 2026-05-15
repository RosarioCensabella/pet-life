import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pet_local_storage.dart';
import '../domain/pet.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final petLocalStorageProvider = FutureProvider<PetLocalStorage>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);

  return PetLocalStorage(preferences: preferences);
});

final petControllerProvider =
    StateNotifierProvider<PetController, AsyncValue<List<Pet>>>((ref) {
  final controller = PetController(ref: ref);
  controller.loadPets();
  return controller;
});

class PetController extends StateNotifier<AsyncValue<List<Pet>>> {
  PetController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadPets() async {
    try {
      final storage = await _ref.read(petLocalStorageProvider.future);
      final pets = storage.getPets();
      state = AsyncValue.data(pets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addPet(Pet pet) async {
    final currentPets = state.valueOrNull ?? const <Pet>[];
    final updatedPets = [...currentPets, pet];

    await _saveAndEmit(updatedPets);
  }

  Future<void> updatePet(Pet updatedPet) async {
    final currentPets = state.valueOrNull ?? const <Pet>[];

    final updatedPets = currentPets.map((pet) {
      if (pet.id == updatedPet.id) {
        return updatedPet;
      }

      return pet;
    }).toList(growable: false);

    await _saveAndEmit(updatedPets);
  }

  Future<void> archivePet(String petId) async {
    final currentPets = state.valueOrNull ?? const <Pet>[];

    final updatedPets = currentPets.map((pet) {
      if (pet.id == petId) {
        return pet.copyWith(archivedAt: DateTime.now());
      }

      return pet;
    }).toList(growable: false);

    await _saveAndEmit(updatedPets);
  }

  Pet? findById(String petId) {
    final pets = state.valueOrNull ?? const <Pet>[];

    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  Future<void> _saveAndEmit(List<Pet> pets) async {
    state = AsyncValue.data(pets);

    try {
      final storage = await _ref.read(petLocalStorageProvider.future);
      await storage.savePets(pets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}