class ConversationAdminModel {
  final int id;
  final int parentId;
  final String parentNom;
  final String parentPrenom;
  final int? eleveId;
  final String? eleveNom;
  final String sujet;
  final String statut;
  final int messagesNonLus;
  final String createdAt;
  final String? dernierMessage;

  ConversationAdminModel({
    required this.id,
    required this.parentId,
    required this.parentNom,
    required this.parentPrenom,
    this.eleveId,
    this.eleveNom,
    required this.sujet,
    required this.statut,
    required this.messagesNonLus,
    required this.createdAt,
    this.dernierMessage,
  });

  factory ConversationAdminModel.fromJson(Map<String, dynamic> json) {
    return ConversationAdminModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      parentNom: json['parent_nom']?.toString() ?? '',
      parentPrenom: json['parent_prenom']?.toString() ?? '',
      eleveId: json['eleve_id'],
      eleveNom: json['eleve_nom'],
      sujet: json['sujet']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'ouvert',
      messagesNonLus: json['messages_non_lus'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      dernierMessage: json['dernier_message'],
    );
  }

  String get parentFullName => '$parentPrenom $parentNom';
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return createdAt;
    }
  }
}