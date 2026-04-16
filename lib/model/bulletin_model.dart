// lib/models/bulletin_model.dart

class BulletinDetailModel {
  final int id;
  final EleveInfo eleve;
  final String trimestre;
  final double moyenneGenerale;
  final String mention;
  final int rang;
  final int totalEleves;
  final String? appreciationGenerale;
  final List<MatiereNote> matieres;

  BulletinDetailModel({
    required this.id,
    required this.eleve,
    required this.trimestre,
    required this.moyenneGenerale,
    required this.mention,
    required this.rang,
    required this.totalEleves,
    this.appreciationGenerale,
    required this.matieres,
  });

  factory BulletinDetailModel.fromJson(Map<String, dynamic> json) {
    return BulletinDetailModel(
      id: json['id'],
      eleve: EleveInfo.fromJson(json['eleve']),
      trimestre: json['trimestre'].toString(),
      moyenneGenerale: (json['moyenne_generale'] ?? 0).toDouble(),
      mention: json['mention'] ?? '',
      rang: json['rang'] ?? 0,
      totalEleves: json['total_eleves'] ?? 0,
      appreciationGenerale: json['appreciation_generale'],
      matieres: (json['matieres'] as List)
          .map((m) => MatiereNote.fromJson(m))
          .toList(),
    );
  }
}

class EleveInfo {
  final int id;
  final String nom;
  final String prenom;
  final String classe;
  final String? matricule;

  EleveInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.classe,
    this.matricule,
  });

  String get fullName => '$nom $prenom';

  factory EleveInfo.fromJson(Map<String, dynamic> json) {
    return EleveInfo(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      classe: json['classe'],
      matricule: json['matricule'],
    );
  }
}

class MatiereNote {
  final String matiere;
  final double note;
  final double moyenneClasse;
  final int rang;
  final String appreciation;
  final double coefficient;

  MatiereNote({
    required this.matiere,
    required this.note,
    required this.moyenneClasse,
    required this.rang,
    required this.appreciation,
    required this.coefficient,
  });

  factory MatiereNote.fromJson(Map<String, dynamic> json) {
    return MatiereNote(
      matiere: json['matiere'],
      note: (json['note'] ?? 0).toDouble(),
      moyenneClasse: (json['moyenne_classe'] ?? 0).toDouble(),
      rang: json['rang'] ?? 0,
      appreciation: json['appreciation'] ?? '',
      coefficient: (json['coefficient'] ?? 1).toDouble(),
    );
  }
}