// lib/model/paiement_model.dart - Version simplifiée

class PaiementModel {
  final int id;
  final String reference;
  final int numeroTranche;
  final String libelle;
  final double montant;
  final String montantFormatted;
  final String statut;
  final String? description;
  final String? datePaiement;
  final String? pdfPath;
  final String? modePaiement;

  PaiementModel({
    required this.id,
    required this.reference,
    required this.numeroTranche,
    required this.libelle,
    required this.montant,
    required this.montantFormatted,
    required this.statut,
    this.description,
    this.datePaiement,
    this.pdfPath,
    this.modePaiement,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
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
    
    return PaiementModel(
      id: json['id'] ?? 0,
      reference: json['reference']?.toString() ?? '',
      numeroTranche: json['numero_tranche'] ?? 0,
      libelle: json['libelle']?.toString() ?? '',
      montant: montantValue,
      montantFormatted: '${montantValue.toStringAsFixed(0)} FCFA',
      statut: json['statut']?.toString() ?? 'en_attente',
      description: json['description'],
      datePaiement: json['date_paiement'],
      pdfPath: json['pdf_path'],
      modePaiement: json['mode_paiement'],
    );
  }

  // Getter pour la date formatée
  String get formattedDate {
    if (datePaiement == null || datePaiement!.isEmpty) {
      return 'Date non spécifiée';
    }
    
    try {
      // Format: 2026-04-01T14:49:52.000000Z
      final dateStr = datePaiement!.split('T')[0];
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateStr;
    } catch (e) {
      return datePaiement!;
    }
  }

  bool get estValide => statut == 'valide';
  bool get estEnAttente => statut == 'en_attente';
  bool get estRefuse => statut == 'refuse';
}