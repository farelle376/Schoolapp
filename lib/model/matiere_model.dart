// lib/model/matiere_model.dart

import 'note_model.dart';
import 'package:flutter/material.dart';

class InterrogationNote {
  final int numero;
  final double note;
  final String date;

  InterrogationNote({
    required this.numero,
    required this.note,
    required this.date,
  });

  factory InterrogationNote.fromJson(Map<String, dynamic> json) {
    return InterrogationNote(
      numero: json['numero'] ?? 0,
      note: (json['note'] ?? 0).toDouble(),
      date: json['date']?.toString() ?? '',
    );
  }
}

class DevoirNote {
  final int numero;
  final double note;
  final String date;

  DevoirNote({
    required this.numero,
    required this.note,
    required this.date,
  });

  factory DevoirNote.fromJson(Map<String, dynamic> json) {
    return DevoirNote(
      numero: json['numero'] ?? 0,
      note: (json['note'] ?? 0).toDouble(),
      date: json['date']?.toString() ?? '',
    );
  }
}

class DetailsInterrogations {
  final List<InterrogationNote> notes;
  final int nombre;
  final double? moyenne;

  DetailsInterrogations({
    required this.notes,
    required this.nombre,
    this.moyenne,
  });

  factory DetailsInterrogations.fromJson(Map<String, dynamic> json) {
    return DetailsInterrogations(
      notes: (json['notes'] as List?)?.map((n) => InterrogationNote.fromJson(n)).toList() ?? [],
      nombre: json['nombre'] ?? 0,
      moyenne: json['moyenne']?.toDouble(),
    );
  }
}

class DetailsDevoirs {
  final List<DevoirNote> notes;
  final int nombre;
  final double? somme;

  DetailsDevoirs({
    required this.notes,
    required this.nombre,
    this.somme,
  });

  factory DetailsDevoirs.fromJson(Map<String, dynamic> json) {
    return DetailsDevoirs(
      notes: (json['notes'] as List?)?.map((n) => DevoirNote.fromJson(n)).toList() ?? [],
      nombre: json['nombre'] ?? 0,
      somme: json['somme']?.toDouble(),
    );
  }
}

class DetailsMatiere {
  final DetailsInterrogations interrogations;
  final DetailsDevoirs devoirs;

  DetailsMatiere({
    required this.interrogations,
    required this.devoirs,
  });

  factory DetailsMatiere.fromJson(Map<String, dynamic> json) {
    return DetailsMatiere(
      interrogations: DetailsInterrogations.fromJson(json['interrogations']),
      devoirs: DetailsDevoirs.fromJson(json['devoirs']),
    );
  }
}

class MatiereModel {
  final int id;
  final String nom;
  final int coefficient;
  final double? moyenne;
  final int? rang;
  final int? totalEleves;
  final bool peutCalculer;
  final bool aMoyenne;
  final DetailsMatiere? details;
  final List<NoteModel>? notes;

  MatiereModel({
    required this.id,
    required this.nom,
    required this.coefficient,
    this.moyenne,
    this.rang,
    this.totalEleves,
    required this.peutCalculer,
    required this.aMoyenne,
    this.details,
    this.notes,
  });

  factory MatiereModel.fromJson(Map<String, dynamic> json) {
    return MatiereModel(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      coefficient: json['coefficient'] ?? 1,
      moyenne: json['moyenne']?.toDouble(),
      rang: json['rang'],
      totalEleves: json['total_eleves'],
      peutCalculer: json['peut_calculer'] ?? false,
      aMoyenne: json['a_moyenne'] ?? false,
      details: json['details'] != null ? DetailsMatiere.fromJson(json['details']) : null,
      notes: json['notes'] != null 
          ? (json['notes'] as List).map((n) => NoteModel.fromJson(n)).toList()
          : null,
    );
  }
  
  // ========== GETTERS ==========
  String get rangTexte {
    if (totalEleves == null) return '--';
    if (rang == null) return '--/${totalEleves}';
    return '$rang/${totalEleves}';
  }
  
  /// Vérifie si le rang est disponible
  bool get hasRang => rang != null && totalEleves != null;
  
  /// Vérifie si la moyenne est disponible
  bool get hasMoyenne => aMoyenne && moyenne != null;
  
  /// Formate la moyenne (ex: "14.5/20")
  String get moyenneTexte {
    if (!hasMoyenne) return '--/20';
    return '${moyenne!.toStringAsFixed(1)}/20';
  }
  
  /// Retourne la couleur de la moyenne
  Color get moyenneColor {
    if (!hasMoyenne) return Colors.grey;
    if (moyenne! >= 16) return Colors.green;
    if (moyenne! >= 14) return Colors.lightGreen;
    if (moyenne! >= 12) return Colors.orange;
    if (moyenne! >= 10) return Colors.amber;
    return Colors.red;
  }
  
  /// Retourne l'appréciation de la moyenne
  String get appreciation {
    if (!hasMoyenne) return 'Non disponible';
    if (moyenne! >= 16) return 'Excellent';
    if (moyenne! >= 14) return 'Très bien';
    if (moyenne! >= 12) return 'Bien';
    if (moyenne! >= 10) return 'Assez bien';
    return 'Insuffisant';
  }
  
  /// Vérifie si la matière a des notes
  bool get hasNotes => notes != null && notes!.isNotEmpty;
}
  