import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_controller.dart';
import '../domain/pet.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _estimatedAgeController = TextEditingController();
  final _breedController = TextEditingController();
  final _microchipController = TextEditingController();
  final _vetNameController = TextEditingController();

  PetSpecies _species = PetSpecies.dog;
  PetSex _sex = PetSex.unknown;
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

  Future<void> _savePet() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final pet = Pet(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      species: _species,
      estimatedAgeYears: int.parse(_estimatedAgeController.text.trim()),
      breed: _optionalText(_breedController.text),
      sex: _sex,
      microchip: _optionalText(_microchipController.text),
      vetName: _optionalText(_vetNameController.text),
      createdAt: DateTime.now(),
    );

    await ref.read(petControllerProvider.notifier).addPet(pet);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.petSaved)),
    );

    context.go('/home');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addPetTitle),
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
                onPressed: _isSaving ? null : _savePet,
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
  }
}