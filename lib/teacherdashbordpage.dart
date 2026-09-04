// lib/teacherdashbordpage.dart

import 'package:flutter/material.dart';
import 'services/dashboard_service.dart';
import 'services/auth_service.dart';
import 'services/eleve_service.dart';
import 'widgets/add_notes_dialog.dart';
import 'widgets/eleve_notes_dialog.dart';
import 'widgets/eleve_notes_manager_dialog.dart';
import 'utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Données des notes
  List<Map<String, dynamic>> _elevesNotes = [];
  List<Map<String, dynamic>> _elevesNotesFiltrees = [];

  // Filtre trimestre
  String _selectedTrimestre = 'Tous';
  bool _showFilter = false;
  final List<String> _trimestres = ['Tous', 'Trimestre 1', 'Trimestre 2', 'Trimestre 3'];

  // Recherche
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Année scolaire
  int? _anneeScolaireId;

  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _checkToken();
    print('=== INIT DASHBOARD ===');
    print('ID Professeur reçu: ${widget.user?['id']}');
    print('Nom Professeur: ${widget.user?['prenom']} ${widget.user?['nom']}');
    print('Matière ID: ${widget.user?['matiere_id']}');

    _dashboardService.setProfesseurId(widget.user?['id']);
    _dashboardService.setMatiereId(widget.user?['matiere_id']);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(Constants.professeurToken);
    print('🔑 Token professeur dans dashboard: ${token != null ? token.substring(0, 20) : 'null'}...');
  }

  Future<void> _loadData() async {
    print('=== CHARGEMENT DES DONNÉES ===');
    setState(() => _isLoading = true);
    await _loadClasses();
    await _loadEmploiDuTemps();
    setState(() => _isLoading = false);
  }

  // ==================== CHARGEMENT DES CLASSES ====================
  Future<void> _loadClasses() async {
    print('=== CHARGEMENT DES CLASSES ===');

    // Charger l'année scolaire en cours
    final anneeResponse = await EleveService.getAnneeScolaireEnCoursStatic();
    if (anneeResponse['success'] == true && anneeResponse['data'] != null) {
      _anneeScolaireId = anneeResponse['data']['id'];
      print('📅 Année scolaire: ${anneeResponse['data']['libelle']} (ID: $_anneeScolaireId)');
    } else {
      print('⚠️ Aucune année scolaire en cours trouvée, utilisation de l\'année par défaut');
      _anneeScolaireId = 1;
    }

    // ✅ Appel avec année
    final response = await _dashboardService.getClasses(anneeScolaireId: _anneeScolaireId);

    if (response['success'] == true && mounted) {
      final List<Map<String, dynamic>> classesData = response['data'] != null
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];

      setState(() {
        _classes = classesData;
        if (_classes.isNotEmpty) {
          _selectedClasse = _classes[0]; // Sélectionner la première classe par défaut
        }
      });

      if (_classes.isNotEmpty) {
        await _loadElevesWithNotes(_classes[0]['id']);
      }
    } else {
      print('Erreur lors du chargement des classes: ${response['message']}');
    }
  }

  // ==================== CHARGEMENT DES ÉLÈVES AVEC NOTES ====================
  Future<void> _loadElevesWithNotes(int classeId) async {
    print('=== CHARGEMENT DES ÉLÈVES AVEC NOTES ===');
    print('Classe ID: $classeId, Année ID: $_anneeScolaireId');

    setState(() => _isLoadingEleves = true);

    try {
      // 1. Récupérer les élèves avec leurs inscriptions pour la classe et l'année
      final elevesResponse = await _dashboardService.getElevesByClasse(
        classeId,
        anneeScolaireId: _anneeScolaireId ?? 1,
      );

      if (elevesResponse['success'] != true) {
        print('Erreur chargement élèves: ${elevesResponse['message']}');
        setState(() {
          _isLoadingEleves = false;
          _eleves = [];
          _elevesNotes = [];
        });
        return;
      }

      final List<dynamic> elevesData = elevesResponse['data']['eleves'] ?? [];
      print('${elevesData.length} élèves trouvés pour cette classe');

      if (elevesData.isEmpty) {
        setState(() {
          _eleves = [];
          _elevesNotes = [];
          _isLoadingEleves = false;
        });
        return;
      }

      // 2. Construire les données des élèves avec leurs notes
      List<Map<String, dynamic>> elevesAvecNotes = [];

      for (var eleveJson in elevesData) {
        final eleveId = eleveJson['id'];
        final inscriptionId = eleveJson['inscription_id'];
        final fullName = eleveJson['full_name'] ?? '';

        Map<String, dynamic> eleveNotes = {
          'id': eleveId,
          'full_name': fullName,
          'prenom': eleveJson['prenom'] ?? '',
          'nom': eleveJson['nom'] ?? '',
          'inscription_id': inscriptionId,
          'interrogations': [],
          'devoirs': [],
          'moyenne': 0.0,
        };

        // 3. Si une inscription existe, récupérer les notes
        if (inscriptionId != null) {
          // ✅ Utiliser l'endpoint professeur dédié (public, filtre déjà par
          // professeur_id + matiere_id côté serveur) au lieu de
          // NoteAdminService, qui exige un token "admin" absent en session
          // professeur (401 -> aucune note jamais affichée).
          final notesResponse = await _dashboardService.getEleveNotes(inscriptionId);
          if (notesResponse['success'] == true) {
            final notes = notesResponse['data'] as List? ?? [];

            for (var note in notes) {
              double noteValue = 0;
              if (note['note'] is String) {
                noteValue = double.tryParse(note['note']) ?? 0;
              } else if (note['note'] is num) {
                noteValue = (note['note'] as num).toDouble();
              }

              // Le backend filtre déjà sur la matière du professeur, pas
              // besoin (et pas possible : le champ n'est pas renvoyé) de
              // refiltrer côté client sur matiere_id ici.
              final noteData = {
                'id': note['id'],
                'note': noteValue,
                'date': note['date'] ?? note['created_at'] ?? '',
                'trimestre': note['trimestre'] ?? '1',
              };

              if (note['type_note'] == 'interrogation') {
                eleveNotes['interrogations'].add(noteData);
              } else if (note['type_note'] == 'devoir') {
                eleveNotes['devoirs'].add(noteData);
              }
            }

            // Trier les notes par date
            (eleveNotes['interrogations'] as List).sort((a, b) {
              final dateA = a['date']?.toString() ?? '';
              final dateB = b['date']?.toString() ?? '';
              return dateA.compareTo(dateB);
            });

            (eleveNotes['devoirs'] as List).sort((a, b) {
              final dateA = a['date']?.toString() ?? '';
              final dateB = b['date']?.toString() ?? '';
              return dateA.compareTo(dateB);
            });

            // Calcul de la moyenne
            double moyenneInterrogations = 0;
            int nbInterrogations = eleveNotes['interrogations'].length;

            if (nbInterrogations > 0) {
              double sumInterro = 0;
              for (var note in eleveNotes['interrogations']) {
                sumInterro += note['note'];
              }
              moyenneInterrogations = sumInterro / nbInterrogations;
            }

            List<double> notesDevoirs = [];
            for (var note in eleveNotes['devoirs']) {
              notesDevoirs.add(note['note']);
            }

            List<double> notesPourMoyenne = [];
            if (nbInterrogations > 0) {
              notesPourMoyenne.add(moyenneInterrogations);
            }
            notesPourMoyenne.addAll(notesDevoirs);

            double moyenneFinale = 0;
            if (notesPourMoyenne.isNotEmpty) {
              double sum = 0;
              for (var note in notesPourMoyenne) {
                sum += note;
              }
              moyenneFinale = sum / notesPourMoyenne.length;
            }

            eleveNotes['moyenne'] = moyenneFinale;
          }
        }

        elevesAvecNotes.add(eleveNotes);
      }

      setState(() {
        _eleves = elevesAvecNotes.map((e) => {
          'id': e['id'],
          'full_name': e['full_name'],
          'prenom': e['prenom'],
          'nom': e['nom'],
          // ✅ Indispensable pour l'enregistrement des notes (AddNotesDialog
          // affiche "Inscription manquante" sans ce champ).
          'inscription_id': e['inscription_id'],
        }).toList();
        _elevesNotes = elevesAvecNotes;
        _applyFilter();
        _isLoadingEleves = false;
      });

      print('${_elevesNotes.length} élèves chargés avec leurs notes');
    } catch (e) {
      print('Erreur dans _loadElevesWithNotes: $e');
      setState(() {
        _isLoadingEleves = false;
        _elevesNotes = [];
        _elevesNotesFiltrees = [];
      });
    }
  }

  // ==================== FILTRES ====================
  void _applyFilter() {
    List<Map<String, dynamic>> filteredList = [];

    if (_selectedTrimestre == 'Tous') {
      filteredList = List.from(_elevesNotes);
    } else {
      final trimestreNum = _selectedTrimestre.split(' ').last;

      for (var eleve in _elevesNotes) {
        Map<String, dynamic> eleveFiltre = Map.from(eleve);

        List<Map<String, dynamic>> interrogationsFiltrees = [];
        for (var note in eleve['interrogations']) {
          if (note['trimestre'].toString() == trimestreNum) {
            interrogationsFiltrees.add(note);
          }
        }

        List<Map<String, dynamic>> devoirsFiltres = [];
        for (var note in eleve['devoirs']) {
          if (note['trimestre'].toString() == trimestreNum) {
            devoirsFiltres.add(note);
          }
        }

        eleveFiltre['interrogations'] = interrogationsFiltrees;
        eleveFiltre['devoirs'] = devoirsFiltres;

        // Recalcul de la moyenne
        double moyenneInterrogations = 0;
        int nbInterrogations = interrogationsFiltrees.length;

        if (nbInterrogations > 0) {
          double sumInterro = 0;
          for (var note in interrogationsFiltrees) {
            sumInterro += note['note'];
          }
          moyenneInterrogations = sumInterro / nbInterrogations;
        }

        List<double> notesDevoirs = [];
        for (var note in devoirsFiltres) {
          notesDevoirs.add(note['note']);
        }

        List<double> notesPourMoyenne = [];
        if (nbInterrogations > 0) {
          notesPourMoyenne.add(moyenneInterrogations);
        }
        notesPourMoyenne.addAll(notesDevoirs);

        double moyenneFinale = 0;
        if (notesPourMoyenne.isNotEmpty) {
          double sum = 0;
          for (var note in notesPourMoyenne) {
            sum += note;
          }
          moyenneFinale = sum / notesPourMoyenne.length;
        }

        eleveFiltre['moyenne'] = moyenneFinale;
        filteredList.add(eleveFiltre);
      }
    }

    setState(() {
      _elevesNotesFiltrees = filteredList;
    });
  }

  // Méthode pour obtenir la liste filtrée ET recherchée
  List<Map<String, dynamic>> _getFilteredAndSearchedList() {
    List<Map<String, dynamic>> filteredList = _elevesNotesFiltrees.isNotEmpty
        ? _elevesNotesFiltrees
        : _elevesNotes;

    if (_searchQuery.isEmpty) {
      return filteredList;
    }

    return filteredList.where((eleve) {
      final fullName = eleve['full_name'].toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  // ==================== EMPLOI DU TEMPS ====================
  Future<void> _loadEmploiDuTemps() async {
    print('=== CHARGEMENT EMPLOI DU TEMPS ===');
    final response = await _dashboardService.getEmploiDuTemps(
      professeurId: widget.user?['id'],
      anneeScolaireId: _anneeScolaireId,
    );
    if (response['success'] == true && mounted) {
      setState(() => _emploiDuTemps = response['data']);
    }
  }

  // ==================== CHANGEMENT DE CLASSE ====================
  void _changeClass(int index) async {
    if (index < _classes.length) {
      setState(() {
        _selectedClasseIndex = index;
        _selectedClasse = _classes[index];
        _searchController.clear();
        _searchQuery = '';
      });
      await _loadElevesWithNotes(_classes[index]['id']);
    }
  }

  // ==================== DATE PARSER ====================
  DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(2000, 1, 1);
    try {
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime(2000, 1, 1);
    }
  }

  // ==================== DIALOGUES ====================
  void _showManageStudentNotesDialog(Map<String, dynamic> eleve) {
    List<Map<String, dynamic>> interrogations = List.from(eleve['interrogations']);
    List<Map<String, dynamic>> devoirs = List.from(eleve['devoirs']);

    interrogations.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      final dateTimeA = _parseDate(dateA);
      final dateTimeB = _parseDate(dateB);
      return dateTimeA.compareTo(dateTimeB);
    });

    devoirs.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      final dateTimeA = _parseDate(dateA);
      final dateTimeB = _parseDate(dateB);
      return dateTimeA.compareTo(dateTimeB);
    });

    Map<int, TextEditingController> interroControllers = {};
    for (int i = 0; i < interrogations.length; i++) {
      interroControllers[i] = TextEditingController(text: interrogations[i]['note'].toString());
    }

    Map<int, TextEditingController> devoirControllers = {};
    for (int i = 0; i < devoirs.length; i++) {
      devoirControllers[i] = TextEditingController(text: devoirs[i]['note'].toString());
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF47C3C),
                  child: Text(
                    eleve['full_name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eleve['full_name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Moyenne: ${eleve['moyenne'].toStringAsFixed(2)}/20',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              // ✅ minWidth: 480 forçait un overflow (RenderFlex) sur les écrans
              // de téléphone (~360-414dp) — la largeur s'adapte maintenant à
              // l'écran, avec un maximum raisonnable sur tablette/desktop.
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (interrogations.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.quiz, color: Color(0xFFF47C3C), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Interrogations',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF47C3C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${interrogations.length} note${interrogations.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...interrogations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final note = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF47C3C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Note ${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFF47C3C)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: interroControllers[index],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Note /20',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 90,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    note['date'].isNotEmpty
                                        ? note['date'].toString().substring(0, 10)
                                        : 'Sans date',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Supprimer la note'),
                                        content: Text('Voulez-vous supprimer cette note de ${eleve['full_name']} ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final response = await _dashboardService.deleteNote(note['id']);
                                              if (response['success'] == true) {
                                                setStateDialog(() {
                                                  interrogations.removeAt(index);
                                                  interroControllers.remove(index);
                                                  final newControllers = <int, TextEditingController>{};
                                                  for (var i = 0; i < interrogations.length; i++) {
                                                    newControllers[i] = interroControllers[i] ??
                                                        TextEditingController(text: interrogations[i]['note'].toString());
                                                  }
                                                  interroControllers.clear();
                                                  interroControllers.addAll(newControllers);
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Note supprimée'), backgroundColor: Colors.green),
                                                );
                                                Navigator.pop(context);
                                                await _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(response['message'] ?? 'Erreur'), backgroundColor: Colors.red),
                                                );
                                              }
                                            },
                                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    if (devoirs.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.assignment, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Devoirs',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${devoirs.length} note${devoirs.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...devoirs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final note = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Note ${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: devoirControllers[index],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Note /20',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 90,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    note['date'].isNotEmpty
                                        ? note['date'].toString().substring(0, 10)
                                        : 'Sans date',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Supprimer la note'),
                                        content: Text('Voulez-vous supprimer cette note de ${eleve['full_name']} ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final response = await _dashboardService.deleteNote(note['id']);
                                              if (response['success'] == true) {
                                                setStateDialog(() {
                                                  devoirs.removeAt(index);
                                                  devoirControllers.remove(index);
                                                  final newControllers = <int, TextEditingController>{};
                                                  for (var i = 0; i < devoirs.length; i++) {
                                                    newControllers[i] = devoirControllers[i] ??
                                                        TextEditingController(text: devoirs[i]['note'].toString());
                                                  }
                                                  devoirControllers.clear();
                                                  devoirControllers.addAll(newControllers);
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Note supprimée'), backgroundColor: Colors.green),
                                                );
                                                Navigator.pop(context);
                                                await _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(response['message'] ?? 'Erreur'), backgroundColor: Colors.red),
                                                );
                                              }
                                            },
                                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    if (interrogations.isEmpty && devoirs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Aucune note enregistrée pour cet élève'),
                        ),
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
                  bool hasError = false;

                  for (var i = 0; i < interrogations.length; i++) {
                    final controller = interroControllers[i];
                    if (controller != null) {
                      // ✅ Accepter la virgule comme séparateur décimal (ex: "14,5")
                      final nouvelleNote = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (nouvelleNote != null && nouvelleNote != interrogations[i]['note']) {
                        final response = await _dashboardService.updateNote(
                          noteId: interrogations[i]['id'],
                          valeur: nouvelleNote,
                        );
                        if (response['success'] != true) hasError = true;
                      }
                    }
                  }

                  for (var i = 0; i < devoirs.length; i++) {
                    final controller = devoirControllers[i];
                    if (controller != null) {
                      // ✅ Accepter la virgule comme séparateur décimal (ex: "14,5")
                      final nouvelleNote = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (nouvelleNote != null && nouvelleNote != devoirs[i]['note']) {
                        final response = await _dashboardService.updateNote(
                          noteId: devoirs[i]['id'],
                          valeur: nouvelleNote,
                        );
                        if (response['success'] != true) hasError = true;
                      }
                    }
                  }

                  if (!hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toutes les notes ont été enregistrées'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Certaines notes n\'ont pas pu être enregistrées'), backgroundColor: Colors.orange),
                    );
                  }

                  Navigator.pop(context);
                  await _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C3C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ENREGISTRER'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddNotesDialog({Map<String, dynamic>? eleveUnique}) {
    final List<Map<String, dynamic>> elevesList = eleveUnique != null ? [eleveUnique] : _eleves;

    if (elevesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun élève dans cette classe'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedClasse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune classe sélectionnée'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddNotesDialog(
        classeId: _selectedClasse!['id'],
        className: _selectedClasse!['name'],
        anneeScolaireId: _anneeScolaireId ?? 1,
        eleves: elevesList,
        onSave: (data) async {
          final response = await _dashboardService.saveNotes(data);
          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message']), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
            await _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
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
          _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
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
          _loadElevesWithNotes(_classes[_selectedClasseIndex]['id']);
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
      case 0:
        return _buildClassesTab();
      case 1:
        return _buildNotesTab();
      case 2:
        return _buildEmploiDuTempsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildClassesTab();
    }
  }

  // ==================== BUILD ====================
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
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
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
      // Le bouton d'ajout de note ne doit apparaître que sur la page
      // "Notes" (onglet 1), pas sur Classes/Emploi/Profil.
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              key: const Key('fab_teacher_dashboard'),
              onPressed: () => _showAddNotesDialog(),
              backgroundColor: const Color(0xFFF47C3C),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              tooltip: 'Ajouter une note',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    final displayList = _getFilteredAndSearchedList();

    // ✅ Le filtre par trimestre (_applyFilter) ne retire jamais un élève de
    // la liste : il vide juste ses listes interrogations/devoirs quand il
    // n'a aucune note pour le trimestre choisi. Résultat : `displayList`
    // gardait toujours le même nombre d'élèves, donc le message "Aucune
    // note pour ce trimestre" ci-dessous n'apparaissait jamais — seul un
    // tableau avec des cellules vides s'affichait, ce qui donnait
    // l'impression que "les notes ne se chargent pas". On détecte donc ici
    // explicitement le cas où AUCUN élève affiché n'a de note pour le
    // trimestre sélectionné, pour basculer sur le même message.
    final bool aucuneNotePourTrimestre = _selectedTrimestre != 'Tous' &&
        displayList.isNotEmpty &&
        displayList.every((eleve) =>
            (eleve['interrogations'] as List? ?? []).isEmpty &&
            (eleve['devoirs'] as List? ?? []).isEmpty);

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 20),
        // Rangée: Classes + Filtre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedClasseIndex == index;
                      final className = _classes[index]['name'] ?? 'Classe ${index + 1}';
                      return GestureDetector(
                        onTap: () => _changeClass(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF47C3C) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            className,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Bouton Filtrer
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilter = !_showFilter;
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _showFilter ? const Color(0xFFF47C3C).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: _showFilter ? const Color(0xFFF47C3C) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filtrer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _showFilter ? const Color(0xFFF47C3C) : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showFilter ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 18,
                        color: _showFilter ? const Color(0xFFF47C3C) : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un élève...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        // Nombre d'élèves
        if (_selectedClasse != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  '${displayList.length} élèves',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        // DATATABLE
        Expanded(
          child: _isLoadingEleves
              ? const Center(child: CircularProgressIndicator())
              : (displayList.isEmpty || aucuneNotePourTrimestre)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : (aucuneNotePourTrimestre
                                      ? Icons.assignment_late_outlined
                                      : Icons.people_outline),
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Aucun élève trouvé pour "$_searchQuery"'
                                : ((_selectedTrimestre != 'Tous' &&
                                        (displayList.isEmpty || aucuneNotePourTrimestre))
                                    ? 'Aucune note enregistrée pour $_selectedTrimestre'
                                    : 'Aucun élève'),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowColor: MaterialStateProperty.resolveWith(
                            (states) => const Color(0xFF0D2B4E),
                          ),
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          columns: const [
                            DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nom & Prénom', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Interrogations', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Devoirs', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Moyenne', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: displayList.asMap().entries.map((entry) {
                            final index = entry.key;
                            final eleve = entry.value;

                            String moyenne = eleve['moyenne'] > 0 ? eleve['moyenne'].toStringAsFixed(2) : '-';
                            Color moyenneColor = Colors.grey;
                            if (eleve['moyenne'] >= 15) moyenneColor = Colors.green;
                            else if (eleve['moyenne'] >= 10) moyenneColor = Colors.orange;
                            else if (eleve['moyenne'] > 0) moyenneColor = Colors.red;

                            return DataRow(
                              color: MaterialStateProperty.resolveWith(
                                (states) => index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                              ),
                              cells: [
                                DataCell(Text('${index + 1}')),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      eleve['full_name'],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: eleve['interrogations'].isEmpty
                                          ? [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text('-', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              )
                                            ]
                                          : eleve['interrogations'].map<Widget>((note) {
                                              return Container(
                                                margin: const EdgeInsets.only(right: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF47C3C).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFFF47C3C).withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  note['note'].toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFF47C3C),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: eleve['devoirs'].isEmpty
                                          ? [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text('-', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                              )
                                            ]
                                          : eleve['devoirs'].map<Widget>((note) {
                                              return Container(
                                                margin: const EdgeInsets.only(right: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  note['note'].toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: moyenne != '-' ? moyenneColor.withOpacity(0.1) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      moyenne,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: moyenne != '-' ? moyenneColor : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Color(0xFFF47C3C)),
                                        onPressed: () => _showManageStudentNotesDialog(eleve),
                                        tooltip: 'Gérer les notes',
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(0xFFF47C3C).withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        ),
          ],
        ),
        // Popup du filtre (survole la recherche et le tableau)
        if (_showFilter)
          Positioned(
            top: 68,
            right: 16,
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _trimestres.map((trimestre) {
                  final isSelected = _selectedTrimestre == trimestre;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTrimestre = trimestre;
                        _applyFilter();
                        _showFilter = false;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF47C3C).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFFF47C3C) : Colors.grey.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              trimestre,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? const Color(0xFFF47C3C) : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF47C3C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Actif',
                                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== ONGLET NOTES ====================
  Widget _buildNotesTab() {
    final className = _selectedClasse?['name'] ?? 'une classe';

    // Le bouton d'ajout de note vit uniquement sur l'onglet Notes (ni sur
    // Classes, ni ailleurs).
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
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: const Color(0xFFF47C3C)),
                  const SizedBox(width: 8),
                  Text(jour, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ...cours.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF47C3C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(c['heure_debut'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('-', style: TextStyle(fontSize: 10)),
                          Text(c['heure_fin'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['classe'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(c['matiere'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          if (c['salle'].isNotEmpty)
                            Text('Salle: ${c['salle']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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