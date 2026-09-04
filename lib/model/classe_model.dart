import 'package:flutter/material.dart';

class Classe {  //
  final int id;
  final String name;
  final int studentCount;
  final Color color;

  Classe({
    required this.id, 
    required this.name, 
    required this.studentCount, 
    required this.color
    });

  factory Classe.fromJson(Map<String, dynamic> json,) {
    List<Color> colors = [Color(0xFF0D2B4E), Color(0xFF1F4E79), Color(0xFFF47C3C)];
    return Classe(
      id: json['id'] ?? 0,
      name: json['nom'] ?? json['nom_classe'] ?? 'Inconnu',
      studentCount: json['eleves_count'] ?? 0,
      color: _getColorFromJson(json),
    );
  }
// Méthode utilitaire pour extraire la couleur
  static Color _getColorFromJson(Map<String, dynamic> json) {
    // Si la couleur est dans le JSON
    if (json['color'] != null) {
      return Color(json['color']);
    }
    // Sinon couleur par défaut
    return const Color(0xFF0D2B4E);
  }

  static Color getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFF0D2B4E),
      const Color(0xFF1F4E79),
      const Color(0xFFF47C3C),
      const Color(0xFF2ECC71),
      const Color(0xFFE74C3C),
    ];
    return colors[index % colors.length];
  }
}