// lib/model/bulletin_model.dart

import 'package:flutter/material.dart';

class BulletinModel {
  final int id;
  final int inscriptionId;
  final String eleveNom;
  final String elevePrenom;
  final String classe;
  final String anneeScolaire;
  final String trimestre;
  final double moyenneGenerale;
  final int rang;
  final int totalEleves;
  final String mention;
  final String? appreciation;
  final List<MatiereBulletin> matieres;
  final String dateGeneration;

  BulletinModel({
    required this.id,
    required this.inscriptionId,
    required this.eleveNom,
    required this.elevePrenom,
    required this.classe,
    required this.anneeScolaire,
    required this.trimestre,
    required this.moyenneGenerale,
    required this.rang,
    required this.totalEleves,
    required this.mention,
    this.appreciation,
    required this.matieres,
    required this.dateGeneration,
  });

  // ✅ La factory DOIT être à l'intérieur de la classe
  factory BulletinModel.fromJson(Map<String, dynamic> json) {
    return BulletinModel(
      id: json['id'] ?? 0,
      inscriptionId: json['inscription_id'] ?? 0,
      eleveNom: json['eleve_nom'] ?? '',
      elevePrenom: json['eleve_prenom'] ?? '',
      classe: json['classe'] ?? '',
      // ⚠️ Auparavant l'écran recalculait l'année scolaire à partir de la
      // date du jour (DateTime.now().year) au lieu de lire la vraie année
      // scolaire de l'inscription — ce qui affichait la mauvaise année dès
      // qu'on consultait un bulletin qui n'est pas celui de l'année en cours.
      anneeScolaire: json['annee_scolaire']?.toString() ?? '',
      trimestre: json['trimestre'] ?? '1',
      moyenneGenerale: (json['moyenne_generale'] ?? 0).toDouble(),
      rang: json['rang'] ?? 0,
      totalEleves: json['total_eleves'] ?? 0,
      mention: json['mention'] ?? '',
      appreciation: json['appreciation'],
      matieres: (json['matieres'] as List?)?.map((e) => MatiereBulletin.fromJson(e)).toList() ?? [],
      dateGeneration: json['date_generation'] ?? '',
    );
  }

  String get fullName => '$elevePrenom $eleveNom';
  
  String get mentionLabel {
    if (moyenneGenerale >= 16) return 'Très Bien';
    if (moyenneGenerale >= 14) return 'Bien';
    if (moyenneGenerale >= 12) return 'Assez Bien';
    if (moyenneGenerale >= 10) return 'Passable';
    return 'Insuffisant';
  }
  
  Color get mentionColor {
    if (moyenneGenerale >= 16) return Colors.green;
    if (moyenneGenerale >= 14) return Colors.lightGreen;
    if (moyenneGenerale >= 12) return Colors.orange;
    if (moyenneGenerale >= 10) return Colors.amber;
    return Colors.red;
  }
}

class MatiereBulletin {
  final int id;
  final String nom;
  final int? coefficient;
  final double moyenne;
  final double moyenneClasse;
  final int rang;
  final int totalEleves;
  final List<NoteDetail> devoirs;
  final List<NoteDetail> interrogations;

  MatiereBulletin({
    required this.id,
    required this.nom,
    this.coefficient,
    required this.moyenne,
    required this.moyenneClasse,
    required this.rang,
    required this.totalEleves,
    required this.devoirs,
    required this.interrogations,
  });

  // ✅ Ajout de la factory pour MatiereBulletin (si elle n'existe pas)
  factory MatiereBulletin.fromJson(Map<String, dynamic> json) {
    // ⚠️ Le backend (ParentController::getMatieresFromBulletin) envoie
    // 'matiere_nom' et 'moyenne_eleve' — pas 'nom' / 'moyenne'. Avec les
    // anciennes clés, chaque matière du bulletin s'affichait sans nom et
    // avec une moyenne à 0.0 côté parent, même quand tout était calculé
    // correctement côté serveur (même bug que côté admin/gestbulletin).
    return MatiereBulletin(
      id: json['id'] ?? 0,
      nom: json['matiere_nom'] ?? json['nom'] ?? '',
      coefficient: json['coefficient'],
      moyenne: double.tryParse(
              (json['moyenne_eleve'] ?? json['moyenne'])?.toString() ?? '') ??
          0.0,
      moyenneClasse: (json['moyenne_classe'] ?? 0).toDouble(),
      rang: json['rang'] ?? 0,
      totalEleves: json['total_eleves'] ?? 0,
      devoirs: (json['devoirs'] as List?)?.map((e) => NoteDetail.fromJson(e)).toList() ?? [],
      interrogations: (json['interrogations'] as List?)?.map((e) => NoteDetail.fromJson(e)).toList() ?? [],
    );
  }

  String get moyenneTexte => moyenne.toStringAsFixed(1);
  String get rangTexte => '$rang/$totalEleves';
  
  Color get moyenneColor {
    if (moyenne >= 16) return Colors.green;
    if (moyenne >= 14) return Colors.lightGreen;
    if (moyenne >= 12) return Colors.orange;
    if (moyenne >= 10) return Colors.amber;
    return Colors.red;
  }
}

class NoteDetail {
  final int numero;
  final double note;
  final String appreciation;

  NoteDetail({
    required this.numero,
    required this.note,
    required this.appreciation,
  });

  // ✅ Ajout de la factory pour NoteDetail
  factory NoteDetail.fromJson(Map<String, dynamic> json) {
    return NoteDetail(
      numero: json['numero'] ?? 0,
      note: (json['note'] ?? 0).toDouble(),
      appreciation: json['appreciation'] ?? '',
    );
  }
}