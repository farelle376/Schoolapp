// lib/models/eleve_model.dart
import 'inscription_model.dart';

class Eleve {
  final int id;
  final String nom;
  final String prenom;
  final String? sexe;

  final List<Inscription>? inscriptions;

  Eleve({
    required this.id,
    required this.nom,
    required this.prenom,
    this.sexe,
    this.inscriptions,
  });

  factory Eleve.fromJson(Map<String, dynamic> json) {
    return Eleve(
      id: json['id']?? 0,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      sexe: json['sexe'],
      inscriptions: json['inscriptions'] != null
          ? (json['inscriptions'] as List)
              .map((e) => Inscription.fromJson(e))
              .toList()
          : null,
    );
  }
}