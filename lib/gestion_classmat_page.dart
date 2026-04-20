// lib/screens/gestion_classmat_page.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';
import '../widgets/add_classe_panel.dart';
import '../widgets/edit_classe_panel.dart';
import '../widgets/add_matiere_panel.dart';
import '../widgets/edit_matiere_panel.dart';

class GestionClassmatPage extends StatefulWidget {
  @override
  _GestionClassmatPageState createState() => _GestionClassmatPageState();
}

class _GestionClassmatPageState extends State<GestionClassmatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Données des classes
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  
  // Données des matières
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _filteredMatieres = [];
  
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
    
    final results = await Future.wait([
      ClassmatService.getClasses(),
      ClassmatService.getMatieres(),
    ]);
    
    final classesResponse = results[0];
    final matieresResponse = results[1];
    
    if (classesResponse['success'] == true) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
        _filteredClasses = _classes;
        
        _allClasses = _classes.map((c) => {
          'id': c['id'],
          'nom': c['nom'],
        }).toList();
      });
    }
    
    if (matieresResponse['success'] == true) {
      setState(() {
        _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
        _filteredMatieres = _matieres;
        
        _allMatieres = _matieres.map((m) => {
          'id': m['id'],
          'nom': m['nom'],
        }).toList();
      });
    }
    
    setState(() => _isLoading = false);
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
    transitionDuration: const Duration(milliseconds: 1500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddClassePanel(
        matieres: _allMatieres,
        onAdd: () {
          _loadAllData();
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
    transitionDuration: const Duration(milliseconds: 1500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EditClassePanel(
        classe: classe,
        matieres: _allMatieres,
        onUpdate: () {
          _loadAllData();
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
      final response = await ClassmatService.deleteClasse(classe['id']);
      if (response['success'] == true) {
        _showSnackBar('Classe supprimée avec succès', Colors.green);
        _loadAllData();
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
    transitionDuration: const Duration(milliseconds: 1500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddMatierePanel(
        classes: _allClasses,
        onAdd: () {
          _loadAllData();
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
    transitionDuration: const Duration(milliseconds: 1500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EditMatierePanel(
        matiere: matiere,
        classes: _allClasses,
        onUpdate: () {
          _loadAllData();
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
      final response = await ClassmatService.deleteMatiere(matiere['id']);
      if (response['success'] == true) {
        _showSnackBar('Matière supprimée avec succès', Colors.green);
        _loadAllData();
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
            onPressed: _loadAllData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // BARRE DE RECHERCHE
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _filterData,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                // TAB VIEW AVEC SCROLL VERTICAL
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune classe trouvée'),
          ],
        ),
      );
    }

    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(
        isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
      ),
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
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text(classe['nom'])),
            DataCell(Text('${classe['effectif'] ?? 0}')),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune matière trouvée'),
          ],
        ),
      );
    }

    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(
        isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
      ),
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
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text(matiere['nom'])),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
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

// ==================== DIALOGUES AVEC CHIPS (PANEL) ====================

class _AjouterClasseDialog extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  const _AjouterClasseDialog({required this.matieres});

  @override
  _AjouterClasseDialogState createState() => _AjouterClasseDialogState();
}

class _AjouterClasseDialogState extends State<_AjouterClasseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  List<Map<String, dynamic>> _selectedMatieres = [];
  Map<int, int> _coefficients = {};

  void _toggleMatiere(Map<String, dynamic> matiere) {
    setState(() {
      final exists = _selectedMatieres.any((m) => m['id'] == matiere['id']);
      if (exists) {
        _selectedMatieres.removeWhere((m) => m['id'] == matiere['id']);
        _coefficients.remove(matiere['id']);
      } else {
        _selectedMatieres.add(matiere);
        _coefficients[matiere['id']] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter une classe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la classe',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              const Text('Matières assignées', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Chips des matières sélectionnées
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMatieres.isEmpty
                      ? [const Text('Aucune matière sélectionnée', style: TextStyle(color: Colors.grey))]
                      : _selectedMatieres.map((matiere) {
                          return Chip(
                            label: Text(matiere['nom']),
                            backgroundColor: const Color(0xFFF47C3C).withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleMatiere(matiere),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Toutes les matières', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              // Liste des matières disponibles
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.matieres.map((matiere) {
                      final isSelected = _selectedMatieres.any((m) => m['id'] == matiere['id']);
                      return FilterChip(
                        label: Text(matiere['nom']),
                        selected: isSelected,
                        onSelected: (_) => _toggleMatiere(matiere),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFF47C3C),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selectedMatieres.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Coefficients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _selectedMatieres.map((matiere) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(matiere['nom'])),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: _coefficients[matiere['id']]?.toString() ?? '1',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onChanged: (value) {
                                    _coefficients[matiere['id']] = int.tryParse(value) ?? 1;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final matieresList = _selectedMatieres.map((m) => ({
                          'id': m['id'],
                          'coefficient': _coefficients[m['id']] ?? 1,
                        })).toList();
                        
                        Navigator.pop(context, {
                          'nom': _nomController.text,
                          'matieres': matieresList,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
                    child: const Text('AJOUTER'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModifierClasseDialog extends StatefulWidget {
  final Map<String, dynamic> classe;
  final List<Map<String, dynamic>> matieres;
  const _ModifierClasseDialog({required this.classe, required this.matieres});

  @override
  _ModifierClasseDialogState createState() => _ModifierClasseDialogState();
}

class _ModifierClasseDialogState extends State<_ModifierClasseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  List<Map<String, dynamic>> _selectedMatieres = [];
  Map<int, int> _coefficients = {};

  @override
  void initState() {
    super.initState();
    _nomController.text = widget.classe['nom'] ?? '';
    final matieres = widget.classe['matieres'] as List? ?? [];
    for (var m in matieres) {
      _selectedMatieres.add({
        'id': m['id'],
        'nom': m['nom'],
      });
      _coefficients[m['id']] = m['coefficient'] ?? 1;
    }
  }

  void _toggleMatiere(Map<String, dynamic> matiere) {
    setState(() {
      final exists = _selectedMatieres.any((m) => m['id'] == matiere['id']);
      if (exists) {
        _selectedMatieres.removeWhere((m) => m['id'] == matiere['id']);
        _coefficients.remove(matiere['id']);
      } else {
        _selectedMatieres.add(matiere);
        _coefficients[matiere['id']] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Modifier la classe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la classe',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              const Text('Matières assignées', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMatieres.isEmpty
                      ? [const Text('Aucune matière sélectionnée', style: TextStyle(color: Colors.grey))]
                      : _selectedMatieres.map((matiere) {
                          return Chip(
                            label: Text(matiere['nom']),
                            backgroundColor: const Color(0xFFF47C3C).withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleMatiere(matiere),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Toutes les matières', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.matieres.map((matiere) {
                      final isSelected = _selectedMatieres.any((m) => m['id'] == matiere['id']);
                      return FilterChip(
                        label: Text(matiere['nom']),
                        selected: isSelected,
                        onSelected: (_) => _toggleMatiere(matiere),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFF47C3C),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selectedMatieres.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Coefficients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _selectedMatieres.map((matiere) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 120, child: Text(matiere['nom'])),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: _coefficients[matiere['id']]?.toString() ?? '1',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onChanged: (value) {
                                    _coefficients[matiere['id']] = int.tryParse(value) ?? 1;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final matieresList = _selectedMatieres.map((m) => ({
                          'id': m['id'],
                          'coefficient': _coefficients[m['id']] ?? 1,
                        })).toList();
                        
                        Navigator.pop(context, {
                          'nom': _nomController.text,
                          'matieres': matieresList,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
                    child: const Text('MODIFIER'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AjouterMatiereDialog extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  const _AjouterMatiereDialog({required this.classes});

  @override
  _AjouterMatiereDialogState createState() => _AjouterMatiereDialogState();
}

class _AjouterMatiereDialogState extends State<_AjouterMatiereDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _coefficientController = TextEditingController(text: '1');
  List<Map<String, dynamic>> _selectedClasses = [];

  void _toggleClasse(Map<String, dynamic> classe) {
    setState(() {
      final exists = _selectedClasses.any((c) => c['id'] == classe['id']);
      if (exists) {
        _selectedClasses.removeWhere((c) => c['id'] == classe['id']);
      } else {
        _selectedClasses.add(classe);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ajouter une matière', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la matière',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coefficientController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Coefficient (1-10)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  final coef = int.tryParse(v);
                  if (coef == null || coef < 1 || coef > 10) return 'Coefficient entre 1 et 10';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Classes assignées', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedClasses.isEmpty
                      ? [const Text('Aucune classe sélectionnée', style: TextStyle(color: Colors.grey))]
                      : _selectedClasses.map((classe) {
                          return Chip(
                            label: Text(classe['nom']),
                            backgroundColor: Colors.green.withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleClasse(classe),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Toutes les classes', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.classes.map((classe) {
                      final isSelected = _selectedClasses.any((c) => c['id'] == classe['id']);
                      return FilterChip(
                        label: Text(classe['nom']),
                        selected: isSelected,
                        onSelected: (_) => _toggleClasse(classe),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final classesList = _selectedClasses.map((c) => ({'id': c['id']})).toList();
                        
                        Navigator.pop(context, {
                          'nom': _nomController.text,
                          'coefficient': int.parse(_coefficientController.text),
                          'classes': classesList,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
                    child: const Text('AJOUTER'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModifierMatiereDialog extends StatefulWidget {
  final Map<String, dynamic> matiere;
  final List<Map<String, dynamic>> classes;
  const _ModifierMatiereDialog({required this.matiere, required this.classes});

  @override
  _ModifierMatiereDialogState createState() => _ModifierMatiereDialogState();
}

class _ModifierMatiereDialogState extends State<_ModifierMatiereDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _coefficientController = TextEditingController();
  List<Map<String, dynamic>> _selectedClasses = [];

  @override
  void initState() {
    super.initState();
    _nomController.text = widget.matiere['nom'] ?? '';
    _coefficientController.text = (widget.matiere['coefficient'] ?? 1).toString();
    final classes = widget.matiere['classes'] as List? ?? [];
    for (var c in classes) {
      _selectedClasses.add({
        'id': c['id'],
        'nom': c['nom'],
      });
    }
  }

  void _toggleClasse(Map<String, dynamic> classe) {
    setState(() {
      final exists = _selectedClasses.any((c) => c['id'] == classe['id']);
      if (exists) {
        _selectedClasses.removeWhere((c) => c['id'] == classe['id']);
      } else {
        _selectedClasses.add(classe);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Modifier la matière', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la matière',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coefficientController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Coefficient (1-10)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  final coef = int.tryParse(v);
                  if (coef == null || coef < 1 || coef > 10) return 'Coefficient entre 1 et 10';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Classes assignées', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedClasses.isEmpty
                      ? [const Text('Aucune classe sélectionnée', style: TextStyle(color: Colors.grey))]
                      : _selectedClasses.map((classe) {
                          return Chip(
                            label: Text(classe['nom']),
                            backgroundColor: Colors.green.withOpacity(0.2),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _toggleClasse(classe),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Toutes les classes', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.classes.map((classe) {
                      final isSelected = _selectedClasses.any((c) => c['id'] == classe['id']);
                      return FilterChip(
                        label: Text(classe['nom']),
                        selected: isSelected,
                        onSelected: (_) => _toggleClasse(classe),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final classesList = _selectedClasses.map((c) => ({'id': c['id']})).toList();
                        
                        Navigator.pop(context, {
                          'nom': _nomController.text,
                          'coefficient': int.parse(_coefficientController.text),
                          'classes': classesList,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
                    child: const Text('MODIFIER'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}