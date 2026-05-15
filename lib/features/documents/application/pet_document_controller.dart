import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/application/pet_controller.dart';
import '../data/pet_document_local_storage.dart';
import '../domain/pet_document.dart';
import 'document_file_service_provider.dart';

final petDocumentLocalStorageProvider =
    FutureProvider<PetDocumentLocalStorage>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);

  return PetDocumentLocalStorage(preferences: preferences);
});

final petDocumentControllerProvider =
    StateNotifierProvider<PetDocumentController, AsyncValue<List<PetDocument>>>(
  (ref) {
    final controller = PetDocumentController(ref: ref);
    controller.loadDocuments();
    return controller;
  },
);

class PetDocumentController
    extends StateNotifier<AsyncValue<List<PetDocument>>> {
  PetDocumentController({
    required Ref ref,
  })  : _ref = ref,
        super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> loadDocuments() async {
    try {
      final storage = await _ref.read(petDocumentLocalStorageProvider.future);
      final documents = storage.getDocuments();
      state = AsyncValue.data(_sortDocuments(documents));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<PetDocument> documentsForPet(String petId) {
    final documents = state.valueOrNull ?? const <PetDocument>[];

    return documents
        .where((document) => document.petId == petId)
        .toList(growable: false);
  }

  Future<void> addDocument(PetDocument document) async {
    final currentDocuments = state.valueOrNull ?? const <PetDocument>[];
    final updatedDocuments = [...currentDocuments, document];

    await _saveAndEmit(updatedDocuments);
  }

  Future<void> openDocument(PetDocument document) async {
    await _ref.read(documentFileServiceProvider).openDocument(
          document.localPath,
        );
  }

  Future<void> deleteDocument(PetDocument document) async {
    await _ref.read(documentFileServiceProvider).deleteDocument(
          document.localPath,
        );

    final currentDocuments = state.valueOrNull ?? const <PetDocument>[];

    final updatedDocuments = currentDocuments
        .where((item) => item.id != document.id)
        .toList(growable: false);

    await _saveAndEmit(updatedDocuments);
  }

  Future<void> _saveAndEmit(List<PetDocument> documents) async {
    final sortedDocuments = _sortDocuments(documents);

    state = AsyncValue.data(sortedDocuments);

    try {
      final storage = await _ref.read(petDocumentLocalStorageProvider.future);
      await storage.saveDocuments(sortedDocuments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<PetDocument> _sortDocuments(List<PetDocument> documents) {
    final sorted = [...documents];

    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sorted;
  }
}