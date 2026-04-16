// lib/model/emploi_du_temps_admin_model.dart
import 'package:flutter/material.dart';
// lib/model/emploi_du_temps_admin_model.dart

class EmploiDuTempsAdminModel {
  final int id;
  final int classeId;
  final String classeNom;
  final int matiereId;
  final String matiereNom;
  final int professeurId;
  final String professeurNom;
  final String jour;
  final String heureDebut;
  final String heureFin;
  final String typeCours;
  final bool estActive;

  EmploiDuTempsAdminModel({
    required this.id,
    required this.classeId,
    required this.classeNom,
    required this.matiereId,
    required this.matiereNom,
    required this.professeurId,
    required this.professeurNom,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.typeCours,
    required this.estActive,
  });

  factory EmploiDuTempsAdminModel.fromJson(Map<String, dynamic> json) {
    String heureDebut = json['heure_debut']?.toString() ?? '';
    String heureFin = json['heure_fin']?.toString() ?? '';
    
    if (heureDebut.contains('T')) {
      heureDebut = heureDebut.split('T')[1].split(':').take(2).join(':');
    }
    if (heureFin.contains('T')) {
      heureFin = heureFin.split('T')[1].split(':').take(2).join(':');
    }
    
    return EmploiDuTempsAdminModel(
      id: json['id'] ?? 0,
      classeId: json['classe_id'] ?? 0,
      classeNom: json['classe_nom']?.toString() ?? 'Classe non définie',
      matiereId: json['matiere_id'] ?? 0,
      matiereNom: json['matiere_nom']?.toString() ?? 'Matière non définie',
      professeurId: json['professeur_id'] ?? 0,
      professeurNom: json['professeur_nom']?.toString() ?? 'Professeur non assigné',
      jour: json['jour']?.toString() ?? 'lundi',
      heureDebut: heureDebut.isEmpty ? '08:00' : heureDebut,
      heureFin: heureFin.isEmpty ? '10:00' : heureFin,
      typeCours: json['type_cours']?.toString() ?? 'cours',
      estActive: json['est_active'] ?? true,
    );
  }

  String get jourLabel {
    switch (jour) {
      case 'lundi': return 'Lundi';
      case 'mardi': return 'Mardi';
      case 'mercredi': return 'Mercredi';
      case 'jeudi': return 'Jeudi';
      case 'vendredi': return 'Vendredi';
      case 'samedi': return 'Samedi';
      default: return jour;
    }
  }

  String get typeCoursLabel {
    switch (typeCours) {
      case 'td': return 'TD';
      case 'tp': return 'TP';
      case 'evaluation': return 'Évaluation';
      default: return 'Cours';
    }
  }

  Color get typeCoursColor {
    switch (typeCours) {
      case 'td': return Colors.orange;
      case 'tp': return Colors.green;
      case 'evaluation': return Colors.red;
      default: return Colors.blue;
    }
  }
}
 