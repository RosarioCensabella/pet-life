import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_document_file_service.dart';
import 'document_file_service.dart';

final documentFileServiceProvider = Provider<DocumentFileService>((ref) {
  return LocalDocumentFileService();
});