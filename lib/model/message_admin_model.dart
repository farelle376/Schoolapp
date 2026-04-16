
class MessageAdminModel {
  final int id;
  final int conversationId;
  final String message;
  final bool estDeAdmin;
  final String expediteur;
  final String createdAt;
  final bool estLu;
  final String? luAt;

  MessageAdminModel({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.estDeAdmin,
    required this.expediteur,
    required this.createdAt,
    required this.estLu,
    this.luAt,
  });

  factory MessageAdminModel.fromJson(Map<String, dynamic> json) {
    return MessageAdminModel(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      message: json['message']?.toString() ?? '',
      estDeAdmin: json['est_de_admin'] ?? false,
      expediteur: json['expediteur']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      estLu: json['est_lu'] ?? false,
      luAt: json['lu_at'],
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
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Hier ${formattedTime}';
      } else {
        return '${date.day}/${date.month}/${date.year} ${formattedTime}';
      }
    } catch (e) {
      return '';
    }
  }
}