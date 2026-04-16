// lib/screens/childrenlistpage.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'studentDashbordpage.dart';  // ← Utilisez le nom exact de votre fichier
import 'conversations_screen.dart';
import 'notifications_screen.dart';
import 'parentloginpage.dart';

class ChildrenListPage extends StatefulWidget {
  final Map<String, dynamic> parentData;

  const ChildrenListPage({Key? key, required this.parentData}) : super(key: key);

  @override
  _ChildrenListPageState createState() => _ChildrenListPageState();
}

class _ChildrenListPageState extends State<ChildrenListPage> {
  final ApiService _api = ApiService();
  int _unreadNotificationsCount = 0;
  int _unreadMessagesCount = 0;
  bool _isLoading = true;
  List<dynamic> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _loadUnreadCounts();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      await _api.reloadToken();
      
      final notifResponse = await _api.get('/parent/notifications/unread-count');
      if (notifResponse['success'] == true && mounted) {
        setState(() {
          _unreadNotificationsCount = notifResponse['count'] ?? 0;
        });
      }
      
      final messagesResponse = await _api.get('/parent/conversations/unread-count');
      if (messagesResponse['success'] == true && mounted) {
        setState(() {
          _unreadMessagesCount = messagesResponse['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Erreur chargement compteurs: $e');
    }
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _api.reloadToken();
      
      final response = await _api.get('/parent/children');
      
      if (response['success'] == true && mounted) {
        if (response['data'] != null && response['data'] is List) {
          setState(() {
            _children = response['data'];
          });
        }
      }
    } catch (e) {
      print('Erreur: $e');
      if (e.toString().contains('401')) {
        _redirectToLogin();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ParentLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'School',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TextSpan(
                text: 'App',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C)),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        actions: [
          // Badge messages
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConversationsScreen()),
                  ).then((_) => _loadUnreadCounts());
                },
              ),
              if (_unreadMessagesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadMessagesCount > 9 ? '9+' : '$_unreadMessagesCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Badge notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationsScreen()),
                  ).then((_) => _loadUnreadCounts());
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileMenu(context),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF47C3C),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Center(
                        child: Text(
                          widget.parentData['initiales'] ?? '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bonjour,', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        Text(widget.parentData['prenom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Titre "Mes enfants"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Text('Mes enfants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF47C3C), borderRadius: BorderRadius.circular(12)),
                    child: Text('${_children.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
            // Liste des enfants
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _children.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.family_restroom, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('Aucun enfant enregistré', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Text('Veuillez contacter l\'administration', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _children.length,
                            itemBuilder: (context, index) {
                              final child = _children[index];
                              return _buildChildCard(child, index);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child, int index) {
    final childId = child['id'] ?? 0;
    String childName = child['nom_complet'] ?? '${child['prenom'] ?? ''} ${child['nom'] ?? ''}'.trim();
    if (childName.isEmpty) childName = 'Élève $childId';
    final childClass = child['classe'] ?? 'Classe non assignée';
    
    final List<Color> avatarColors = [const Color(0xFFF47C3C), Colors.green, Colors.blue, Colors.purple, Colors.orange];
    final Color avatarColor = avatarColors[index % avatarColors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboardPage(  // ← Assurez-vous que c'est le bon nom
                childId: childId,
                childName: childName,
                childClass: childClass,
                parentInitiales: widget.parentData['initiales'] ?? '',
                parentNom: widget.parentData['prenom'] ?? '',
                parentData: widget.parentData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: avatarColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(
                  child: Text(_getInitiales(childName), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: avatarColor)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(childName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 5),
                        Expanded(child: Text(childClass, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitiales(String nomComplet) {
    if (nomComplet.isEmpty) return '?';
    List<String> parts = nomComplet.split(' ');
    String initiales = '';
    for (var part in parts) {
      if (part.isNotEmpty) initiales += part[0].toUpperCase();
    }
    return initiales.length > 2 ? initiales.substring(0, 2) : initiales;
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(color: Color(0xFFF47C3C), shape: BoxShape.circle),
                    child: Center(child: Text(widget.parentData['initiales'] ?? '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.parentData['prenom'] ?? ''} ${widget.parentData['nom'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(widget.parentData['email'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Se déconnecter'),
                onTap: () async {
                  Navigator.pop(context);
                  await _api.logout();
                  if (mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ParentLoginPage()));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}