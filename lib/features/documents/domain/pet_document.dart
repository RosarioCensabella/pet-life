enum PetDocumentCategory {
  healthRecord,
  labReport,
  prescription,
  insurance,
  invoice,
  other,
}

class PetDocument {
  const PetDocument({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.category,
    required this.originalFileName,
    required this.localPath,
    required this.sizeBytes,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String petId;
  final String petName;
  final String title;
  final PetDocumentCategory category;
  final String originalFileName;
  final String localPath;
  final int sizeBytes;
  final DateTime createdAt;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'title': title,
      'category': category.name,
      'originalFileName': originalFileName,
      'localPath': localPath,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory PetDocument.fromJson(Map<String, dynamic> json) {
    return PetDocument(
      id: json['id'] as String,
      petId: json['petId'] as String,
      petName: (json['petName'] as String?) ?? 'Pet',
      title: json['title'] as String,
      category: PetDocumentCategory.values.byName(json['category'] as String),
      originalFileName: json['originalFileName'] as String,
      localPath: json['localPath'] as String,
      sizeBytes: json['sizeBytes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}