import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_controller.dart';
import '../application/profile_photo/pet_profile_photo_file_service_provider.dart';
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

  final String _petId = const Uuid().v4();

  PetSpecies _species = PetSpecies.dog;
  PetSex _sex = PetSex.unknown;
  int _selectedColorValue = Pet.defaultColorValue;
  String? _profileImagePath;
  bool _isSaving = false;
  bool _isPickingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _estimatedAgeController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _vetNameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final strings = _PetVisualIdentityStrings.of(context);

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final fileService = ref.read(petProfilePhotoFileServiceProvider);
      final pickedPhoto = await fileService.pickAndCopyProfilePhoto(
        petId: _petId,
      );

      if (!mounted) {
        return;
      }

      if (pickedPhoto == null) {
        return;
      }

      setState(() {
        _profileImagePath = pickedPhoto.localPath;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.photoPickError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _removeProfilePhoto() {
    setState(() {
      _profileImagePath = null;
    });
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
      id: _petId,
      name: _nameController.text.trim(),
      species: _species,
      estimatedAgeYears: int.parse(_estimatedAgeController.text.trim()),
      breed: _optionalText(_breedController.text),
      sex: _sex,
      microchip: _optionalText(_microchipController.text),
      vetName: _optionalText(_vetNameController.text),
      profileImagePath: _profileImagePath,
      colorValue: _selectedColorValue,
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
    final strings = _PetVisualIdentityStrings.of(context);

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
              _PetAvatarEditor(
                imagePath: _profileImagePath,
                colorValue: _selectedColorValue,
                addPhotoLabel: strings.addPhoto,
                changePhotoLabel: strings.changePhoto,
                removePhotoLabel: strings.removePhoto,
                isPickingPhoto: _isPickingPhoto,
                onPickPhoto: _pickProfilePhoto,
                onRemovePhoto: _removeProfilePhoto,
              ),
              const SizedBox(height: 24),
              _PetColorPicker(
                title: strings.petColor,
                selectedColorValue: _selectedColorValue,
                onColorSelected: (colorValue) {
                  setState(() {
                    _selectedColorValue = colorValue;
                  });
                },
              ),
              const SizedBox(height: 24),
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

class _PetAvatarEditor extends StatelessWidget {
  const _PetAvatarEditor({
    required this.imagePath,
    required this.colorValue,
    required this.addPhotoLabel,
    required this.changePhotoLabel,
    required this.removePhotoLabel,
    required this.isPickingPhoto,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final String? imagePath;
  final int colorValue;
  final String addPhotoLabel;
  final String changePhotoLabel;
  final String removePhotoLabel;
  final bool isPickingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProviderForPath(imagePath);
    final hasPhoto = imageProvider != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Color(colorValue),
              backgroundImage: imageProvider,
              child: hasPhoto
                  ? null
                  : const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 44,
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isPickingPhoto ? null : onPickPhoto,
                  icon: isPickingPhoto
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(hasPhoto ? changePhotoLabel : addPhotoLabel),
                ),
                if (hasPhoto)
                  TextButton.icon(
                    onPressed: onRemovePhoto,
                    icon: const Icon(Icons.close_outlined),
                    label: Text(removePhotoLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProviderForPath(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }
}

class _PetColorPicker extends StatelessWidget {
  const _PetColorPicker({
    required this.title,
    required this.selectedColorValue,
    required this.onColorSelected,
  });

  final String title;
  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Pet.colorPalette.map((colorValue) {
                final isSelected = colorValue == selectedColorValue;

                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onColorSelected(colorValue),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetVisualIdentityStrings {
  const _PetVisualIdentityStrings({
    required this.addPhoto,
    required this.changePhoto,
    required this.removePhoto,
    required this.petColor,
    required this.photoPickError,
  });

  final String addPhoto;
  final String changePhoto;
  final String removePhoto;
  final String petColor;
  final String photoPickError;

  static _PetVisualIdentityStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _PetVisualIdentityStrings(
        addPhoto: 'Add photo',
        changePhoto: 'Change photo',
        removePhoto: 'Remove photo',
        petColor: 'Pet color',
        photoPickError: 'Unable to select the photo.',
      );
    }

    return const _PetVisualIdentityStrings(
      addPhoto: 'Aggiungi foto',
      changePhoto: 'Cambia foto',
      removePhoto: 'Rimuovi foto',
      petColor: 'Colore del pet',
      photoPickError: 'Impossibile selezionare la foto.',
    );
  }
}