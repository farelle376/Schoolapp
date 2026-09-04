// lib/models/scolarite_model.dart

import 'package:flutter/material.dart';

class ElevePaiementModel {
  final int id;
  final int? inscriptionId;
  final String nom;
  final String prenom;
  final String classe;
  final bool estPaye;
  final double montant;
  final String? datePaiement;

  ElevePaiementModel({
    required this.id,
    this.inscriptionId,
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
      inscriptionId: json['inscription_id'],
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

// Classe pour représenter une tranche de paiement
class TrancheInfo {
  final int numero;
  final String libelle;
  final double montant;
  final bool estPaye;
  final String? dateLimite;
  final String? datePaiement;
  final int? inscriptionId;

  TrancheInfo({
    required this.numero,
    required this.libelle,
    required this.montant,
    required this.estPaye,
    this.dateLimite,
    this.datePaiement,
    this.inscriptionId,
  });

  factory TrancheInfo.fromJson(Map<String, dynamic> json) {
    double montantValue = 40000;
    if (json['montant'] != null) {
      if (json['montant'] is double) {
        montantValue = json['montant'];
      } else if (json['montant'] is int) {
        montantValue = (json['montant'] as int).toDouble();
      } else if (json['montant'] is String) {
        montantValue = double.tryParse(json['montant']) ?? 40000;
      }
    }
    
    return TrancheInfo(
      numero: json['numero'] ?? 0,
      libelle: json['libelle'] ?? 'Tranche ${json['numero']}',
      montant: montantValue,
      estPaye: json['est_paye'] ?? false,
      dateLimite: json['date_limite'],
      datePaiement: json['date_paiement'],
      inscriptionId: json['inscription_id'],
    );
  }

  String get statutTexte => estPaye ? 'Payé' : 'Impayé';
  Color get statutCouleur => estPaye ? Colors.green : Colors.red;
  Color get statutBackground => estPaye ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
}

// Modèle Élève avec toutes ses tranches
class EleveAvecTranches {
  final int id;                       
  final int? inscriptionId;
  final String nom;
  final String prenom;
  final int classeId;
  final String classeNom;
  final List<TrancheInfo> _tranchesList;

  EleveAvecTranches({
    required this.id,
    this.inscriptionId,
    required this.nom,
    required this.prenom,
    required this.classeId,
    required this.classeNom,
    required List<TrancheInfo> tranches,
  }) : _tranchesList = tranches;

  String get fullName => '$prenom $nom';
  
  List<TrancheInfo> get tranches => _tranchesList;

  bool getTrancheStatus(int tranche) {
    final t = _tranchesList.firstWhere(
      (t) => t.numero == tranche,
      orElse: () => TrancheInfo(numero: tranche, libelle: '', montant: 0, estPaye: false)
    );
    return t.estPaye;
  }

  String? getTrancheDate(int tranche) {
    final t = _tranchesList.firstWhere(
      (t) => t.numero == tranche,
      orElse: () => TrancheInfo(numero: tranche, libelle: '', montant: 0, estPaye: false)
    );
    return t.datePaiement;
  }

  double getTrancheMontant(int tranche) {
    final t = _tranchesList.firstWhere(
      (t) => t.numero == tranche,
      orElse: () => TrancheInfo(numero: tranche, libelle: '', montant: 40000, estPaye: false)
    );
    return t.montant;
  }

  TrancheInfo? getTranche(int tranche) {
    try {
      return _tranchesList.firstWhere((t) => t.numero == tranche);
    } catch (e) {
      return null;
    }
  }

  bool get isCompletelyPaid {
    for (var tranche in _tranchesList) {
      if (!tranche.estPaye) return false;
    }
    return true;
  }

  int get paidTranchesCount {
    return _tranchesList.where((t) => t.estPaye).length;
  }

  double get totalPaidAmount {
    double total = 0;
    for (var tranche in _tranchesList) {
      if (tranche.estPaye) {
        total += tranche.montant;
      }
    }
    return total;
  }

  double get totalRemainingAmount {
    double total = 0;
    for (var tranche in _tranchesList) {
      if (!tranche.estPaye) {
        total += tranche.montant;
      }
    }
    return total;
  }

  factory EleveAvecTranches.fromJson(
    Map<String, dynamic> json,
    String classeNom,
    int classeId,
  ) {
    final List<TrancheInfo> tranchesList = [];
    
    if (json['paiements'] != null && json['paiements'] is List) {
      for (var paiement in json['paiements']) {
        tranchesList.add(TrancheInfo.fromJson(paiement));
      }
    }
    
    tranchesList.sort((a, b) => a.numero.compareTo(b.numero));
    
    return EleveAvecTranches(
      id: json['id'] ?? 0,
      inscriptionId: json['inscription_id'],
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      classeId: classeId,
      classeNom: classeNom,
      tranches: tranchesList,
    );
  }
}