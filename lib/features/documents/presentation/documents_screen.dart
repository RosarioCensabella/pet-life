import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../application/pet_document_controller.dart';
import '../domain/pet_document.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _DocumentDesignStrings.of(context);
    final documentsState = ref.watch(petDocumentControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: documentsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorState(error: error),
          data: (documents) {
            final petDocuments = documents
                .where((document) => document.petId == petId)
                .toList(growable: false)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _TopBar(
                  title: l10n.documentsTitle,
                  onBack: () => context.go('/pets/$petId'),
                ),
                const SizedBox(height: 12),
                _HeroCard(
                  title: l10n.documentsTitle,
                  subtitle: strings.heroSubtitle,
                  count: petDocuments.length,
                  countLabel: strings.saved,
                  onAdd: () => context.push('/pets/$petId/documents/new'),
                  addLabel: strings.quickAdd,
                ),
                const SizedBox(height: 12),
                _DisclaimerCard(text: strings.disclaimer),
                const SizedBox(height: 12),
                if (petDocuments.isEmpty)
                  _EmptyDocumentsState(
                    title: l10n.noDocumentsTitle,
                    description: l10n.noDocumentsDescription,
                    buttonLabel: l10n.addDocument,
                    onPressed: () => context.push('/pets/$petId/documents/new'),
                  )
                else ...[
                  _SectionHeader(
                    title: strings.archiveTitle,
                    count: petDocuments.length,
                  ),
                  const SizedBox(height: 8),
                  ...petDocuments.map(
                    (document) => _DocumentCard(
                      document: document,
                      categoryLabel: _categoryLabel(l10n, document.category),
                      dateLabel: _formatDate(context, document.createdAt),
                      sizeLabel: _formatSize(document.sizeBytes),
                      openLabel: l10n.openDocument,
                      deleteLabel: l10n.deleteDocument,
                      onOpen: () => ref
                          .read(petDocumentControllerProvider.notifier)
                          .openDocument(document),
                      onDelete: () => _confirmDeleteDocument(
                        context: context,
                        ref: ref,
                        document: document,
                        l10n: l10n,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/pets/$petId/documents/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addDocument),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addDocument,
        onPressed: () => context.push('/pets/$petId/documents/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteDocument({
    required BuildContext context,
    required WidgetRef ref,
    required PetDocument document,
    required AppLocalizations l10n,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteDocumentConfirmTitle),
          content: Text(l10n.deleteDocumentConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteDocument),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await ref.read(petDocumentControllerProvider.notifier).deleteDocument(
          document,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.documentDeleted)),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    return dateFormat.format(date);
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }

    final sizeKb = sizeBytes / 1024;

    if (sizeKb < 1024) {
      return '${sizeKb.toStringAsFixed(1)} KB';
    }

    final sizeMb = sizeKb / 1024;

    return '${sizeMb.toStringAsFixed(1)} MB';
  }

  String _categoryLabel(AppLocalizations l10n, PetDocumentCategory category) {
    return switch (category) {
      PetDocumentCategory.healthRecord => l10n.documentCategoryHealthRecord,
      PetDocumentCategory.labReport => l10n.documentCategoryLabReport,
      PetDocumentCategory.prescription => l10n.documentCategoryPrescription,
      PetDocumentCategory.insurance => l10n.documentCategoryInsurance,
      PetDocumentCategory.invoice => l10n.documentCategoryInvoice,
      PetDocumentCategory.other => l10n.documentCategoryOther,
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final strings = _DocumentDesignStrings.of(context);

    return Row(
      children: [
        Material(
          color: PetLifeDesign.softSurface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: strings.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.onAdd,
    required this.addLabel,
  });

  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.primaryBrown,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        boxShadow: [PetLifeDesign.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DarkPill(
                        icon: Icons.description_outlined,
                        label: '$count $countLabel',
                      ),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: onAdd,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: PetLifeDesign.primaryBrown,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  addLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: PetLifeDesign.primaryBrown,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
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
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: const Color(0xFFF0D6BF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB87841),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7B5537),
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PetLifeDesign.softSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: PetLifeDesign.secondaryBrown,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  const _EmptyDocumentsState({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PetLifeDesign.infoLilac,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 34,
                color: Color(0xFF9C6ADE),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.categoryLabel,
    required this.dateLabel,
    required this.sizeLabel,
    required this.openLabel,
    required this.deleteLabel,
    required this.onOpen,
    required this.onDelete,
  });

  final PetDocument document;
  final String categoryLabel;
  final String dateLabel;
  final String sizeLabel;
  final String openLabel;
  final String deleteLabel;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final notes = document.notes?.trim();
    final accentColor = _accentColorForCategory(document.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(PetLifeDesign.radiusLarge),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            _iconForCategory(document.category),
                            color: accentColor,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                document.originalFileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          color: accentColor,
                          icon: Icons.label_outline,
                          label: categoryLabel,
                        ),
                        _InfoPill(
                          color: PetLifeDesign.secondaryBrown,
                          icon: Icons.schedule_outlined,
                          label: dateLabel,
                        ),
                        _InfoPill(
                          color: PetLifeDesign.secondaryBrown,
                          icon: Icons.sd_storage_outlined,
                          label: sizeLabel,
                        ),
                        _InfoPill(
                          color: accentColor,
                          icon: Icons.pets_outlined,
                          label: document.petName,
                        ),
                      ],
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        notes,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.open_in_new),
                          label: Text(openLabel),
                        ),
                        OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(deleteLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColorForCategory(PetDocumentCategory category) {
    return switch (category) {
      PetDocumentCategory.healthRecord => const Color(0xFF72A980),
      PetDocumentCategory.labReport => const Color(0xFF5A8BB8),
      PetDocumentCategory.prescription => const Color(0xFFC85B4A),
      PetDocumentCategory.insurance => const Color(0xFF7A6B5B),
      PetDocumentCategory.invoice => const Color(0xFFE49D4F),
      PetDocumentCategory.other => const Color(0xFF9C6ADE),
    };
  }

  IconData _iconForCategory(PetDocumentCategory category) {
    return switch (category) {
      PetDocumentCategory.healthRecord => Icons.folder_shared_outlined,
      PetDocumentCategory.labReport => Icons.science_outlined,
      PetDocumentCategory.prescription => Icons.medication_outlined,
      PetDocumentCategory.insurance => Icons.verified_user_outlined,
      PetDocumentCategory.invoice => Icons.receipt_long_outlined,
      PetDocumentCategory.other => Icons.description_outlined,
    };
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
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

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetLifeDesign.warmSurface,
        borderRadius: BorderRadius.circular(PetLifeDesign.radiusExtraLarge),
        border: Border.all(color: PetLifeDesign.outline),
        boxShadow: [PetLifeDesign.subtleShadow],
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DocumentDesignStrings {
  const _DocumentDesignStrings({
    required this.back,
    required this.heroSubtitle,
    required this.saved,
    required this.quickAdd,
    required this.disclaimer,
    required this.archiveTitle,
  });

  final String back;
  final String heroSubtitle;
  final String saved;
  final String quickAdd;
  final String disclaimer;
  final String archiveTitle;

  static _DocumentDesignStrings of(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'en') {
      return const _DocumentDesignStrings(
        back: 'Back',
        heroSubtitle:
            'Keep health records, prescriptions, invoices and pet files organized in one calm archive.',
        saved: 'saved',
        quickAdd: 'New',
        disclaimer:
            'Documents are stored as an organizational archive. Pet Life does not interpret reports, provide diagnosis or replace your veterinarian.',
        archiveTitle: 'Document archive',
      );
    }

    return const _DocumentDesignStrings(
      back: 'Indietro',
      heroSubtitle:
          'Tieni libretto, prescrizioni, fatture e file del pet ordinati in un archivio semplice.',
      saved: 'salvati',
      quickAdd: 'Nuovo',
      disclaimer:
          'I documenti sono archiviati solo per organizzazione. Pet Life non interpreta referti, non fornisce diagnosi e non sostituisce il veterinario.',
      archiveTitle: 'Archivio documenti',
    );
  }
}