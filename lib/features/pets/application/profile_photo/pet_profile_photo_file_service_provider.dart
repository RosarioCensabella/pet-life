import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_photo/local_pet_profile_photo_file_service.dart';
import 'pet_profile_photo_file_service.dart';

final petProfilePhotoFileServiceProvider =
    Provider<PetProfilePhotoFileService>(
  (ref) => LocalPetProfilePhotoFileService(),
);