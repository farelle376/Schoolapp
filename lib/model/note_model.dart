// lib/model/note_model.dart
import 'package:flutter/material.dart';
class NoteModel {
  final int id;
  final int inscriptionId;
  final int matiereId;
  final double note;
  final String typeNote;
  final int trimestre;
  final String appreciation;
  final String date;
  final bool isValidated;
  final String? matiereNom; 

  NoteModel({
    required this.id,
    required this.inscriptionId,
    required this.matiereId,
    required this.note,
    required this.typeNote,
    required this.trimestre,
    required this.appreciation,
    required this.date,
    required this.isValidated,
    this.matiereNom,
  });

factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? 0,
      inscriptionId: json['inscription_id'] ?? 0,
      matiereId: json['matiere_id'] ?? 0,
      note: (json['note'] ?? 0).toDouble(),
      typeNote: json['type_note']?.toString() ?? 'interrogation',
      trimestre: json['trimestre'] ?? 1,
      appreciation: json['appreciation']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isValidated: json['is_validated'] ?? false,
      matiereNom: json['matiere_nom']?.toString(),
    );
  }

  String getTypeNoteLabel() {
    switch (typeNote) {
      case 'interrogation': return 'Interrogation';
      case 'devoir': return 'Devoir';
      case 'composition': return 'Composition';
      default: return 'Note';
    }
  }

  Color getTypeNoteColor() {
    switch (typeNote) {
      case 'interrogation': return Colors.blue;
      case 'devoir': return Colors.orange;
      case 'composition': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class NoteInfo {
  final int numero;
  final double note;
  final String appreciation;

  NoteInfo({
    required this.numero,
    required this.note,
    required this.appreciation,
  });
}

class InterrogationsModel {
  final List<NoteInfo> notes;
  final double? moyenne;

  InterrogationsModel({
    required this.notes,
    this.moyenne,
  });
}

class DevoirsModel {
  final List<NoteInfo> notes;
  final double? somme;

  DevoirsModel({
    required this.notes,
    this.somme,
  });
}

class DetailsModel {
  final InterrogationsModel interrogations;
  final DevoirsModel devoirs;

  DetailsModel({
    required this.interrogations,
    required this.devoirs,
  });
}