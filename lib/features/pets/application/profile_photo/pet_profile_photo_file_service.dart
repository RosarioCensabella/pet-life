class PickedPetProfilePhoto {
  const PickedPetProfilePhoto({
    required this.localPath,
    required this.originalFileName,
  });

  final String localPath;
  final String originalFileName;
}

abstract class PetProfilePhotoFileService {
  Future<PickedPetProfilePhoto?> pickAndCopyProfilePhoto({
    required String petId,
  });

  Future<void> deleteProfilePhoto(String localPath);
}