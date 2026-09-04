// lib/models/notification_model.dart

import 'package:flutter/material.dart'; 

class NotificationModel {
  final int id;
  final String titre;
  final String message;
  final String type;
  final bool estLu;
  final String createdAt;
  final String? luAt;
  // Non-null uniquement pour une notification générée par un nouveau
  // message admin → parent (voir AdminConversationController::sendMessage).
  // Permet de sauter directement dans la bonne discussion au tap.
  final int? conversationId;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.estLu,
    required this.createdAt,
    this.luAt,
    this.conversationId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      estLu: json['est_lu'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      luAt: json['lu_at'],
      conversationId: json['conversation_id'],
    );
  }

  bool get estUnMessage => conversationId != null;

  Color getColor() {
    if (estUnMessage) return const Color(0xFFF47C3C);
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'danger':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData getIcon() {
    if (estUnMessage) return Icons.chat_bubble;
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'danger':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}