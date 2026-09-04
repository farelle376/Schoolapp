// lib/screens/gestnotification.dart

import 'package:flutter/material.dart';
import '../services/admin_notification_service.dart';
import '../model/notification_admin_model.dart';
import 'conversation_detail_admin_screen.dart';
import '../model/conversation_admin_model.dart';

class GestNotificationPage extends StatefulWidget {
  // Appelé après qu'une conversation ait été consultée (donc des messages
  // potentiellement marqués lus côté serveur), pour que la pastille de la
  // barre latérale (gérée par AdminDashboardPage, un widget parent) se
  // remette à jour immédiatement au lieu d'attendre le prochain sondage.
  final VoidCallback? onConversationRead;

  const GestNotificationPage({Key? key, this.onConversationRead}) : super(key: key);

  @override
  _GestNotificationPageState createState() => _GestNotificationPageState();
}

class _GestNotificationPageState extends State<GestNotificationPage> {
  final AdminNotificationService _service = AdminNotificationService();
  List<NotificationAdminModel> _notifications = [];
  List<ConversationAdminModel> _conversations = [];
  bool _isLoading = true;
  bool _showNotifications = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _service.getNotifications();
      final conversations = await _service.getConversations();
      
      if (!mounted) return;
      
      setState(() {
        _notifications = notifications;
        _conversations = conversations;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(NotificationAdminModel notification) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          'Confirmation',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Supprimer la notification "${notification.titre}" ?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      final success = await _service.deleteNotification(notification.id);
      if (success) {
        await _loadData();
        _showSnackBar('Notification supprimée', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddNotificationDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    int? selectedParentId;
    int? selectedEleveId;
    String titre = '';
    String message = '';
    String type = 'info';
    List<Map<String, dynamic>> parents = [];
    List<Map<String, dynamic>> eleves = [];
    bool isLoadingParents = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (parents.isEmpty && isLoadingParents) {
            _service.getParents().then((p) {
              setStateDialog(() {
                parents = p;
                isLoadingParents = false;
              });
            });
            _service.getEleves().then((e) {
              setStateDialog(() {
                eleves = e;
              });
            });
          }

          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
            title: Text(
              'Ajouter une notification',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Parent destinataire',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      items: parents.map((p) {
                        String nom = p['prenom']?.toString() ?? '';
                        String prenom = p['nom']?.toString() ?? '';
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text('$nom $prenom'),
                        );
                      }).toList(),
                      onChanged: (value) => selectedParentId = value,
                      validator: (v) => v == null ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Élève concerné (optionnel)',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      items: [
                        const DropdownMenuItem<int>(value: null, child: Text('-- Général --')),
                        ...eleves.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text(e['nom_complet']?.toString() ?? ''),
                        )),
                      ],
                      onChanged: (value) => selectedEleveId = value,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFF47C3C)),
                        ),
                      ),
                      onChanged: (value) => titre = value,
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFF47C3C)),
                        ),
                      ),
                      onChanged: (value) => message = value,
                      validator: (v) => v!.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: type,
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFF47C3C)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'info', child: Text('Information')),
                        DropdownMenuItem(value: 'success', child: Text('Succès')),
                        DropdownMenuItem(value: 'warning', child: Text('Avertissement')),
                        DropdownMenuItem(value: 'danger', child: Text('Urgent')),
                      ],
                      onChanged: (value) => type = value!,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    if (!mounted) return;
                    
                    setState(() => _isLoading = true);
                    
                    final success = await _service.createNotification({
                      'parent_id': selectedParentId,
                      'eleve_id': selectedEleveId,
                      'titre': titre,
                      'message': message,
                      'type': type,
                    });
                    
                    if (!mounted) return;
                    
                    if (success) {
                      await _loadData();
                      _showSnackBar('Notification envoyée', isError: false);
                    } else {
                      _showSnackBar('Erreur lors de l\'envoi');
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications et Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildTabs(),
                    Expanded(
                      child: _showNotifications
                          ? _buildNotificationsList()
                          : _buildConversationsList(),
                    ),
                  ],
                ),
      floatingActionButton: _showNotifications
          ? FloatingActionButton(
              onPressed: _showAddNotificationDialog,
              backgroundColor: const Color(0xFFF47C3C),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTabs() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showNotifications = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showNotifications ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade800 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: _showNotifications ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showNotifications = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showNotifications ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade800 : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Messages (${_conversations.length})',
                    style: TextStyle(
                      color: !_showNotifications ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          'Aucune notification',
          style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        return Card(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(notif.type).withOpacity(0.1),
              child: Icon(_getTypeIcon(notif.type), color: _getTypeColor(notif.type)),
            ),
            title: Text(
              notif.titre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  notif.destinataire,
                  style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
                ),
                Text(
                  notif.formattedDate,
                  style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNotification(notif),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_conversations.isEmpty) {
      return Center(
        child: Text(
          'Aucun message',
          style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return Card(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: conv.messagesNonLus > 0 
                  ? (isDarkMode ? Colors.red.withOpacity(0.2) : Colors.red.withOpacity(0.1))
                  : (isDarkMode ? Colors.grey.shade700 : Colors.grey[200]),
              child: Icon(
                Icons.message,
                color: conv.messagesNonLus > 0 ? Colors.red : (isDarkMode ? Colors.grey.shade500 : Colors.grey),
              ),
            ),
            title: Text(
              conv.sujet,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.parentFullName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                  ),
                ),
                if (conv.eleveNom != null && conv.eleveNom!.isNotEmpty)
                  Text(
                    conv.classe != null && conv.classe!.isNotEmpty
                        ? '👤 ${conv.eleveNom} — ${conv.classe}'
                        : '👤 ${conv.eleveNom}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                    ),
                  ),
                if (conv.dernierMessage != null)
                  Text(
                    conv.dernierMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (conv.messagesNonLus > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conv.messagesNonLus}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                Text(
                  conv.formattedDate,
                  style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400]),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationDetailAdminScreen(
                    conversationId: conv.id,
                    parentName: conv.parentFullName,
                    sujet: conv.sujet,
                    eleveNom: conv.eleveNom,
                    classe: conv.classe,
                  ),
                ),
              ).then((_) {
                _loadData();
                widget.onConversationRead?.call();
              });
            },
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'danger': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'danger': return Icons.error;
      default: return Icons.info;
    }
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}