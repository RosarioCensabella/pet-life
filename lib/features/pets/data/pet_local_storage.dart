import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pet.dart';

class PetLocalStorage {
  PetLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const _petsKey = 'pet_life_pets_v1';

  final SharedPreferences _preferences;

  List<Pet> getPets() {
    final rawPets = _preferences.getString(_petsKey);

    if (rawPets == null || rawPets.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawPets) as List<dynamic>;

    return decoded
        .map((item) => Pet.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> savePets(List<Pet> pets) async {
    final encoded = jsonEncode(
      pets.map((pet) => pet.toJson()).toList(growable: false),
    );

    await _preferences.setString(_petsKey, encoded);
  }
}