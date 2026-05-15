import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pet_document.dart';

class PetDocumentLocalStorage {
  PetDocumentLocalStorage({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const documentsKey = 'pet_life_documents_v1';

  final SharedPreferences _preferences;

  List<PetDocument> getDocuments() {
    final rawDocuments = _preferences.getString(documentsKey);

    if (rawDocuments == null || rawDocuments.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawDocuments) as List<dynamic>;

    return decoded
        .map((item) => PetDocument.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveDocuments(List<PetDocument> documents) async {
    final encoded = jsonEncode(
      documents.map((document) => document.toJson()).toList(growable: false),
    );

    await _preferences.setString(documentsKey, encoded);
  }
}