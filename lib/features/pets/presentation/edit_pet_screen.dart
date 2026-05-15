import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_controller.dart';
import '../domain/pet.dart';

class EditPetScreen extends ConsumerStatefulWidget {
  const EditPetScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends ConsumerState<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _estimatedAgeController = TextEditingController();
  final _breedController = TextEditingController();
  final _microchipController = TextEditingController();
  final _vetNameController = TextEditingController();

  PetSpecies _species = PetSpecies.dog;
  PetSex _sex = PetSex.unknown;
  String? _initializedPetId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _estimatedAgeController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _vetNameController.dispose();
    super.dispose();
  }

  void _initializeFormIfNeeded(Pet pet) {
    if (_initializedPetId == pet.id) {
      return;
    }

    _initializedPetId = pet.id;
    _nameController.text = pet.name;
    _estimatedAgeController.text = pet.estimatedAgeYears.toString();
    _breedController.text = pet.breed ?? '';
    _microchipController.text = pet.microchip ?? '';
    _vetNameController.text = pet.vetName ?? '';
    _species = pet.species;
    _sex = pet.sex;
  }

  Future<void> _savePet(Pet originalPet) async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final breed = _optionalText(_breedController.text);
    final microchip = _optionalText(_microchipController.text);
    final vetName = _optionalText(_vetNameController.text);

    final updatedPet = originalPet.copyWith(
      name: _nameController.text.trim(),
      species: _species,
      estimatedAgeYears: int.parse(_estimatedAgeController.text.trim()),
      breed: breed,
      sex: _sex,
      microchip: microchip,
      vetName: vetName,
      clearBreed: breed == null,
      clearMicrochip: microchip == null,
      clearVetName: vetName == null,
    );

    await ref.read(petControllerProvider.notifier).updatePet(updatedPet);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.petUpdated)),
    );

    context.go('/pets/${originalPet.id}');
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final petsState = ref.watch(petControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.editPetTitle)),
        body: Center(child: Text(l10n.loadingPets)),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.editPetTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (pets) {
        final pet = _findPet(pets, widget.petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editPetTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(l10n.petNotFound),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/home'),
                      child: Text(l10n.backToHome),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        _initializeFormIfNeeded(pet);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.editPetTitle),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.petNameLabel,
                      hintText: l10n.petNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.petNameRequired;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PetSpecies>(
                    initialValue: _species,
                    decoration: InputDecoration(
                      labelText: l10n.speciesLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PetSpecies.dog,
                        child: Text(l10n.speciesDog),
                      ),
                      DropdownMenuItem(
                        value: PetSpecies.cat,
                        child: Text(l10n.speciesCat),
                      ),
                      DropdownMenuItem(
                        value: PetSpecies.other,
                        child: Text(l10n.speciesOther),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _species = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _estimatedAgeController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.estimatedAgeLabel,
                      hintText: l10n.estimatedAgeHint,
                      suffixText: l10n.yearsSuffix,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.estimatedAgeRequired;
                      }

                      final parsedValue = int.tryParse(value.trim());

                      if (parsedValue == null || parsedValue < 0) {
                        return l10n.estimatedAgeInvalid;
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _breedController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.breedLabel,
                      hintText: l10n.breedHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<PetSex>(
                    initialValue: _sex,
                    decoration: InputDecoration(
                      labelText: l10n.sexLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PetSex.unknown,
                        child: Text(l10n.sexUnknown),
                      ),
                      DropdownMenuItem(
                        value: PetSex.female,
                        child: Text(l10n.sexFemale),
                      ),
                      DropdownMenuItem(
                        value: PetSex.male,
                        child: Text(l10n.sexMale),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _sex = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _microchipController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.microchipLabel,
                      hintText: l10n.microchipHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vetNameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.vetNameLabel,
                      hintText: l10n.vetNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : () => _savePet(pet),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.savePet),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Pet? _findPet(List<Pet> pets, String petId) {
    for (final pet in pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }
}