// lib/model/conversation_model.dart

import 'package:flutter/material.dart';

class ConversationModel {
  final int id;
  final int parentId;
  final int? eleveId;
  final String? eleveNom;
  final String sujet;
  final String statut;
  final Map<String, dynamic>? dernierMessage;
  final DateTime dernierMessageAt;
  final DateTime createdAt;
  final int messagesNonLus;

  ConversationModel({
    required this.id,
    required this.parentId,
    this.eleveId,
    this.eleveNom,
    required this.sujet,
    required this.statut,
    this.dernierMessage,
    required this.dernierMessageAt,
    required this.createdAt,
    this.messagesNonLus = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      eleveId: json['eleve_id'],
      eleveNom: json['eleve_nom'],
      sujet: json['sujet']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'ouvert',
      dernierMessage: json['dernier_message'] != null && json['dernier_message'] is Map
          ? Map<String, dynamic>.from(json['dernier_message'])
          : null,
      dernierMessageAt: DateTime.tryParse(json['dernier_message_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      messagesNonLus: json['messages_non_lus'] ?? 0,
    );
  }

  String get type {
    if (eleveId != null && eleveNom != null) {
      return 'eleve';
    }
    return 'general';
  }

  String get typeLabel {
    switch (type) {
      case 'eleve':
        return 'Avec ${eleveNom ?? "l'élève"}';
      default:
        return 'Discussion générale';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'eleve':
        return Icons.school;
      default:
        return Icons.people;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'eleve':
        return Colors.blue;
      default:
        return const Color(0xFFF47C3C);
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(dernierMessageAt);
    
    if (diff.inDays > 7) {
      return '${dernierMessageAt.day}/${dernierMessageAt.month}/${dernierMessageAt.year}';
    } else if (diff.inDays > 0) {
      return 'il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'il y a ${diff.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }
}