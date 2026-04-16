// lib/screens/admindashboardpage.dart

import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../model/admin_model.dart';
import 'adminloginpage.dart';
import 'gestparent.dart'; 
import 'gestpaiement.dart';
import 'gestemploi.dart';
import 'gestnotification.dart';
import 'gestscolarite.dart';
import 'gestbulletin.dart';
import 'gestion_eleves_page.dart';
import 'gestion_notes_page.dart';
import 'parametres_pages.dart';
import 'gestion_professeurs_page.dart';


class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminAuthService _authService = AdminAuthService();
  AdminModel? _admin;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _admin = _authService.currentAdmin;
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'School',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
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
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFF47C3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
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
        backgroundColor: Color(0xFF0D2B4E),
        elevation: 0,
        actions: [
          // Avatar admin
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFF47C3C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _admin?.initials ?? 'A',
                  style: TextStyle(
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
        decoration: BoxDecoration(
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
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFFF47C3C),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _admin?.initials ?? 'A',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _admin?.name ?? 'Administrateur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _admin?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      _buildMenuItem(
                        icon: Icons.people,
                        title: 'Gestion des parents',
                        subtitle: 'Ajouter, modifier, supprimer des parents',
                        color: Color(0xFF0D2B4E),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => GestParentPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        }, 
                      ),
                      _buildMenuItem(
                        icon: Icons.school,
                        title: 'Gestion des élèves',
                        subtitle: 'Gérer les inscriptions et les classes',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestionElevesPage ()),
                            );
                         },
                      ),
                      _buildMenuItem(
                        icon: Icons.payment,
                        title: 'Gestion des paiements',
                        subtitle: 'Suivi des transactions',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GestPaiementPage(),
                            ),
                          );
                        },
                      ),
                       _buildMenuItem(
                        icon: Icons.school,
                        title: 'Gestion des professeur',
                        subtitle: 'Gérer les ajouts, modifications et suppressions',
                        color: const Color.fromARGB(255, 195, 195, 30),
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestionProfesseursPage()),
                            );
                         },
                      ),
                      _buildMenuItem(
                        icon: Icons.calendar_today,
                        title: 'Emploi du temps',
                        subtitle: 'Gérer les emplois du temps',
                        color: Colors.purple,
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestEmploiPage()),
                            );
                         },
                      ),

                      _buildMenuItem(
                        icon: Icons.calendar_today,
                        title: 'Gestions des notes',
                        subtitle: 'Consulter toutes les notes ',
                        color: const Color.fromARGB(255, 207, 67, 188),
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestionNotesPage()),
                            );
                         },
                      ),

                      _buildMenuItem(
                        icon: Icons.menu_book,
                        title: 'Scolarité',
                        subtitle: 'Gestion des scolarités',
                        color: const Color.fromARGB(255, 176, 39, 119),
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestScolaritePage()),
                            );
                         },
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment,
                        title: 'Bulletin',
                        subtitle: 'Gestion des bulletins scolaires',
                        color: const Color.fromARGB(255, 10, 2, 49),
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GestBulletinPage()),
                            );
                         },
                      ),
                      
                      _buildMenuItem(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Envoyer des notifications aux parents',
                        color: Colors.blue,
                         onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GestNotificationPage(),
                              ),
                          );
                         },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        title: 'Paramètres',
                        subtitle: 'Configuration de l\'application',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ParametresPage()),
                            );
                         },
                      ),
                    ],
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
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}