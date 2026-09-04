// lib/screens/admindashboardpage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../services/admin_notification_service.dart';
import '../model/admin_model.dart';
import 'adminloginpage.dart';
import 'gestparent.dart'; 
import 'gestpaiement.dart';
import 'gestemploi.dart';
import 'gestnotification.dart';
import 'gestscolarite.dart';
import 'gestbulletin.dart';
import 'gestion_eleves_page.dart';
import 'gestion_notes_admin_page.dart';
import 'parametres_pages.dart';
import 'gestion_classmat_page.dart';
import 'gestion_professeurs_page.dart';
import 'gestmontants.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminAuthService _authService = AdminAuthService();
  final AdminNotificationService _notifService = AdminNotificationService();
  AdminModel? _admin;
  int _selectedIndex = 0;
  bool _isMenuOpen = true;
  int _unreadMessagesCount = 0;
  Timer? _unreadPollTimer;

  late final List<Widget> _pages;
  late final List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    _admin = _authService.currentAdmin;

    _pages = [
      GestionElevesPage(),
      GestionClassmatPage(),
      GestionProfesseursPage(),
      GestParentPage(),
      GestPaiementPage(),
      GestEmploiPage(),
      GestionNotesAdminPage(),
      GestScolaritePage(),
      GestMontantsPage(),
      GestBulletinPage(),
      GestNotificationPage(onConversationRead: _loadUnreadMessagesCount),
      ParametresPage(),
      
    ];
    
    _menuItems = [
      {'icon': Icons.school, 'title': 'Gestion des élèves', 'subtitle': 'Gérer les inscriptions et les classes', 'color': Colors.green, 'index': 0},
      {'icon': Icons.class_, 'title': 'Classes et Matières', 'subtitle': 'Gestion des classes et des matières', 'color': const Color.fromARGB(255, 150, 188, 254), 'index': 1},
      {'icon': Icons.person_outline, 'title': 'Gestion des professeurs', 'subtitle': 'Gérer les ajouts, modifications et suppressions', 'color': const Color.fromARGB(255, 195, 195, 30), 'index': 2},
      {'icon': Icons.people, 'title': 'Gestion des parents', 'subtitle': 'Ajouter, modifier, supprimer des parents', 'color': const Color.fromARGB(255, 2, 114, 242), 'index': 3},
      {'icon': Icons.payment, 'title': 'Gestion des paiements', 'subtitle': 'Suivi des transactions', 'color': Colors.orange, 'index': 4},
      {'icon': Icons.calendar_today, 'title': 'Emploi du temps', 'subtitle': 'Gérer les emplois du temps', 'color': Colors.purple, 'index': 5},
      {'icon': Icons.grade, 'title': 'Gestion des notes', 'subtitle': 'Consulter toutes les notes', 'color': const Color.fromARGB(255, 207, 67, 188), 'index': 6},
      {'icon': Icons.menu_book, 'title': 'Scolarité', 'subtitle': 'Gestion des scolarités', 'color': const Color.fromARGB(255, 255, 139, 207), 'index': 7},
      {'icon': Icons.menu_book, 'title': 'Montants', 'subtitle': 'Gestion des tranches de scolarité', 'color': const Color.fromARGB(255, 64, 255, 54), 'index': 8},
      {'icon': Icons.assignment, 'title': 'Bulletin', 'subtitle': 'Gestion des bulletins scolaires', 'color': const Color.fromARGB(255, 243, 32, 109), 'index': 9},
      {'icon': Icons.notifications, 'title': 'Notifications', 'subtitle': 'Envoyer des notifications aux parents', 'color': const Color.fromARGB(255, 33, 243, 201), 'index': 10},
      {'icon': Icons.settings, 'title': 'Paramètres', 'subtitle': 'Configuration de l\'application', 'color': Colors.grey, 'index': 11},
    ];

    _loadUnreadMessagesCount();
    // Pas de websocket côté serveur : on interroge périodiquement pour que
    // la pastille se mette à jour sans que l'admin ait à recharger l'app.
    _unreadPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _loadUnreadMessagesCount();
    });
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadMessagesCount() async {
    final count = await _notifService.getUnreadMessagesCount();
    if (mounted) {
      setState(() {
        _unreadMessagesCount = count;
      });
    }
  }

  Future<void> _logout() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          'Déconnexion',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
        );
      }
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(_isMenuOpen ? Icons.menu_open : Icons.menu),
              onPressed: _toggleMenu,
              color: Colors.white,
              tooltip: _isMenuOpen ? 'Fermer le menu' : 'Ouvrir le menu',
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'School',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(
                    text: 'App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF47C3C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF47C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF47C3C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _admin?.initials ?? 'A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B4E),
              Color(0xFF1F4E79),
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Menu latéral gauche (animé et adapté au mode sombre)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isMenuOpen ? 300 : 0,
                child: ClipRect(
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(15),
                      children: [
                        // Header du menu (adapté au mode sombre)
                        Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF47C3C),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _admin?.initials ?? 'A',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _admin?.name ?? 'Administrateur',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _admin?.email ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Éléments du menu
                        ..._menuItems.map((item) => _buildMenuItem(
                              icon: item['icon'],
                              title: item['title'],
                              subtitle: item['subtitle'],
                              color: item['color'],
                              isSelected: _selectedIndex == item['index'],
                              // Pastille rouge des messages non lus : la page
                              // 'Notifications' héberge aussi les conversations.
                              badgeCount: item['title'] == 'Notifications' ? _unreadMessagesCount : 0,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = item['index'];
                                });
                                if (item['title'] == 'Notifications') {
                                  _loadUnreadMessagesCount();
                                }
                              },
                              isDarkMode: isDarkMode,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              // Zone de contenu avec IndexedStack
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                  ),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: color.withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.25) : (color.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : (isDarkMode ? color : color),
                size: 20,
              ),
            ),
            // Pastille rouge signalant un/des nouveau(x) message(s) non lu(s).
            if (badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? color 
                : (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isSelected 
                ? color.withOpacity(0.8) 
                : (isDarkMode ? Colors.grey.shade500 : Colors.grey[600]),
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: Colors.transparent,
      ),
    );
  }
}