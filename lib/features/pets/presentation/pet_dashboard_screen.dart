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
          return _PetNotFoundScreen(l10n: l10n);
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
                statusLabel:
                    pet.isArchived ? l10n.archivedProfile : l10n.activeProfile,
              ),
              _InfoCard(
                icon: Icons.badge_outlined,
                title: l10n.petProfileSection,
                description: l10n.petProfileDescription,
              ),
              if (!pet.isArchived)
                _PetActionsCard(
                  l10n: l10n,
                  onEdit: () => context.go('/pets/${pet.id}/edit'),
                  onArchive: () => _confirmArchivePet(
                    context: context,
                    ref: ref,
                    pet: pet,
                    l10n: l10n,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmArchivePet({
    required BuildContext context,
    required WidgetRef ref,
    required Pet pet,
    required AppLocalizations l10n,
  }) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.archivePetConfirmTitle),
          content: Text(l10n.archivePetConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.archive),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true || !context.mounted) {
      return;
    }

    await ref.read(petControllerProvider.notifier).archivePet(pet.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.petArchived)),
    );

    context.go('/home');
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

class _PetNotFoundScreen extends StatelessWidget {
  const _PetNotFoundScreen({
    required this.l10n,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
}

class _PetHeaderCard extends StatelessWidget {
  const _PetHeaderCard({
    required this.pet,
    required this.speciesLabel,
    required this.sexLabel,
    required this.yearsSuffix,
    required this.statusLabel,
  });

  final Pet pet;
  final String speciesLabel;
  final String sexLabel;
  final String yearsSuffix;
  final String statusLabel;

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
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(statusLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetActionsCard extends StatelessWidget {
  const _PetActionsCard({
    required this.l10n,
    required this.onEdit,
    required this.onArchive,
  });

  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tune_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.petActions,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.petActionsDescription),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editPet),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
              label: Text(l10n.archivePet),
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