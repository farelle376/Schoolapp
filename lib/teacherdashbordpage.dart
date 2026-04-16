// lib/teacherdashbordpage.dart

import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'widgets/add_notes_dialog.dart';
import 'widgets/eleve_notes_dialog.dart';
import 'widgets/eleve_notes_manager_dialog.dart';

class TeacherDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const TeacherDashboardPage({Key? key, this.user}) : super(key: key);

  @override
  _TeacherDashboardPageState createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _selectedIndex = 0;
  int _selectedClasseIndex = 0;
  bool _isLoading = true;
  bool _isLoadingEleves = false;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _eleves = [];
  Map<String, dynamic>? _selectedClasse;
  Map<String, dynamic>? _emploiDuTemps;
  
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    print('=== INIT DASHBOARD ===');
    print('ID Professeur reçu: ${widget.user?['id']}');
    print('Nom Professeur: ${widget.user?['prenom']} ${widget.user?['nom']}');
    
    _dashboardService.setProfesseurId(widget.user?['id']);
    _loadData();
  }

  Future<void> _loadData() async {
    print('=== CHARGEMENT DES DONNÉES ===');
    setState(() => _isLoading = true);
    await _loadClasses();
    await _loadEmploiDuTemps();
    setState(() => _isLoading = false);
  }

  Future<void> _loadClasses() async {
    print('=== CHARGEMENT DES CLASSES ===');
    final response = await _dashboardService.getClasses();
    
    print('Réponse getClasses: $response');
    
    if (response['success'] == true && mounted) {
      final List<Map<String, dynamic>> classesData = response['data'] != null 
          ? List<Map<String, dynamic>>.from(response['data']) 
          : [];
      
      print('Nombre de classes trouvées: ${classesData.length}');
      for (var c in classesData) {
        print('  - Classe: ${c['name']} (ID: ${c['id']})');
      }
      
      setState(() {
        _classes = classesData;
      });
      
      if (_classes.isNotEmpty) {
        print('Chargement des élèves de la première classe: ${_classes[0]['name']}');
        _loadEleves(_classes[0]['id']);
      }
    } else {
      print('Erreur lors du chargement des classes: ${response['message']}');
    }
  }

  Future<void> _loadEleves(int classeId) async {
    print('=== CHARGEMENT DES ÉLÈVES ===');
    print('Classe ID: $classeId');
    
    setState(() => _isLoadingEleves = true);
    final response = await _dashboardService.getElevesByClasse(classeId);
    
    print('Réponse getElevesByClasse: $response');
    
    if (response['success'] == true && mounted) {
      final data = response['data'];
      final classeInfo = data['classe'] ?? {};
      
      final List<Map<String, dynamic>> elevesData = data['eleves'] != null 
          ? List<Map<String, dynamic>>.from(data['eleves']) 
          : [];
      
      print('Classe: ${classeInfo['name']} - ${elevesData.length} élèves');
      
      setState(() {
        _selectedClasse = classeInfo;
        _eleves = elevesData;
        _isLoadingEleves = false;
      });
    } else {
      print('Erreur chargement élèves: ${response['message']}');
      setState(() {
        _isLoadingEleves = false;
        _eleves = [];
      });
    }
  }

  Future<void> _loadEmploiDuTemps() async {
    print('=== CHARGEMENT EMPLOI DU TEMPS ===');
    final response = await _dashboardService.getEmploiDuTemps();
    if (response['success'] == true && mounted) {
      print('Emploi du temps chargé');
      setState(() => _emploiDuTemps = response['data']);
    } else {
      print('Erreur chargement emploi du temps: ${response['message']}');
    }
  }

  void _changeClass(int index) {
    print('=== CHANGEMENT DE CLASSE ===');
    if (index < _classes.length) {
      print('Nouvel index: $index, Classe: ${_classes[index]['name']}');
      setState(() => _selectedClasseIndex = index);
      _loadEleves(_classes[index]['id']);
    }
  }

  void _showAddNotesDialog({Map<String, dynamic>? eleveUnique}) {
    final List<Map<String, dynamic>> elevesList = eleveUnique != null ? [eleveUnique] : _eleves;
    
    if (elevesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élève dans cette classe'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddNotesDialog(
        classeId: _selectedClasse!['id'],
        className: _selectedClasse!['name'],
        eleves: elevesList,
        onSave: (data) async {
          final response = await _dashboardService.saveNotes(data);
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message']), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
            // Recharger les élèves pour mettre à jour les moyennes
            _loadEleves(_classes[_selectedClasseIndex]['id']);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message']), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showEleveNotes(Map<String, dynamic> eleve) {
    showDialog(
      context: context,
      builder: (context) => EleveNotesDialog(
        eleve: eleve,
        professeurId: widget.user?['id'] ?? 0,
        onNoteUpdated: () {
          // Recharger les élèves pour mettre à jour les moyennes
          _loadEleves(_classes[_selectedClasseIndex]['id']);
        },
      ),
    );
  }

  void _showEleveNotesManager(Map<String, dynamic> eleve) {
        showDialog(
        context: context,
        builder: (context) => EleveNotesManagerDialog(
        eleve: eleve,
        professeurId: widget.user?['id'] ?? 0,
        matiereId: widget.user?['matiere_id'] ?? 0,
        onNoteUpdated: () {
        // Recharger les élèves pour mettre à jour les moyennes
        _loadEleves(_classes[_selectedClasseIndex]['id']);
      },
    ),
  );
}

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/professeur/login');
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0: return _buildClassesTab();
      case 1: return _buildNotesTab();
      case 2: return _buildEmploiDuTempsTab();
      case 3: return _buildProfileTab();
      default: return _buildClassesTab();
    }
  }

  @override
Widget build(BuildContext context) {
  final initials = widget.user?['prenom'] != null && widget.user?['nom'] != null
      ? '${widget.user!['prenom'].toString().trim()[0]}${widget.user!['nom'].toString().trim()[0]}'.toUpperCase()
      : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFF0D2B4E),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // HEADER BLEU
                Container(
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 30),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D2B4E), Color(0xFF0D2B4E)],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFF47C3C),
                        child: Text(initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.user?['prenom'] ?? ''} ${widget.user?['nom'] ?? 'Professeur'}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text('Bienvenue dans votre espace', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white), 
                        onPressed: _logout
                      ),
                    ],
                  ),
                ),

                // CONTENU BLANC
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: _getBodyContent(),
                    ),
                  ),
                ),
              ],
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF47C3C),
        unselectedItemColor: Colors.grey,
        elevation: 20,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), activeIcon: Icon(Icons.edit_note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Emploi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // ==================== ONGLET CLASSES ====================
  Widget _buildClassesTab() {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune classe assignée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Contactez l\'administration',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        // Liste horizontale des classes
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedClasseIndex == index;
              final className = _classes[index]['name'] ?? 'Classe ${index + 1}';
              return GestureDetector(
                onTap: () => _changeClass(index),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF47C3C) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      if(!isSelected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                    ]
                  ),
                  child: Text(
                    className,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        
        // Nombre d'élèves
        if (_selectedClasse != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${_selectedClasse!['students_count'] ?? 0} élèves',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        
        // Liste des élèves avec boutons VOIR et MODIFIER
        Expanded(
          child: _isLoadingEleves
              ? const Center(child: CircularProgressIndicator())
              : _eleves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Aucun élève', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _eleves.length,
                      itemBuilder: (context, index) {
                        final eleve = _eleves[index];
                        final fullName = eleve['full_name'] ?? '${eleve['prenom'] ?? ''} ${eleve['nom'] ?? ''}'.trim();
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF47C3C).withOpacity(0.1),
                              child: Text('${index + 1}', style: const TextStyle(color: Color(0xFFF47C3C))),
                            ),
                            title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Bouton VOIR
                            IconButton(
                            icon: Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => _showEleveNotes(eleve),
                            tooltip: 'Voir les notes',
                              ),
                            // Bouton MODIFIER
                            IconButton(
                            icon: Icon(Icons.edit, color: const Color(0xFFF47C3C)),
                            onPressed: () => _showEleveNotesManager(eleve),
                            tooltip: 'Gérer les notes',
                               ),
                             ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==================== ONGLET NOTES ====================
  Widget _buildNotesTab() {
    final className = _selectedClasse?['name'] ?? 'une classe';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 80, color: Color(0xFFF47C3C)),
            const SizedBox(height: 20),
            Text(
              'Saisie des notes pour : $className',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _showAddNotesDialog(),
              icon: const Icon(Icons.add),
              label: const Text('OUVRIR LE FORMULAIRE', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ONGLET EMPLOI DU TEMPS ====================
  Widget _buildEmploiDuTempsTab() {
  if (_emploiDuTemps == null) return const Center(child: CircularProgressIndicator());
  
  final jours = _emploiDuTemps!.keys.toList();
  
  if (jours.isEmpty) {
    return const Center(child: Text('Aucun cours pour ce professeur'));
  }
  
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: jours.length,
    itemBuilder: (context, index) {
      final jour = jours[index];
      final cours = _emploiDuTemps![jour] as List;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du jour
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Color(0xFFF47C3C)),
                const SizedBox(width: 8),
                Text(
                  jour,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Liste des cours du jour (sans ExpansionTile)
          ...cours.map((c) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Heure
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF47C3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          c['heure_debut'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Text('-', style: TextStyle(fontSize: 10)),
                        Text(
                          c['heure_fin'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Infos matière et classe
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['classe'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['matiere'],
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        if (c['salle'].isNotEmpty)
                          Text(
                            'Salle: ${c['salle']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
          const Divider(),
        ],
      );
    },
  );
}

  // ==================== ONGLET PROFIL ====================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF0D2B4E),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Nom', widget.user?['nom']),
                  const Divider(),
                  _buildInfoRow('Prénom', widget.user?['prenom']),
                  const Divider(),
                  _buildInfoRow('Email', widget.user?['email']),
                  const Divider(),
                  _buildInfoRow('Numéro', widget.user?['numero']),
                  const SizedBox(height: 20),
                  const Text(
                    'Pour toute modification, contactez l\'administration.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    final displayValue = value ?? 'Non renseigné';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(displayValue, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
        ],
      ),
    );
  }
}