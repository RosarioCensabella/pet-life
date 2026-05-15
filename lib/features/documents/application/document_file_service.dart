class PickedLocalDocument {
  const PickedLocalDocument({
    required this.originalFileName,
    required this.localPath,
    required this.sizeBytes,
  });

  final String originalFileName;
  final String localPath;
  final int sizeBytes;
}

abstract class DocumentFileService {
  Future<PickedLocalDocument?> pickAndCopyDocument({
    required String petId,
    required String documentId,
  });

  Future<void> openDocument(String localPath);

  Future<void> deleteDocument(String localPath);
}