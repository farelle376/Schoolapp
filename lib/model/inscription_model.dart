// lib/models/inscription_model.dart

import 'eleve_model.dart';
import 'classe_model.dart';
import 'annee_scolaire_model.dart';

class Inscription {
  final int id;
  final int eleveId;
  final int classeId;
  final int anneeScolaireId;
  final String dateInscription;
  final String statut;
  final String? createdAt;
  final String? updatedAt;
  final Eleve? eleve;
  final Classe? classe;
  final AnneeScolaire? anneeScolaire;

  Inscription({
    required this.id,
    required this.eleveId,
    required this.classeId,
    required this.anneeScolaireId,
    required this.dateInscription,
    required this.statut,
    this.createdAt,
    this.updatedAt,
    this.eleve,
    this.classe,
    this.anneeScolaire,
  });

  factory Inscription.fromJson(Map<String, dynamic> json) {
  final classeAnnee = json['classe_annee'] as Map<String, dynamic>?;

  return Inscription(
    id: json['id'] ?? 0,
    eleveId: json['eleve_id'] ?? 0,
    classeId: classeAnnee?['classe_id'] ?? 0,
    anneeScolaireId: classeAnnee?['annee_scolaire_id'] ?? 0,
    dateInscription: json['date_inscription']?.toString() ?? '',
    statut: json['statut']?.toString() ?? '',
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
    eleve: json['eleve'] != null ? Eleve.fromJson(json['eleve']) : null,
    classe: classeAnnee?['classe'] != null
        ? Classe.fromJson(classeAnnee!['classe'])
        : null,
    anneeScolaire: classeAnnee?['annee_scolaire'] != null
        ? AnneeScolaire.fromJson(classeAnnee!['annee_scolaire'])
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'eleve_id': eleveId,
      'classe_id': classeId,
      'annee_scolaire_id': anneeScolaireId,
      'date_inscription': dateInscription,
      'statut': statut,
    };
  }
}