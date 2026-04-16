// lib/model/schedule_model.dart

class ScheduleModel {
  final int id;
  final String matiere;
  final String professeur;
  final String heureDebut;
  final String heureFin;
  final String jour;
  final String typeCours;

  ScheduleModel({
    required this.id,
    required this.matiere,
    required this.professeur,
    required this.heureDebut,
    required this.heureFin,
    required this.jour,
    required this.typeCours,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    // Nettoyer les heures si nécessaire
    String heureDebut = json['heure_debut']?.toString() ?? '';
    String heureFin = json['heure_fin']?.toString() ?? '';
    
    // Si l'heure est au format datetime complet, extraire seulement HH:MM
    if (heureDebut.contains('T')) {
      heureDebut = heureDebut.split('T')[1].split(':').take(2).join(':');
    }
    if (heureFin.contains('T')) {
      heureFin = heureFin.split('T')[1].split(':').take(2).join(':');
    }
    
    return ScheduleModel(
      id: json['id'] ?? 0,
      matiere: json['matiere']?.toString() ?? '',
      professeur: json['professeur']?.toString() ?? '',
      heureDebut: heureDebut,
      heureFin: heureFin,
      jour: json['jour']?.toString() ?? '',
      typeCours: json['type_cours']?.toString() ?? '',
    );
  }

  static List<ScheduleModel> fromList(List<dynamic> list) {
    return list.map((item) => ScheduleModel.fromJson(item)).toList();
  }
}