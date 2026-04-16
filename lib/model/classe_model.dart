import 'package:flutter/material.dart';

class Classe {  // <--- Vérifie que le "C" est majuscule ici
  final int id;
  final String name;
  final int studentCount;
  final Color color;

  Classe({required this.id, required this.name, required this.studentCount, required this.color});

  factory Classe.fromJson(Map<String, dynamic> json, int index) {
    List<Color> colors = [Color(0xFF0D2B4E), Color(0xFF1F4E79), Color(0xFFF47C3C)];
    return Classe(
      id: json['id'] ?? 0,
      name: json['nom_classe'] ?? 'Inconnu',
      studentCount: json['eleves_count'] ?? 0,
      color: colors[index % colors.length],
    );
  }
}