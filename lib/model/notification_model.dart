// lib/models/notification_model.dart

class NotificationModel {
  final int id;
  final String type;
  final String titre;
  final String contenu;
  final String createdAt;
  final String eleve;
  final bool lu;
  
  NotificationModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.createdAt,
    required this.eleve,
    required this.lu,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      titre: json['titre'],
      contenu: json['contenu'],
      createdAt: json['created_at'],
      eleve: json['eleve'],
      lu: json['lu'] ?? false,
    );
  }
}