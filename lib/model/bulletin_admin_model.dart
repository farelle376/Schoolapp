
class ClasseInfo {
  final int id;
  final String nom;

  ClasseInfo({
    required this.id,
    required this.nom,
  });

  factory ClasseInfo.fromJson(Map<String, dynamic> json) {
    return ClasseInfo(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
    );
  }
}

class BulletinAdminModel {
  final int id;
  final int eleveId;
  final String eleveNom;
  final String elevePrenom;
  final String classe;
  final String trimestre;
  final double moyenneGenerale;
  final String mention;
  final String appreciation;
  final List<dynamic> notes;
  final DateTime createdAt;

  BulletinAdminModel({
    required this.id,
    required this.eleveId,
    required this.eleveNom,
    required this.elevePrenom,
    required this.classe,
    required this.trimestre,
    required this.moyenneGenerale,
    required this.mention,
    required this.appreciation,
    required this.notes,
    required this.createdAt,
  });

  factory BulletinAdminModel.fromJson(Map<String, dynamic> json) {
    return BulletinAdminModel(
      id: json['id'] ?? 0,
      eleveId: json['eleve_id'] ?? 0,
      eleveNom: json['eleve_nom']?.toString() ?? '',
      elevePrenom: json['eleve_prenom']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      trimestre: json['trimestre']?.toString() ?? '1',
      moyenneGenerale: (json['moyenne_generale'] ?? 0).toDouble(),
      mention: json['mention']?.toString() ?? '',
      appreciation: json['appreciation']?.toString() ?? '',
      notes: json['notes'] ?? [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get fullName => '$elevePrenom $eleveNom';
}