// lib/model/scolarite_model.dart

class ElevePaiementModel {
  final int id;
  final String nom;
  final String prenom;
  final String classe;
  final bool estPaye;
  final double montant;
  final String? datePaiement;

  ElevePaiementModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.estPaye,
    required this.montant,
    this.datePaiement,
  });

  factory ElevePaiementModel.fromJson(Map<String, dynamic> json) {
    double montantValue = 0.0;
    if (json['montant'] != null) {
      if (json['montant'] is double) {
        montantValue = json['montant'];
      } else if (json['montant'] is int) {
        montantValue = (json['montant'] as int).toDouble();
      } else if (json['montant'] is String) {
        montantValue = double.tryParse(json['montant']) ?? 0.0;
      }
    }
    
    return ElevePaiementModel(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      estPaye: json['est_paye'] ?? false,
      montant: montantValue,
      datePaiement: json['date_paiement'],
    );
  }

  String get fullName => '$prenom $nom';
}

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