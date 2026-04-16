// lib/model/paiement_admin_model.dart

class PaiementAdminModel {
  final int id;
  final String reference;
  final int eleveId;
  final String eleveNom;
  final String elevePrenom;
  final String classe;
  final int numeroTranche;
  final String libelle;
  final String? description;
  final double montant;
  final String statut;
  final String? modePaiement;
  final String? datePaiement;
  final String createdAt;

  PaiementAdminModel({
    required this.id,
    required this.reference,
    required this.eleveId,
    required this.eleveNom,
    required this.elevePrenom,
    required this.classe,
    required this.numeroTranche,
    required this.libelle,
    this.description,
    required this.montant,
    required this.statut,
    this.modePaiement,
    this.datePaiement,
    required this.createdAt,
  });

  factory PaiementAdminModel.fromJson(Map<String, dynamic> json) {
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
    
    return PaiementAdminModel(
      id: json['id'] ?? 0,
      reference: json['reference']?.toString() ?? '',
      eleveId: json['eleve_id'] ?? 0,
      eleveNom: json['eleve_nom']?.toString() ?? '',
      elevePrenom: json['eleve_prenom']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      numeroTranche: json['numero_tranche'] ?? 0,
      libelle: json['libelle']?.toString() ?? '',
      description: json['description'],
      montant: montantValue,
      statut: json['statut']?.toString() ?? 'valide',
      modePaiement: json['mode_paiement'],
      datePaiement: json['date_paiement'],
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  String get montantFormatted => '${montant.toStringAsFixed(0)} FCFA';
  
  String get formattedDate {
    if (datePaiement != null && datePaiement!.isNotEmpty) {
      return datePaiement!;
    }
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return createdAt;
      }
    }
    return 'Date non spécifiée';
  }
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