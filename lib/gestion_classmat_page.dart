// lib/screens/gestion_classmat_page.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/annee_scolaire_model.dart';
import '../widgets/add_classe_panel.dart';
import '../widgets/edit_classe_panel.dart';
import '../widgets/add_matiere_panel.dart';
import '../widgets/edit_matiere_panel.dart';

class GestionClassmatPage extends StatefulWidget {
  @override
  _GestionClassmatPageState createState() => _GestionClassmatPageState();
}

class _GestionClassmatPageState extends State<GestionClassmatPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  // Services
  final ClassmatService _classmatService = ClassmatService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  // Données des années
  List<AnneeScolaire> _anneesScolaires = [];
  int? _selectedAnneeId;

  // Données des classes
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];

  // Données des matières
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _filteredMatieres = [];

  List<Map<String, dynamic>> _allProfesseurs = [];
  List<Map<String, dynamic>> _filteredProfesseurs = [];


  bool _isLoading = true;
  String _searchQuery = '';

  // Liste des matières et classes pour les dialogues
  List<Map<String, dynamic>> _allMatieres = [];
  List<Map<String, dynamic>> _allClasses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger les années
      final annees = await _anneeService.getAnneesScolaires();
      setState(() {
        _anneesScolaires = annees;
      });

      // 2. Déterminer l'année par défaut
      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }

      // 3. Charger les données avec filtre année
      await _chargerDonnees();
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerDonnees() async {
  setState(() => _isLoading = true);

  try {
    final professeurs = await _classmatService.getProfesseursList();
setState(() { _allProfesseurs = professeurs;});
    final classes = await _classmatService.getClassesList(anneeScolaireId: _selectedAnneeId);
    final matieres = await _classmatService.getMatieresList(anneeScolaireId: _selectedAnneeId);

    setState(() {
      _classes = classes;
      _filteredClasses = classes;
      _allClasses = classes.map((c) => {
        'id': c['id'],
        'nom': c['nom'],
      }).toList();
      
      _matieres = matieres;
      _filteredMatieres = matieres;
      _allMatieres = matieres.map((m) => {
        'id': m['id'],
        'nom': m['nom'],
      }).toList();

      _allProfesseurs = professeurs;
      
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    _showSnackBar('Erreur: $e', Colors.red);
  }
}

  void _filterData(String query) {
    setState(() {
      _searchQuery = query;
      _filteredClasses = _classes.where((item) {
        return item['nom'].toLowerCase().contains(query.toLowerCase());
      }).toList();

      _filteredMatieres = _matieres.where((item) {
        return item['nom'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _ajouterClasse() async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddClassePanel(
        matieres: _allMatieres,
        professeurs: _allProfesseurs,       // ✅
        anneesScolaires: _anneesScolaires,  // ✅
        initialAnneeId: _selectedAnneeId ?? (_anneesScolaires.isNotEmpty ? _anneesScolaires.first.id : 0),
        onAdd: () {
          _chargerDonnees();
        },
      );
      },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

  Future<void> _modifierClasse(Map<String, dynamic> classe) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EditClassePanel(
        classe: classe,
        matieres: _allMatieres,
        professeurs: _allProfesseurs,        // ✅
        anneesScolaires: _anneesScolaires,   // ✅
        initialAnneeId: _selectedAnneeId ?? (_anneesScolaires.isNotEmpty ? _anneesScolaires.first.id : 0), // ✅
        onUpdate: () {
          _chargerDonnees();
          },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

  Future<void> _supprimerClasse(Map<String, dynamic> classe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer la classe ${classe['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _classmatService.deleteClasse(classe['id']);
      if (response['success'] == true) {
        _showSnackBar('Classe supprimée avec succès', Colors.green);
        await _chargerDonnees();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _ajouterMatiere() async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddMatierePanel(
          classes: _allClasses,
          onAdd: () {
            _chargerDonnees();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  Future<void> _modifierMatiere(Map<String, dynamic> matiere) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EditMatierePanel(
          matiere: matiere,
          classes: _allClasses,
          onUpdate: () {
            _chargerDonnees();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  Future<void> _supprimerMatiere(Map<String, dynamic> matiere) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer la matière ${matiere['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _classmatService.deleteMatiere(matiere['id']);
      if (response['success'] == true) {
        _showSnackBar('Matière supprimée avec succès', Colors.green);
        await _chargerDonnees();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Classes & Matières'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Classes', icon: Icon(Icons.class_)),
            Tab(text: 'Matières', icon: Icon(Icons.book)),
          ],
          labelColor: const Color(0xFFF47C3C),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFF47C3C),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (_tabController.index == 0) {
                _ajouterClasse();
              } else {
                _ajouterMatiere();
              }
            },
            tooltip: 'Ajouter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SÉLECTEUR D'ANNÉE SCOLAIRE
                if (_anneesScolaires.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    child: Row(
                      children: [
                        const Text(
                          'Année scolaire : ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int>(
                            value: _selectedAnneeId,
                            isExpanded: true,
                            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            underline: Container(
                              height: 1,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Toutes les années'),
                              ),
                              ..._anneesScolaires.map((annee) {
                                return DropdownMenuItem(
                                  value: annee.id,
                                  child: Text(annee.libelle ?? 'Année ${annee.id}'),
                                );
                              }),
                            ],
                            onChanged: (value) async {
                              setState(() {
                                _selectedAnneeId = value;
                              });
                              await _chargerDonnees();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                // BARRE DE RECHERCHE
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _filterData,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFFF47C3C),
                          width: 1,
                        ),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    ),
                  ),
                ),
                // TAB VIEW
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Classes
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Center(
                          child: _buildClassesTable(isDarkMode),
                        ),
                      ),
                      // Onglet Matières
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Center(
                          child: _buildMatieresTable(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildClassesTable(bool isDarkMode) {
    if (_filteredClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedAnneeId == null
                  ? 'Aucune classe trouvée'
                  : 'Aucune classe pour cette année',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(
        isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
      ),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      dataRowColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => isDarkMode ? const Color(0xFF2A2A2A) : Colors.transparent,
      ),
      dividerThickness: 0,
      columns: const [
        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Effectif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      ],
      rows: _filteredClasses.asMap().entries.map((entry) {
        final index = entry.key;
        final classe = entry.value;

        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (states) {
              if (index % 2 == 0) {
                return isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
              }
              return null;
            },
          ),
          cells: [
            DataCell(
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                classe['nom'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                '${classe['effectif'] ?? 0}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _modifierClasse(classe),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _supprimerClasse(classe),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMatieresTable(bool isDarkMode) {
    if (_filteredMatieres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune matière trouvée',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(
        isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
      ),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      dataRowColor: MaterialStateProperty.resolveWith<Color?>(
        (states) => isDarkMode ? const Color(0xFF2A2A2A) : Colors.transparent,
      ),
      dividerThickness: 0,
      columns: const [
        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Coef.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      ],
      rows: _filteredMatieres.asMap().entries.map((entry) {
        final index = entry.key;
        final matiere = entry.value;

        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (states) {
              if (index % 2 == 0) {
                return isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
              }
              return null;
            },
          ),
          cells: [
            DataCell(
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Text(
                matiere['nom'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${matiere['coefficient'] ?? 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _modifierMatiere(matiere),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _supprimerMatiere(matiere),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}