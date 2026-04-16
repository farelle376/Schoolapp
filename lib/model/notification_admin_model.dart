// lib/model/notification_admin_model.dart

class NotificationAdminModel {
  final int id;
  final int parentId;
  final String parentNom;
  final String parentPrenom;
  final int? eleveId;
  final String? eleveNom;
  final String titre;
  final String message;
  final String type;
  final String createdAt;
  final bool estLu;
  final String? luAt;

  NotificationAdminModel({
    required this.id,
    required this.parentId,
    required this.parentNom,
    required this.parentPrenom,
    this.eleveId,
    this.eleveNom,
    required this.titre,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.estLu,
    this.luAt,
  });

  factory NotificationAdminModel.fromJson(Map<String, dynamic> json) {
    return NotificationAdminModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      parentNom: json['parent_nom']?.toString() ?? '',
      parentPrenom: json['parent_prenom']?.toString() ?? '',
      eleveId: json['eleve_id'],
      eleveNom: json['eleve_nom'],
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      createdAt: json['created_at']?.toString() ?? '',
      estLu: json['est_lu'] ?? false,
      luAt: json['lu_at'],
    );
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return createdAt;
    }
  }

  String get parentFullName => '$parentPrenom $parentNom';
  
  String get destinataire {
    if (eleveNom != null && eleveNom!.isNotEmpty) {
      return 'Pour ${eleveNom} (Parent: $parentFullName)';
    }
    return 'Général (Parent: $parentFullName)';
  }
}