// 2. PAGE D'ACCUEIL AVEC SÉLECTION DE PROFIL
import 'package:flutter/material.dart';
import 'adminloginpage.dart';
import 'parentloginpage.dart';
import 'teacherloginpage.dart';

class AccueilPage extends StatelessWidget {
  final List<Map<String, dynamic>> profiles = [
    {
      'title': 'PARENTS', 
      'icon': Icons.family_restroom, 
      'color': Color(0xFFF47C3C), // Bleu foncé
      'description': 'Suivez la scolarité de vos enfants'
    },
    {
      'title': 'PROFESSEURS', 
      'icon': Icons.person, 
      'color': Color(0xFFF47C3C), // Bleu moyen
      'description': 'Gérez vos classes et notes'
    },
    {
      'title': 'ADMINISTRATION', 
      'icon': Icons.business, 
      'color': Color(0xFFF47C3C), // Orange
      'description': 'Administrez l\'établissement'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B4E), // Bleu foncé
              Color(0xFF1F4E79), // Bleu moyen
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec logo et bienvenue
              Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  children: [
                    // Logo avec badge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.school,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 50,
                          right: 45,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF47C3C), // Orange
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    // Titre
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'School',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          TextSpan(
                            text: 'App',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF47C3C), // Orange
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Bénin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Bienvenue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Connectez-vous pour accéder à votre espace',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Carte blanche avec les options
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Petit indicateur (drag handle)
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 16, bottom: 10),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      
                      // Titre de la section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 25,
                              decoration: BoxDecoration(
                                color: Color(0xFFF47C3C), // Orange
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Choisissez votre profil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 10),
                      
                      // Liste des profils
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: profiles.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                if (profiles[index]['title'] == 'PARENTS') {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => ParentLoginPage())
                                  );
                                } else if (profiles[index]['title'] == 'PROFESSEURS') {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => TeacherLoginPage())
                                  );
                                } else {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => AdminLoginPage())
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                margin: EdgeInsets.only(bottom: 15),
                                child: Stack(
                                  children: [
                                    // Carte principale
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: profiles[index]['color'].withOpacity(0.1),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: profiles[index]['color'].withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Icône avec fond coloré
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: profiles[index]['color'].withOpacity(0.1),
                                            ),
                                            child: Icon(
                                              profiles[index]['icon'],
                                              color: profiles[index]['color'],
                                              size: 30,
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          // Textes
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  profiles[index]['title'],
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: profiles[index]['color'],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  profiles[index]['description'],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF7A7A7A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Flèche
                                          Container(
                                            width: 35,
                                            height: 35,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: profiles[index]['color'].withOpacity(0.1),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward,
                                              color: profiles[index]['color'],
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Petit badge si c'est l'admin (optionnel)
                                    if (index == 2)
                                      Positioned(
                                        top: 0,
                                        right: 10,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF47C3C),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'ADMIN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Pied de page avec version
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
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
}