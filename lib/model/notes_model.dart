// lib/models/note_model.dart

class NoteModel {
  final int id;
  final String matiere;
  final double note;
  final String trimestre;
  final String appreciation;
  final String date;
  final bool isValidated;
  
  NoteModel({
    required this.id,
    required this.matiere,
    required this.note,
    required this.trimestre,
    required this.appreciation,
    required this.date,
    required this.isValidated,
  });
  
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      matiere: json['matiere'],
      note: json['note'].toDouble(),
      trimestre: json['trimestre'],
      appreciation: json['appreciation'],
      date: json['date'],
      isValidated: json['is_validated'],
    );
  }
}