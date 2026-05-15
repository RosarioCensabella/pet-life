import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../pets/application/pet_controller.dart';
import '../application/document_file_service.dart';
import '../application/document_file_service_provider.dart';
import '../application/pet_document_controller.dart';
import '../domain/pet_document.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  const AddDocumentScreen({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PetDocumentCategory _category = PetDocumentCategory.healthRecord;
  PickedLocalDocument? _pickedDocument;
  String? _documentId;
  bool _isPickingFile = false;
  bool _isSaving = false;
  bool _showFileError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    setState(() {
      _isPickingFile = true;
      _showFileError = false;
    });

    final documentId = const Uuid().v4();

    final pickedDocument = await ref
        .read(documentFileServiceProvider)
        .pickAndCopyDocument(
          petId: widget.petId,
          documentId: documentId,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _documentId = pickedDocument == null ? null : documentId;
      _pickedDocument = pickedDocument;
      _isPickingFile = false;
    });
  }

  Future<void> _saveDocument() async {
    final l10n = AppLocalizations.of(context)!;

    final isFormValid = _formKey.currentState!.validate();

    if (_pickedDocument == null || _documentId == null) {
      setState(() {
        _showFileError = true;
      });
    }

    if (!isFormValid || _pickedDocument == null || _documentId == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final petName = ref
            .read(petControllerProvider.notifier)
            .findById(widget.petId)
            ?.name ??
        'Pet';

    final document = PetDocument(
      id: _documentId!,
      petId: widget.petId,
      petName: petName,
      title: _titleController.text.trim(),
      category: _category,
      originalFileName: _pickedDocument!.originalFileName,
      localPath: _pickedDocument!.localPath,
      sizeBytes: _pickedDocument!.sizeBytes,
      createdAt: DateTime.now(),
      notes: _optionalText(_notesController.text),
    );

    await ref.read(petDocumentControllerProvider.notifier).addDocument(
          document,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.documentSaved)),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pets/${widget.petId}/documents');
    }
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
        title: Text(l10n.addDocumentTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.documentTitleLabel,
                  hintText: l10n.documentTitleHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.documentTitleRequired;
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PetDocumentCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.documentCategoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: PetDocumentCategory.healthRecord,
                    child: Text(l10n.documentCategoryHealthRecord),
                  ),
                  DropdownMenuItem(
                    value: PetDocumentCategory.labReport,
                    child: Text(l10n.documentCategoryLabReport),
                  ),
                  DropdownMenuItem(
                    value: PetDocumentCategory.prescription,
                    child: Text(l10n.documentCategoryPrescription),
                  ),
                  DropdownMenuItem(
                    value: PetDocumentCategory.insurance,
                    child: Text(l10n.documentCategoryInsurance),
                  ),
                  DropdownMenuItem(
                    value: PetDocumentCategory.invoice,
                    child: Text(l10n.documentCategoryInvoice),
                  ),
                  DropdownMenuItem(
                    value: PetDocumentCategory.other,
                    child: Text(l10n.documentCategoryOther),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _category = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isPickingFile ? null : _selectFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _isPickingFile ? '...' : l10n.selectDocumentFile,
                ),
              ),
              if (_pickedDocument != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.selectedDocumentFile}: ${_pickedDocument!.originalFileName}',
                ),
              ],
              if (_showFileError) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.documentFileRequired,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.documentNotesLabel,
                  hintText: l10n.documentNotesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _saveDocument,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveDocument),
              ),
            ],
          ),
        ),
      ),
    );
  }
}