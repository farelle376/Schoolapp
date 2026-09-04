// lib/models/schedule_model.dart

class ScheduleModel {
  final int id;
  final int? anneeScolaireId;
  final String matiere;
  final String professeur;
  final String heureDebut;
  final String heureFin;
  final String jour;
  final String typeCours;
  final String? classe;

  ScheduleModel({
    required this.id,
    this.anneeScolaireId,
    required this.matiere,
    required this.professeur,
    required this.heureDebut,
    required this.heureFin,
    required this.jour,
    required this.typeCours,
    this.classe,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    String heureDebut = json['heure_debut']?.toString() ?? '';
    String heureFin = json['heure_fin']?.toString() ?? '';
    
    if (heureDebut.contains('T')) {
      heureDebut = heureDebut.split('T')[1].split(':').take(2).join(':');
    }
    if (heureFin.contains('T')) {
      heureFin = heureFin.split('T')[1].split(':').take(2).join(':');
    }
    
    return ScheduleModel(
      id: json['id'] ?? 0,
      anneeScolaireId: json['annee_scolaire_id'],
      matiere: json['matiere']?.toString() ?? '',
      professeur: json['professeur']?.toString() ?? '',
      heureDebut: heureDebut,
      heureFin: heureFin,
      jour: json['jour']?.toString() ?? '',
      typeCours: json['type_cours']?.toString() ?? '',
      classe: json['classe']?.toString(),
    );
  }

  static List<ScheduleModel> fromList(List<dynamic> list) {
    return list.map((item) => ScheduleModel.fromJson(item)).toList();
  }
}