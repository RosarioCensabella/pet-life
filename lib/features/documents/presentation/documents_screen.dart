import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final documentsState = ref.watch(petDocumentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentsTitle),
      ),
      body: documentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (documents) {
          final petDocuments = documents
              .where((document) => document.petId == petId)
              .toList(growable: false);

          if (petDocuments.isEmpty) {
            return _EmptyDocumentsState(
              title: l10n.noDocumentsTitle,
              description: l10n.noDocumentsDescription,
              buttonLabel: l10n.addDocument,
              onPressed: () => context.push('/pets/$petId/documents/new'),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ...petDocuments.map(
                (document) => _DocumentCard(
                  document: document,
                  categoryLabel: _categoryLabel(l10n, document.category),
                  dateLabel: _formatDate(context, document.createdAt),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/pets/$petId/documents/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addDocument),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pets/$petId/documents/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addDocument),
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

    await ref
        .read(petDocumentControllerProvider.notifier)
        .deleteDocument(document);

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
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.folder_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.categoryLabel,
    required this.dateLabel,
    required this.openLabel,
    required this.deleteLabel,
    required this.onOpen,
    required this.onDelete,
  });

  final PetDocument document;
  final String categoryLabel;
  final String dateLabel;
  final String openLabel;
  final String deleteLabel;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final notes = document.notes?.trim();

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
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    document.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(categoryLabel),
            Text(document.originalFileName),
            Text(dateLabel),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes),
            ],
            const SizedBox(height: 16),
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
    );
  }
}