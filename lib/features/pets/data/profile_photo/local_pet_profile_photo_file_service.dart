import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/profile_photo/pet_profile_photo_file_service.dart';

class LocalPetProfilePhotoFileService implements PetProfilePhotoFileService {
  @override
  Future<PickedPetProfilePhoto?> pickAndCopyProfilePhoto({
    required String petId,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.image,
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

    final profilePhotosDirectory = Directory(
      '${appDocumentsDirectory.path}${Platform.pathSeparator}pet_profile_photos${Platform.pathSeparator}$petId',
    );

    await profilePhotosDirectory.create(recursive: true);

    final safeFileName = _safeFileName(pickedFile.name);
    final destinationPath =
        '${profilePhotosDirectory.path}${Platform.pathSeparator}profile_$safeFileName';

    final copiedFile = await sourceFile.copy(destinationPath);

    return PickedPetProfilePhoto(
      localPath: copiedFile.path,
      originalFileName: pickedFile.name,
    );
  }

  @override
  Future<void> deleteProfilePhoto(String localPath) async {
    final file = File(localPath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  String _safeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (sanitized.trim().isEmpty) {
      return 'profile_photo';
    }

    return sanitized;
  }
}