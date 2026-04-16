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

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.estLu,
    required this.createdAt,
    this.luAt,
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
    );
  }
  Color getColor() {
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