// lib/models/annee_scolaire_model.dart

class AnneeScolaire {
  final int id;
  final String libelle;
  final String dateDebut;
  final String dateFin;
  final String? createdAt;
  final String? updatedAt;

  AnneeScolaire({
    required this.id,
    required this.libelle,
    required this.dateDebut,
    required this.dateFin,
    this.createdAt,
    this.updatedAt,
  });

  factory AnneeScolaire.fromJson(Map<String, dynamic> json) {
    return AnneeScolaire(
      id: json['id'],
      libelle: json['libelle'],
      dateDebut: json['date_debut'],
      dateFin: json['date_fin'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'date_debut': dateDebut,
      'date_fin': dateFin,
    };
  }
}