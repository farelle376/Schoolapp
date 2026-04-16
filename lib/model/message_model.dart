// lib/model/message_model.dart

class MessageModel {
  final int id;
  final String message;
  final String type;
  final bool estDeParent;
  final String expediteur;
  final String createdAt;
  final bool estLu;
  final Map<String, dynamic>? eleve;

  MessageModel({
    required this.id,
    required this.message,
    required this.type,
    required this.estDeParent,
    required this.expediteur,
    required this.createdAt,
    required this.estLu,
    this.eleve,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      estDeParent: json['est_de_parent'] ?? false,
      expediteur: json['expediteur']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      estLu: json['est_lu'] ?? false,
      eleve: json['eleve'],
    );
  }

  String get formattedTime {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return 'Aujourd\'hui ${formattedTime}';
      } else if (messageDate == today.subtract(Duration(days: 1))) {
        return 'Hier ${formattedTime}';
      } else {
        return '${date.day}/${date.month}/${date.year} ${formattedTime}';
      }
    } catch (e) {
      return '';
    }
  }
}