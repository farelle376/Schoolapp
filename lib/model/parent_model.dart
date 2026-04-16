// lib/model/parent_model.dart
import 'package:flutter/material.dart';
class ParentModel {
  final int id;
  final String nom;
  final String prenom;
  final String typeParent;
  final String numTelephone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ParentModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.typeParent,
    required this.numTelephone,
    this.email,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      typeParent: json['type_parent']?.toString() ?? 'pere',
      numTelephone: json['num_telephone']?.toString() ?? '',
      email: json['email'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  String get fullName => '$prenom $nom';
  
  String get initials {
    String initiales = '';
    if (prenom.isNotEmpty) initiales += prenom[0].toUpperCase();
    if (nom.isNotEmpty) initiales += nom[0].toUpperCase();
    return initiales.isEmpty ? '?' : initiales;
  }
  
  String get typeLabel {
    switch (typeParent) {
      case 'pere': return 'Père';
      case 'mere': return 'Mère';
      case 'tuteur': return 'Tuteur';
      default: return 'Parent';
    }
  }
  
  Color get typeColor {
    switch (typeParent) {
      case 'pere': return Colors.blue;
      case 'mere': return Colors.pink;
      case 'tuteur': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  IconData get typeIcon {
    switch (typeParent) {
      case 'pere': return Icons.man;
      case 'mere': return Icons.woman;
      case 'tuteur': return Icons.person;
      default: return Icons.person;
    }
  }
}