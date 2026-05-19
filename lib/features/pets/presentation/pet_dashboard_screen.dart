import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_flags.dart';
import '../../../app/feature_flags_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_controller.dart';
import '../domain/pet.dart';
import 'widgets/pet_module_grid.dart';

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
    final featureFlags = ref.watch(featureFlagsProvider);

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
              if (!pet.isArchived)
                PetModuleGrid(
                  title: l10n.petDashboardChooseAction,
                  modules: _buildEnabledModules(
                    context: context,
                    l10n: l10n,
                    pet: pet,
                    featureFlags: featureFlags,
                  ),
                ),
              if (!pet.isArchived)
                _PetActionsCard(
                  l10n: l10n,
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

  List<PetModuleItem> _buildEnabledModules({
    required BuildContext context,
    required AppLocalizations l10n,
    required Pet pet,
    required FeatureFlags featureFlags,
  }) {
    final modules = <PetModuleItem>[];

    if (featureFlags.petProfileModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.badge_outlined,
          title: l10n.moduleProfileTitle,
          description: l10n.moduleProfileDescription,
          onTap: () => context.push('/pets/${pet.id}/edit'),
        ),
      );
    }

    if (featureFlags.remindersModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.notifications_active_outlined,
          title: l10n.moduleRemindersTitle,
          description: l10n.moduleRemindersDescription,
          onTap: () => context.push('/pets/${pet.id}/reminders'),
        ),
      );
    }

    if (featureFlags.documentsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.folder_outlined,
          title: l10n.moduleDocumentsTitle,
          description: l10n.moduleDocumentsDescription,
          onTap: () => context.push('/pets/${pet.id}/documents'),
        ),
      );
    }

    if (featureFlags.healthDiaryModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.edit_note_outlined,
          title: l10n.moduleHealthDiaryTitle,
          description: _localized(
            context,
            it: 'Note datate per preparare meglio le visite, senza diagnosi.',
            en: 'Dated notes to prepare visits, without diagnosis.',
          ),
          onTap: () => context.push('/pets/${pet.id}/health-diary'),
        ),
      );
    }

    if (featureFlags.weightModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.monitor_weight_outlined,
          title: l10n.moduleWeightTitle,
          description: _localized(
            context,
            it: 'Registra il peso nel tempo senza interpretazioni mediche.',
            en: 'Track weight over time without medical interpretation.',
          ),
          onTap: () => context.push('/pets/${pet.id}/weight'),
        ),
      );
    }

    if (featureFlags.foodModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.restaurant_outlined,
          title: l10n.moduleFoodTitle,
          description: _localized(
            context,
            it: 'Tieni traccia dei pasti senza consigli nutrizionali automatici.',
            en: 'Track meals without automatic nutrition advice.',
          ),
          onTap: () => context.push('/pets/${pet.id}/food'),
        ),
      );
    }

    if (featureFlags.symptomsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.visibility_outlined,
          title: l10n.moduleSymptomsTitle,
          description: _localized(
            context,
            it: 'Registra osservazioni e intensità, senza triage o consigli.',
            en: 'Record observations and intensity, without triage or advice.',
          ),
          onTap: () => context.push('/pets/${pet.id}/symptoms'),
        ),
      );
    }

    if (featureFlags.medicationsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.medication_outlined,
          title: l10n.moduleMedicationsTitle,
          description: _localized(
            context,
            it: 'Registro dei farmaci indicati dal veterinario, senza dosaggi suggeriti.',
            en: 'Medication records from your veterinarian, without dosage suggestions.',
          ),
          onTap: () => context.push('/pets/${pet.id}/medications'),
        ),
      );
    }

    if (featureFlags.visitsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.local_hospital_outlined,
          title: l10n.moduleVisitsTitle,
          description: _localized(
            context,
            it: 'Registro visite, esiti e prossimi controlli senza diagnosi generate.',
            en: 'Track visits, outcomes and follow-ups without generated diagnoses.',
          ),
          onTap: () => context.push('/pets/${pet.id}/visits'),
        ),
      );
    }

    if (featureFlags.expensesModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.receipt_long_outlined,
          title: l10n.moduleExpensesTitle,
          description: _localized(
            context,
            it: 'Tieni traccia dei costi del pet in modo semplice e ordinato.',
            en: 'Track pet-related costs in a simple, organized way.',
          ),
          onTap: () => context.push('/pets/${pet.id}/expenses'),
        ),
      );
    }

    if (featureFlags.insuranceModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.verified_user_outlined,
          title: l10n.moduleInsuranceTitle,
          description: '',
          onTap: () {},
        ),
      );
    }


    if (featureFlags.reportsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.summarize_outlined,
          title: l10n.moduleReportsTitle,
          description: _localized(
            context,
            it: 'Riepilogo organizzativo da copiare, senza diagnosi.',
            en: 'Organizational summary you can copy, without diagnosis.',
          ),
          onTap: () => context.push('/pets/${pet.id}/reports'),
        ),
      );
    }




    return modules;
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

  String _localized(
    BuildContext context, {
    required String it,
    required String en,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return languageCode == 'en' ? en : it;
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
    required this.onArchive,
  });

  final AppLocalizations l10n;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: OutlinedButton.icon(
          onPressed: onArchive,
          icon: const Icon(Icons.archive_outlined),
          label: Text(l10n.archivePet),
        ),
      ),
    );
  }
}