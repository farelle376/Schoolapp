// lib/models/child_model.dart

class ChildModel {
  final int id;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String? classe;
  final int? classeId; 
  final int? classeAnneeId;  
  final String? anneeScolaire;
  final int? anneeScolaireId;
  final int? inscriptionId;
  final double? moyenneGenerale;
  final List<dynamic> dernieresNotes;

  ChildModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    this.classe,
    this.classeId,
    this.classeAnneeId,
    this.anneeScolaire,
    this.anneeScolaireId,
    this.inscriptionId,
    this.moyenneGenerale,
    required this.dernieresNotes,
  });
  
  factory ChildModel.fromJson(Map<String, dynamic> json) {
     return ChildModel(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      nomComplet: json['nom_complet']?.toString() ?? '',
      classe: json['classe']?.toString(),
      classeId: json['classe_id'],
      classeAnneeId: json['classe_annee_id'],
      anneeScolaire: json['annee_scolaire']?.toString(),
      anneeScolaireId: json['annee_scolaire_id'],
      inscriptionId: json['inscription_id'],
      moyenneGenerale: json['moyenne_generale']?.toDouble(),
      dernieresNotes: json['dernieres_notes'] ?? [],
    );
  }
  
  // Méthode pour obtenir les initiales
  String getInitiales() {
    if (prenom.isNotEmpty && nom.isNotEmpty) {
      return '${prenom[0].toUpperCase()}${nom[0].toUpperCase()}';
    }
    return '?';
  }
}