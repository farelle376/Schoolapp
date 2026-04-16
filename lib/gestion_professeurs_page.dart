// lib/screens/gestion_professeurs_page.dart

import 'package:flutter/material.dart';
import '../services/professeur_service.dart';
import '../widgets/add_professeur_panel.dart';
import '../widgets/edit_professeur_panel.dart';

class GestionProfesseursPage extends StatefulWidget {
  @override
  _GestionProfesseursPageState createState() => _GestionProfesseursPageState();
}

class _GestionProfesseursPageState extends State<GestionProfesseursPage> {
  List<Map<String, dynamic>> _professeurs = [];
  List<Map<String, dynamic>> _filteredProfesseurs = [];
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedClasseId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Charger les professeurs
    final profsResponse = await ProfesseurService.getProfesseurs();
    if (profsResponse['success'] == true) {
      setState(() {
        _professeurs = List<Map<String, dynamic>>.from(profsResponse['data']);
        _filteredProfesseurs = _professeurs;
      });
    }
    
    // Charger les matières
    final matieresResponse = await ProfesseurService.getMatieres();
    if (matieresResponse['success'] == true) {
      setState(() {
        _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
      });
    }
    
    // Charger les classes
    final classesResponse = await ProfesseurService.getClasses();
    if (classesResponse['success'] == true) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
      });
    }
    
    setState(() => _isLoading = false);
  }

  void _filterProfesseurs() {
    setState(() {
      _filteredProfesseurs = _professeurs.where((prof) {
        final fullName = '${prof['prenom']} ${prof['nom']}'.toLowerCase();
        final email = (prof['email'] ?? '').toLowerCase();
        final search = _searchQuery.toLowerCase();
        final matchesSearch = fullName.contains(search) || email.contains(search);
        bool matchesClasse = true;
        if (_selectedClasseId != null) {
          final classeIds = List<int>.from(prof['classe_ids'] ?? []);
          matchesClasse = classeIds.contains(_selectedClasseId);
        }
        return matchesSearch && matchesClasse;
      }).toList();
    });
  }

  Future<void> _ajouterProfesseur() async {
  // Si les matières ou classes ne sont pas encore chargées, charge-les d'abord
  if (_matieres.isEmpty) {
    final matieresResponse = await ProfesseurService.getMatieres();
    if (matieresResponse['success'] == true) {
      setState(() {
        _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
      });
    }
  }
  
  if (_classes.isEmpty) {
    final classesResponse = await ProfesseurService.getClasses();
    if (classesResponse['success'] == true) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
      });
    }
  }
  
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 1500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddProfesseurPanel(
        matieres: _matieres,
        classes: _classes,
        onAdd: () {
          _loadData();
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

Future<void> _modifierProfesseur(Map<String, dynamic> professeur) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 1500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EditProfesseurPanel(
          professeur: professeur,
          matieres: _matieres,
          onUpdate: () {
            _loadData();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  Future<void> _supprimerProfesseur(Map<String, dynamic> professeur) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer ${professeur['prenom']} ${professeur['nom']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final response = await ProfesseurService.deleteProfesseur(professeur['id']);
      
      if (response['success'] == true) {
        _showSnackBar('Professeur supprimé avec succès', Colors.green);
        _loadData();
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
        title: const Text('Gestion des professeurs'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterProfesseur,
            tooltip: 'Ajouter un professeur',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // STATS CARDS
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard('Total profs', _professeurs.length.toString(), const Color.fromARGB(255, 4, 252, 223)),
                      const SizedBox(width: 12),
                      _buildStatCard('Matières', _matieres.length.toString(), const Color(0xFFF47C3C)),
                      const SizedBox(width: 12),
                      _buildStatCard('Classes', _classes.length.toString(), Colors.green),
                    ],
                  ),
                ),
                // ✅ FILTRE PAR CLASSE (Liste déroulante)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.filter_list, size: 18, color: Color(0xFFF47C3C)),
      const SizedBox(width: 8),
      Container(
        width: 250, // Largeur réduite de la liste déroulante
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButton<int>(
          value: _selectedClasseId,
          hint: const Text('Toutes les classes'),
          isExpanded: true,
          underline: const SizedBox(),
            items: [
      const DropdownMenuItem<int>(
        value: null,
        child: Text('📚 Toutes les classes'),
      ),
            ..._classes.map((classe) {
              return DropdownMenuItem<int>(
                value: classe['id'],
                child: Text('📖 ${classe['nom']}'),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedClasseId = value;
              _filterProfesseurs();
            });
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
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterProfesseurs();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou email...',
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
                // DATA TABLE
                Expanded(
                  child: _filteredProfesseurs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Aucun professeur trouvé'),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateProperty.all(
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : const Color(0xFFF47C3C).withOpacity(0.1),
                              ),
                              columns: const [
                                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Numéro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                              rows: _filteredProfesseurs.asMap().entries.map((entry) {
                                final index = entry.key;
                                final prof = entry.value;
                                
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(Text('${prof['prenom']} ${prof['nom']}')),
                                    DataCell(Text(prof['email'] ?? '-')),
                                    DataCell(Text(prof['numero'] ?? '-')),
                                    DataCell(Text(prof['matiere_nom'] ?? '-')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${prof['classes_count'] ?? 0} classe(s)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () => _modifierProfesseur(prof),
                                            tooltip: 'Modifier',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => _supprimerProfesseur(prof),
                                            tooltip: 'Supprimer',
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
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialogue pour ajouter/modifier un professeur
class _AjouterModifierProfesseurDialog extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final List<Map<String, dynamic>> classes;
  final Map<String, dynamic>? professeur;

  const _AjouterModifierProfesseurDialog({
    required this.matieres,
    required this.classes,
    this.professeur,
  });

  @override
  __AjouterModifierProfesseurDialogState createState() => __AjouterModifierProfesseurDialogState();
}

class __AjouterModifierProfesseurDialogState extends State<_AjouterModifierProfesseurDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroController = TextEditingController();
  int? _matiereId;
  String? _password;
  List<int> _selectedClasseIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.professeur != null) {
      _nomController.text = widget.professeur!['nom'] ?? '';
      _prenomController.text = widget.professeur!['prenom'] ?? '';
      _emailController.text = widget.professeur!['email'] ?? '';
      _numeroController.text = widget.professeur!['numero'] ?? '';
      _matiereId = widget.professeur!['matiere_id'];
      _selectedClasseIds = List<int>.from(widget.professeur!['classe_ids'] ?? []);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.professeur == null ? 'Ajouter un professeur' : 'Modifier le professeur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _matiereId,
                decoration: InputDecoration(
                  labelText: 'Matière enseignée',
                  prefixIcon: const Icon(Icons.book),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.matieres.map((m) {
                  return DropdownMenuItem<int>(
                    value: m['id'],
                    child: Text(m['nom']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _matiereId = value),
                validator: (v) => v == null ? 'Sélectionnez une matière' : null,
              ),
              if (widget.professeur == null)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      obscureText: true,
                      onChanged: (value) => _password = value,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe (par défaut: 1234)',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classes assignées',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.classes.map((classe) {
                        final isSelected = _selectedClasseIds.contains(classe['id']);
                        return FilterChip(
                          label: Text(classe['nom']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedClasseIds.add(classe['id']);
                              } else {
                                _selectedClasseIds.remove(classe['id']);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFF47C3C),
                        );
                      }).toList(),
                    ),
                  ],
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'nom': _nomController.text,
                'prenom': _prenomController.text,
                'email': _emailController.text,
                'numero': _numeroController.text,
                'matiere_id': _matiereId,
                'classe_ids': _selectedClasseIds,
              };
              if (_password != null && _password!.isNotEmpty) {
                data['password'] = _password;
              }
              Navigator.pop(context, data);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: Text(widget.professeur == null ? 'AJOUTER' : 'MODIFIER'),
        ),
      ],
    );
  }
}