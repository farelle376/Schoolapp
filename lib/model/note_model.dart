// lib/model/note_model.dart
import 'package:flutter/material.dart';
class NoteModel {
  final int id;
  final double note;
  final String typeNote;
  final String appreciation;
  final String date;
  final bool isValidated;

  NoteModel({
    required this.id,
    required this.note,
    required this.typeNote,
    required this.appreciation,
    required this.date,
    required this.isValidated,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? 0,
      note: (json['note'] ?? 0).toDouble(),
      typeNote: json['type_note']?.toString() ?? 'interrogation',
      appreciation: json['appreciation']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      isValidated: json['is_validated'] ?? false,
    );
  }

  String getTypeNoteLabel() {
    switch (typeNote) {
      case 'interrogation':
        return 'Interrogation';
      case 'devoir':
        return 'Devoir';
      case 'composition':
        return 'Composition';
      default:
        return 'Note';
    }
  }

  Color getTypeNoteColor() {
    switch (typeNote) {
      case 'interrogation':
        return Colors.blue;
      case 'devoir':
        return Colors.orange;
      case 'composition':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}