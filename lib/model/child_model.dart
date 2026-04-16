// lib/models/child_model.dart

class ChildModel {
  final int id;
  final String nom;
  final String prenom;
  final String nomComplet;
  final String classe;
  final double? moyenneGenerale;
  final List<dynamic> dernieresNotes;
  
  ChildModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.nomComplet,
    required this.classe,
    this.moyenneGenerale,
    required this.dernieresNotes,
  });
  
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    // Récupérer les valeurs avec des valeurs par défaut
    final id = json['id'] ?? 0;
    final nom = json['nom']?.toString() ?? '';
    final prenom = json['prenom']?.toString() ?? '';
    final nomComplet = json['nom_complet']?.toString() ?? '';
    final classe = json['classe']?.toString() ?? '';
    
    double? moyenneGenerale;
    if (json['moyenne_generale'] != null) {
      if (json['moyenne_generale'] is double) {
        moyenneGenerale = json['moyenne_generale'];
      } else if (json['moyenne_generale'] is int) {
        moyenneGenerale = (json['moyenne_generale'] as int).toDouble();
      } else if (json['moyenne_generale'] is String) {
        moyenneGenerale = double.tryParse(json['moyenne_generale']);
      }
    }
    
    return ChildModel(
      id: id,
      nom: nom,
      prenom: prenom,
      nomComplet: nomComplet,
      classe: classe,
      moyenneGenerale: moyenneGenerale,
      dernieresNotes: json['dernieres_notes'] ?? [],
    );
  }
  
  // Méthode pour obtenir les initiales
  String getInitiales() {
    String initiales = '';
    if (prenom.isNotEmpty) {
      initiales += prenom[0].toUpperCase();
    }
    if (nom.isNotEmpty) {
      initiales += nom[0].toUpperCase();
    }
    return initiales.isEmpty ? '?' : initiales;
  }
}