enum PetSpecies {
  dog,
  cat,
  other,
}

enum PetSex {
  unknown,
  female,
  male,
}

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.estimatedAgeYears,
    required this.createdAt,
    this.breed,
    this.sex = PetSex.unknown,
    this.microchip,
    this.vetName,
    this.archivedAt,
  });

  final String id;
  final String name;
  final PetSpecies species;
  final int estimatedAgeYears;
  final DateTime createdAt;
  final String? breed;
  final PetSex sex;
  final String? microchip;
  final String? vetName;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Pet copyWith({
    String? id,
    String? name,
    PetSpecies? species,
    int? estimatedAgeYears,
    DateTime? createdAt,
    String? breed,
    PetSex? sex,
    String? microchip,
    String? vetName,
    DateTime? archivedAt,
    bool clearBreed = false,
    bool clearMicrochip = false,
    bool clearVetName = false,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      estimatedAgeYears: estimatedAgeYears ?? this.estimatedAgeYears,
      createdAt: createdAt ?? this.createdAt,
      breed: clearBreed ? null : breed ?? this.breed,
      sex: sex ?? this.sex,
      microchip: clearMicrochip ? null : microchip ?? this.microchip,
      vetName: clearVetName ? null : vetName ?? this.vetName,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species.name,
      'estimatedAgeYears': estimatedAgeYears,
      'createdAt': createdAt.toIso8601String(),
      'breed': breed,
      'sex': sex.name,
      'microchip': microchip,
      'vetName': vetName,
      'archivedAt': archivedAt?.toIso8601String(),
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    final archivedAtRaw = json['archivedAt'] as String?;

    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      species: PetSpecies.values.byName(json['species'] as String),
      estimatedAgeYears: json['estimatedAgeYears'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      breed: json['breed'] as String?,
      sex: PetSex.values.byName((json['sex'] as String?) ?? PetSex.unknown.name),
      microchip: json['microchip'] as String?,
      vetName: json['vetName'] as String?,
      archivedAt: archivedAtRaw == null ? null : DateTime.parse(archivedAtRaw),
    );
  }
}