import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_controller.dart';
import '../domain/pet.dart';

class PetDashboardScreen extends ConsumerWidget {
  const PetDashboardScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final petsState = ref.watch(petControllerProvider);

    return petsState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.petDashboardTitle)),
        body: Center(child: Text(l10n.loadingPets)),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: Text(l10n.petDashboardTitle)),
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
        final pet = _findPet(pets, petId);

        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.petDashboardTitle)),
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

        return Scaffold(
          appBar: AppBar(
            title: Text(pet.name),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _PetHeaderCard(
                pet: pet,
                speciesLabel: _speciesLabel(l10n, pet.species),
                sexLabel: _sexLabel(l10n, pet.sex),
                yearsSuffix: l10n.yearsSuffix,
              ),
              _InfoCard(
                icon: Icons.badge_outlined,
                title: l10n.petProfileSection,
                description: l10n.petProfileDescription,
              ),
              _InfoCard(
                icon: Icons.visibility_off_outlined,
                title: l10n.petCareModulesHiddenTitle,
                description: l10n.petCareModulesHiddenDescription,
              ),
            ],
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

  String _speciesLabel(AppLocalizations l10n, PetSpecies species) {
    return switch (species) {
      PetSpecies.dog => l10n.speciesDog,
      PetSpecies.cat => l10n.speciesCat,
      PetSpecies.other => l10n.speciesOther,
    };
  }

  String _sexLabel(AppLocalizations l10n, PetSex sex) {
    return switch (sex) {
      PetSex.unknown => l10n.sexUnknown,
      PetSex.female => l10n.sexFemale,
      PetSex.male => l10n.sexMale,
    };
  }
}

class _PetHeaderCard extends StatelessWidget {
  const _PetHeaderCard({
    required this.pet,
    required this.speciesLabel,
    required this.sexLabel,
    required this.yearsSuffix,
  });

  final Pet pet;
  final String speciesLabel;
  final String sexLabel;
  final String yearsSuffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.pets,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$speciesLabel · ${pet.estimatedAgeYears} $yearsSuffix'),
                  Text(sexLabel),
                  if (pet.breed != null) Text(pet.breed!),
                  if (pet.microchip != null) Text(pet.microchip!),
                  if (pet.vetName != null) Text(pet.vetName!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}