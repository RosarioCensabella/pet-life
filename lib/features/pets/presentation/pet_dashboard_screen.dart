import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/feature_flags.dart';
import '../../../app/feature_flags_provider.dart';
import '../../../app/theme.dart';
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
    final strings = _PetDashboardDesignStrings.of(context);
    final petsState = ref.watch(petControllerProvider);
    final featureFlags = ref.watch(featureFlagsProvider);

    return petsState.when(
      loading: () => Scaffold(
        body: SafeArea(
          child: Center(child: Text(l10n.loadingPets)),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      data: (pets) {
        final pet = _findPet(pets, petId);

        if (pet == null) {
          return _PetNotFoundScreen(l10n: l10n);
        }

        final modules = _buildEnabledModules(
          context: context,
          l10n: l10n,
          strings: strings,
          pet: pet,
          featureFlags: featureFlags,
        );

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _DashboardTopBar(
                  petName: pet.name,
                  onBack: () => context.go('/home'),
                  onEdit: pet.isArchived
                      ? null
                      : () => context.push('/pets/${pet.id}/edit'),
                ),
                const SizedBox(height: 12),
                _PetHeroCard(
                  pet: pet,
                  speciesLabel: _speciesLabel(l10n, pet.species),
                  sexLabel: _sexLabel(l10n, pet.sex),
                  yearsSuffix: l10n.yearsSuffix,
                  statusLabel: pet.isArchived
                      ? l10n.archivedProfile
                      : l10n.activeProfile,
                  strings: strings,
                ),
                const SizedBox(height: 10),
                _QuickInfoGrid(
                  pet: pet,
                  speciesLabel: _speciesLabel(l10n, pet.species),
                  sexLabel: _sexLabel(l10n, pet.sex),
                  yearsSuffix: l10n.yearsSuffix,
                  strings: strings,
                ),
                if (!pet.isArchived) ...[
                  const SizedBox(height: 10),
                  _TodayFocusCard(
                    petName: pet.name,
                    petColor: Color(pet.colorValue),
                    strings: strings,
                    onCalendar: () => context.go('/calendar'),
                    onReminder: () => context.push('/pets/${pet.id}/reminders'),
                  ),
                  const SizedBox(height: 10),
                  PetModuleGrid(
                    title: l10n.petDashboardChooseAction,
                    modules: modules,
                  ),
                  _PetActionsCard(
                    l10n: l10n,
                    strings: strings,
                    onArchive: () => _confirmArchivePet(
                      context: context,
                      ref: ref,
                      pet: pet,
                      l10n: l10n,
                    ),
                  ),
                ],
                if (pet.isArchived)
                  _ArchivedPetCard(
                    statusLabel: l10n.archivedProfile,
                    strings: strings,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PetModuleItem> _buildEnabledModules({
    required BuildContext context,
    required AppLocalizations l10n,
    required _PetDashboardDesignStrings strings,
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
          description: '',
          onTap: () => context.push('/pets/${pet.id}/health-diary'),
        ),
      );
    }

    if (featureFlags.weightModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.monitor_weight_outlined,
          title: l10n.moduleWeightTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/weight'),
        ),
      );
    }

    if (featureFlags.foodModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.restaurant_outlined,
          title: l10n.moduleFoodTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/food'),
        ),
      );
    }

    if (featureFlags.symptomsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.visibility_outlined,
          title: l10n.moduleSymptomsTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/symptoms'),
        ),
      );
    }

    if (featureFlags.medicationsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.medication_outlined,
          title: l10n.moduleMedicationsTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/medications'),
        ),
      );
    }

    if (featureFlags.visitsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.local_hospital_outlined,
          title: l10n.moduleVisitsTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/visits'),
        ),
      );
    }

    if (featureFlags.expensesModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.receipt_long_outlined,
          title: l10n.moduleExpensesTitle,
          description: '',
          onTap: () => context.push('/pets/${pet.id}/expenses'),
        ),
      );
    }




    if (featureFlags.reportsModuleEnabled) {
      modules.add(
        PetModuleItem(
          icon: Icons.summarize_outlined,
          title: l10n.moduleReportsTitle,
          description: strings.reportNonDiagnostic,
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
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.petName,
    required this.onBack,
    required this.onEdit,
  });

  final String petName;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = _PetDashboardDesignStrings.of(context);

    return Row(
      children: [
        _CircleIconButton(
          tooltip: strings.back,
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            petName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
        ),
        if (onEdit != null)
          _CircleIconButton(
            tooltip: strings.editProfile,
            icon: Icons.edit_outlined,
            onPressed: onEdit!,
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PetLifeDesign.softSurface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _PetHeroCard extends StatelessWidget {
  const _PetHeroCard({
    required this.pet,
    required this.speciesLabel,
    required this.sexLabel,
    required this.yearsSuffix,
    required this.statusLabel,
    required this.strings,
  });

  final Pet pet;
  final String speciesLabel;
  final String sexLabel;
  final String yearsSuffix;
  final String statusLabel;
  final _PetDashboardDesignStrings strings;

  @override
  Widget build(BuildContext context) {
    final petColor = Color(pet.colorValue);
    final breed = pet.breed?.trim();

    return _SoftContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: petColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
              _PetAvatar(
                imagePath: pet.profileImagePath,
                colorValue: pet.colorValue,
                radius: 54,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pet.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            breed == null || breed.isEmpty
                ? '$speciesLabel · ${pet.estimatedAgeYears} $yearsSuffix'
                : '$speciesLabel · $breed · ${pet.estimatedAgeYears} $yearsSuffix',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                color: petColor,
                icon: Icons.circle,
                label: statusLabel,
              ),
              _StatusPill(
                color: PetLifeDesign.secondaryBrown,
                icon: Icons.pets_outlined,
                label: sexLabel,
              ),
            ],
          ),
          if (pet.vetName != null && pet.vetName!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _HeroInfoStrip(
              icon: Icons.local_hospital_outlined,
              label: strings.vet,
              value: pet.vetName!,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroInfoStrip extends StatelessWidget {
  const _HeroInfoStrip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PetLifeDesign.softSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: PetLifeDesign.secondaryBrown,
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: PetLifeDesign.secondaryBrown,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.primaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickInfoGrid extends StatelessWidget {
  const _QuickInfoGrid({
    required this.pet,
    required this.speciesLabel,
    required this.sexLabel,
    required this.yearsSuffix,
    required this.strings,
  });

  final Pet pet;
  final String speciesLabel;
  final String sexLabel;
  final String yearsSuffix;
  final _PetDashboardDesignStrings strings;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickInfoItem(
        icon: Icons.cake_outlined,
        label: strings.age,
        value: '${pet.estimatedAgeYears} $yearsSuffix',
        color: const Color(0xFFE49D4F),
      ),
      _QuickInfoItem(
        icon: Icons.pets_outlined,
        label: strings.species,
        value: speciesLabel,
        color: Color(pet.colorValue),
      ),
      _QuickInfoItem(
        icon: Icons.wc_outlined,
        label: strings.sex,
        value: sexLabel,
        color: const Color(0xFF8F7AE5),
      ),
      _QuickInfoItem(
        icon: Icons.memory_outlined,
        label: strings.microchip,
        value: pet.microchip == null || pet.microchip!.trim().isEmpty
            ? strings.notSet
            : pet.microchip!,
        color: const Color(0xFF72A980),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 106,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            return _QuickInfoTile(item: items[index]);
          },
        );
      },
    );
  }
}

class _QuickInfoTile extends StatelessWidget {
  const _QuickInfoTile({
    required this.item,
  });

  final _QuickInfoItem item;

  @override
  Widget build(BuildContext context) {
    return _SoftContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 1,
                  maxWidth: 220,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: PetLifeDesign.mutedText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoItem {
  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.petName,
    required this.petColor,
    required this.strings,
    required this.onCalendar,
    required this.onReminder,
  });

  final String petName;
  final Color petColor;
  final _PetDashboardDesignStrings strings;
  final VoidCallback onCalendar;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.primaryBrown,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        boxShadow: [PetLifeDesign.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: petColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: petColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.todayFor(petName),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.todayDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DarkActionChip(
                        icon: Icons.calendar_month_outlined,
                        label: strings.openCalendar,
                        onTap: onCalendar,
                      ),
                      _DarkActionChip(
                        icon: Icons.notifications_active_outlined,
                        label: strings.addReminder,
                        onTap: onReminder,
                      ),
                    ],
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

class _DarkActionChip extends StatelessWidget {
  const _DarkActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.imagePath,
    required this.colorValue,
    required this.radius,
  });

  final String? imagePath;
  final int colorValue;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProviderForPath(imagePath);
    final hasPhoto = imageProvider != null;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(colorValue),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(colorValue).withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Color(colorValue).withValues(alpha: 0.16),
        backgroundImage: imageProvider,
        child: hasPhoto
            ? null
            : Icon(
                Icons.pets,
                color: Color(colorValue),
                size: radius,
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

class _PetActionsCard extends StatelessWidget {
  const _PetActionsCard({
    required this.l10n,
    required this.strings,
    required this.onArchive,
  });

  final AppLocalizations l10n;
  final _PetDashboardDesignStrings strings;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(
          color: const Color(0xFFF0D6BF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.archive_outlined,
              color: Color(0xFFB87841),
            ),
            SizedBox(
              width: 420,
              child: Text(
                strings.archiveDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                    ),
              ),
            ),
            OutlinedButton(
              onPressed: onArchive,
              child: Text(l10n.archivePet),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedPetCard extends StatelessWidget {
  const _ArchivedPetCard({
    required this.statusLabel,
    required this.strings,
  });

  final String statusLabel;
  final _PetDashboardDesignStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(
          color: const Color(0xFFF0D6BF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.archive_outlined,
              color: Color(0xFFB87841),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$statusLabel · ${strings.archivedDescription}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _SoftContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: PetLifeDesign.softSurface,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 34,
                      color: PetLifeDesign.secondaryBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.petNotFound,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: Text(l10n.backToHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftContainer extends StatelessWidget {
  const _SoftContainer({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _PetDashboardDesignStrings {
  const _PetDashboardDesignStrings({
    required this.back,
    required this.editProfile,
    required this.vet,
    required this.age,
    required this.species,
    required this.sex,
    required this.microchip,
    required this.notSet,
    required this.todayLabelPrefix,
    required this.todayDescription,
    required this.openCalendar,
    required this.addReminder,
    required this.reportNonDiagnostic,
    required this.archiveDescription,
    required this.archivedDescription,
  });

  final String back;
  final String editProfile;
  final String vet;
  final String age;
  final String species;
  final String sex;
  final String microchip;
  final String notSet;
  final String todayLabelPrefix;
  final String todayDescription;
  final String openCalendar;
  final String addReminder;
  final String reportNonDiagnostic;
  final String archiveDescription;
  final String archivedDescription;

  String todayFor(String petName) {
    return '$todayLabelPrefix $petName';
  }

  static _PetDashboardDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _PetDashboardDesignStrings(
        back: 'Back',
        editProfile: 'Edit profile',
        vet: 'Vet',
        age: 'Age',
        species: 'Species',
        sex: 'Sex',
        microchip: 'Microchip',
        notSet: 'Not set',
        todayLabelPrefix: 'Today for',
        todayDescription:
            'Review today’s schedule or create a new reminder in a few seconds.',
        openCalendar: 'Calendar',
        addReminder: 'New reminder',
        reportNonDiagnostic: 'Non-diagnostic report',
        archiveDescription:
            'Archive this pet only if you no longer need it in your active dashboard.',
        archivedDescription:
            'This pet is archived and hidden from the active home list.',
      );
    }

    return const _PetDashboardDesignStrings(
      back: 'Indietro',
      editProfile: 'Modifica profilo',
      vet: 'Vet',
      age: 'Età',
      species: 'Specie',
      sex: 'Sesso',
      microchip: 'Microchip',
      notSet: 'Non impostato',
      todayLabelPrefix: 'Oggi per',
      todayDescription:
          'Controlla la giornata o crea un nuovo promemoria in pochi secondi.',
      openCalendar: 'Calendario',
      addReminder: 'Nuovo promemoria',
      reportNonDiagnostic: 'Report non diagnostico',
      archiveDescription:
          'Archivia questo pet solo se non vuoi più vederlo nella dashboard attiva.',
      archivedDescription:
          'Questo pet è archiviato e nascosto dalla lista attiva in Home.',
    );
  }
}