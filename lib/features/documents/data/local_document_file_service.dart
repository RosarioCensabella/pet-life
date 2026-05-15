import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../application/document_file_service.dart';

class LocalDocumentFileService implements DocumentFileService {
  @override
  Future<PickedLocalDocument?> pickAndCopyDocument({
    required String petId,
    required String documentId,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'heic',
        'webp',
        'doc',
        'docx',
      ],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final pickedFile = result.files.single;
    final sourcePath = pickedFile.path;

    if (sourcePath == null || sourcePath.isEmpty) {
      return null;
    }

    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      return null;
    }

    final appDocumentsDirectory = await getApplicationDocumentsDirectory();
    final documentsDirectory = Directory(
      '${appDocumentsDirectory.path}${Platform.pathSeparator}pet_documents${Platform.pathSeparator}$petId',
    );

    await documentsDirectory.create(recursive: true);

    final safeFileName = _safeFileName(pickedFile.name);
    final destinationPath =
        '${documentsDirectory.path}${Platform.pathSeparator}${documentId}_$safeFileName';

    final copiedFile = await sourceFile.copy(destinationPath);
    final sizeBytes = await copiedFile.length();

    return PickedLocalDocument(
      originalFileName: pickedFile.name,
      localPath: copiedFile.path,
      sizeBytes: sizeBytes,
    );
  }

  @override
  Future<void> openDocument(String localPath) async {
    await OpenFilex.open(localPath);
  }

  @override
  Future<void> deleteDocument(String localPath) async {
    final file = File(localPath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  String _safeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (sanitized.trim().isEmpty) {
      return 'document';
    }

    return sanitized;
  }
}