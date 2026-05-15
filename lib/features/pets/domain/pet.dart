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
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
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
    );
  }
}