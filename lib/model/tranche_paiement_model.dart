// lib/model/tranche_paiement_model.dart

class TranchePaiementModel {
  final int id;
  final int numeroTranche;
  final String libelle;
  final double montant;
  final String montantFormatted;
  final String? description;
  final String? dateLimite;
  final String statut;
  final bool estPaye;

  TranchePaiementModel({
    required this.id,
    required this.numeroTranche,
    required this.libelle,
    required this.montant,
    required this.montantFormatted,
    this.description,
    this.dateLimite,
    required this.statut,
    required this.estPaye,
  });

  factory TranchePaiementModel.fromJson(Map<String, dynamic> json) {
    // Convertir le montant correctement (peut être String ou double)
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
    
    return TranchePaiementModel(
      id: json['id'] ?? 0,
      numeroTranche: json['numero_tranche'] ?? 0,
      libelle: json['libelle']?.toString() ?? '',
      montant: montantValue,
      montantFormatted: _formatMontant(montantValue),
      description: json['description'],
      dateLimite: json['date_limite'],
      statut: json['statut']?.toString() ?? 'non_paye',
      estPaye: json['statut'] == 'paye',
    );
  }

  static String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }
}