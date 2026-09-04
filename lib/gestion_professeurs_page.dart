// lib/screens/gestion_professeurs_page.dart

import 'package:flutter/material.dart';
import '../services/professeur_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/annee_scolaire_model.dart';
import '../widgets/add_professeur_panel.dart';
import '../widgets/edit_professeur_panel.dart';

class GestionProfesseursPage extends StatefulWidget {
  @override
  _GestionProfesseursPageState createState() => _GestionProfesseursPageState();
}

class _GestionProfesseursPageState extends State<GestionProfesseursPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Services
  final ProfesseurService _profService = ProfesseurService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  // Données
  List<Map<String, dynamic>> _professeurs = [];
  List<Map<String, dynamic>> _filteredProfesseurs = [];
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _classes = [];
  List<AnneeScolaire> _anneesScolaires = [];
  int? _selectedAnneeId;
  int? _selectedClasseId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. Charger les années (ne doit jamais bloquer le chargement des professeurs
    // si cet appel échoue pour une raison quelconque, ex: route indisponible).
    try {
      final annees = await _anneeService.getAnneesScolaires();
      _anneesScolaires = annees;
      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }
    } catch (e) {
      _showSnackBar('Erreur (années scolaires): $e', Colors.red);
    }

    // 2. Charger les professeurs (avec filtre année) — indépendant du bloc ci-dessus.
    try {
      await _chargerProfesseurs();
    } catch (e) {
      _showSnackBar('Erreur (professeurs): $e', Colors.red);
    }

    // 3. Charger les matières et classes (pour les filtres et dialogues)
    try {
      final matieresResponse = await _profService.getMatieres();
      if (matieresResponse['success'] == true) {
        _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
      }

      final classesResponse = await _profService.getClasses(anneeScolaireId: _selectedAnneeId);
      if (classesResponse['success'] == true) {
        _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
      }
    } catch (e) {
      _showSnackBar('Erreur (matières/classes): $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerProfesseurs() async {
    final profsResponse = await _profService.getProfesseurs(anneeScolaireId: _selectedAnneeId);
    if (profsResponse['success'] == true) {
      setState(() {
        _professeurs = List<Map<String, dynamic>>.from(profsResponse['data']);
        _filterProfesseurs();
      });
    } else {
      _showSnackBar(
        'Impossible de charger les professeurs: ${profsResponse['message'] ?? 'Erreur inconnue'}',
        Colors.red,
      );
    }
  }

  void _filterProfesseurs() {
    setState(() {
      _filteredProfesseurs = _professeurs.where((prof) {
        // Recherche textuelle
        final fullName = '${prof['prenom']} ${prof['nom']}'.toLowerCase();
        final email = (prof['email'] ?? '').toLowerCase();
        final search = _searchQuery.toLowerCase();
        final matchesSearch = fullName.contains(search) || email.contains(search);

        // Filtre par classe (les classes assignées au professeur pour l'année sélectionnée)
        bool matchesClasse = true;
        if (_selectedClasseId != null) {
          // La réponse de l'API doit contenir les classes assignées pour l'année en cours
          final classeIds = List<int>.from(prof['classe_ids'] ?? []);
          matchesClasse = classeIds.contains(_selectedClasseId);
        }

        return matchesSearch && matchesClasse;
      }).toList();
    });
  }

  Future<void> _ajouterProfesseur() async {
    // Charger les données nécessaires si elles ne le sont pas déjà
    if (_matieres.isEmpty) {
      final matieresResponse = await _profService.getMatieres();
      if (matieresResponse['success'] == true) {
        setState(() {
          _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
        });
      }
    }
    if (_classes.isEmpty) {
      final classesResponse = await _profService.getClasses(anneeScolaireId: _selectedAnneeId);
      if (classesResponse['success'] == true) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
        });
      }
    }

    // Ouvrir le panneau d'ajout (qui doit inclure un sélecteur d'année)
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProfesseurDialog(
        matieres: _matieres,
        classes: _classes,
        annees: _anneesScolaires,
        selectedAnneeId: _selectedAnneeId,
      ),
    );

    if (result != null) {
      // Créer le professeur (sans les classes)
      final professeurData = <String, dynamic>{
        'nom': result['nom'],
        'prenom': result['prenom'],
        'email': result['email'],
        'numero': result['numero'],
        'matiere_id': result['matiere_id'],
      };
      // Si l'admin ne saisit pas de mot de passe, on ne l'envoie pas du tout :
      // c'est le backend qui applique son propre défaut ("password").
      if (result['password'] != null && (result['password'] as String).isNotEmpty) {
        professeurData['password'] = result['password'];
      }

      final createResponse = await _profService.addProfesseur(professeurData);
      if (createResponse['success'] == true) {
        final professeurId = createResponse['data']['id'];

        // Assigner les classes pour l'année sélectionnée
        final classeIds = List<int>.from(result['classe_ids'] ?? []);
        if (classeIds.isNotEmpty && result['annee_scolaire_id'] != null) {
          await _profService.addClassesToProfesseur(
            professeurId,
            classeIds,
            anneeScolaireId: result['annee_scolaire_id']!,
          );
        }

        _showSnackBar('Professeur ajouté avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(createResponse['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _modifierProfesseur(Map<String, dynamic> professeur) async {
    // Charger les classes si nécessaire
    if (_classes.isEmpty) {
      final classesResponse = await _profService.getClasses(anneeScolaireId: _selectedAnneeId);
      if (classesResponse['success'] == true) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
        });
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProfesseurDialog(
        matieres: _matieres,
        classes: _classes,
        annees: _anneesScolaires,
        selectedAnneeId: _selectedAnneeId,
        professeur: professeur,
      ),
    );

    if (result != null) {
      // Mettre à jour les informations du professeur
      final updateData = {
        'nom': result['nom'],
        'prenom': result['prenom'],
        'email': result['email'],
        'numero': result['numero'],
        'matiere_id': result['matiere_id'],
      };
      final updateResponse = await _profService.updateProfesseur(professeur['id'], updateData);
      if (updateResponse['success'] == true) {
        // Mettre à jour les classes assignées pour l'année
        final classeIds = List<int>.from(result['classe_ids'] ?? []);
        final anneeId = result['annee_scolaire_id'];
        if (anneeId != null) {
          // On pourrait supprimer toutes les assignations existantes pour cette année puis ajouter les nouvelles
          // Mais le service actuel a seulement addClassesToProfesseur.
          // Pour simplifier, on suppose que l'API remplace les assignations existantes.
          // Si ce n'est pas le cas, il faudrait une méthode de synchronisation.
          await _profService.addClassesToProfesseur(
            professeur['id'],
            classeIds,
            anneeScolaireId: anneeId,
          );
        }
        _showSnackBar('Professeur modifié avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(updateResponse['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _supprimerProfesseur(Map<String, dynamic> professeur) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer ${professeur['prenom']} ${professeur['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _profService.deleteProfesseur(professeur['id']);
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

                // FILTRES : Année + Classe
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Sélecteur d'année
                      if (_anneesScolaires.isNotEmpty)
                        Row(
                          children: [
                            const Text('Année : ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<int>(
                                value: _selectedAnneeId,
                                isExpanded: true,
                                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                                    _selectedClasseId = null; // Réinitialiser le filtre classe
                                  });
                                  await _loadData();
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      // Sélecteur de classe
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                              ),
                              child: DropdownButton<int>(
                                value: _selectedClasseId,
                                hint: Text(
                                  'Toutes les classes',
                                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                                underline: const SizedBox(),
                                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Toutes les classes'),
                                  ),
                                  ..._classes.map((classe) {
                                    return DropdownMenuItem<int>(
                                      value: classe['id'],
                                      child: Text(classe['nom'] ?? '-'),
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
                          ),
                        ],
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
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou email...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
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
                        borderSide: const BorderSide(color: Color(0xFFF47C3C), width: 1),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
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
                              Icon(Icons.person_off, size: 64, color: isDarkMode ? Colors.grey.shade600 : Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _selectedAnneeId == null
                                    ? 'Veuillez sélectionner une année'
                                    : 'Aucun professeur trouvé',
                                style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
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
                                isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
                              ),
                              headingTextStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                                (states) => isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : null,
                              ),
                              dividerThickness: 0,
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
                                  color: MaterialStateProperty.resolveWith<Color?>(
                                    (states) {
                                      if (index % 2 == 0) {
                                        return isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
                                      }
                                      return null;
                                    },
                                  ),
                                  cells: [
                                    DataCell(Text('${index + 1}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                                    DataCell(Text('${prof['prenom']} ${prof['nom']}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                                    DataCell(Text(prof['email'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                                    DataCell(Text(prof['numero'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                                    DataCell(Text(prof['matiere_nom'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black))),
                                    DataCell(
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: _buildClassesChips(prof['classes_names'] ?? [], isDarkMode),
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

  Widget _buildClassesChips(List<dynamic> classesNames, bool isDarkMode) {
    if (classesNames.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune classe',
          style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: classesNames.map((className) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF47C3C).withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF47C3C).withOpacity(isDarkMode ? 0.5 : 0.3)),
          ),
          child: Text(
            className.toString(),
            style: const TextStyle(fontSize: 10, color: Color(0xFFF47C3C), fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
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
              style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DIALOGUE UNIFIÉ POUR L'AJOUT ET LA MODIFICATION ====================

class _ProfesseurDialog extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final List<Map<String, dynamic>> classes;
  final List<AnneeScolaire> annees;
  final int? selectedAnneeId;
  final Map<String, dynamic>? professeur;

  const _ProfesseurDialog({
    required this.matieres,
    required this.classes,
    required this.annees,
    this.selectedAnneeId,
    this.professeur,
  });

  @override
  __ProfesseurDialogState createState() => __ProfesseurDialogState();
}

class __ProfesseurDialogState extends State<_ProfesseurDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroController = TextEditingController();
  int? _matiereId;
  String? _password;
  int? _anneeScolaireId;
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
    // Définir l'année par défaut
    if (widget.selectedAnneeId != null) {
      _anneeScolaireId = widget.selectedAnneeId;
    } else if (widget.annees.isNotEmpty) {
      _anneeScolaireId = widget.annees.first.id;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      title: Text(
        widget.professeur == null ? 'Ajouter un professeur' : 'Modifier le professeur',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informations personnelles
              _buildTextField(
                controller: _nomController,
                label: 'Nom',
                icon: Icons.person,
                isDarkMode: isDarkMode,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _prenomController,
                label: 'Prénom',
                icon: Icons.person_outline,
                isDarkMode: isDarkMode,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                isDarkMode: isDarkMode,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _numeroController,
                label: 'Numéro de téléphone',
                icon: Icons.phone,
                isDarkMode: isDarkMode,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),

              // Matière
              DropdownButtonFormField<int>(
                value: _matiereId,
                dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration(
                  label: 'Matière enseignée',
                  icon: Icons.book,
                  isDarkMode: isDarkMode,
                ),
                items: widget.matieres.map((m) {
                  return DropdownMenuItem<int>(
                    value: m['id'],
                    child: Text(m['nom'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _matiereId = value),
                validator: (v) => v == null ? 'Sélectionnez une matière' : null,
              ),
              const SizedBox(height: 12),

              // Année scolaire
              DropdownButtonFormField<int>(
                value: _anneeScolaireId,
                dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: _buildInputDecoration(
                  label: 'Année scolaire',
                  icon: Icons.calendar_today,
                  isDarkMode: isDarkMode,
                ),
                items: widget.annees.map((annee) {
                  return DropdownMenuItem<int>(
                    value: annee.id,
                    child: Text(annee.libelle ?? 'Année ${annee.id}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _anneeScolaireId = value),
                validator: (v) => v == null ? 'Sélectionnez une année' : null,
              ),
              const SizedBox(height: 12),

              // Mot de passe (seulement pour l'ajout)
              if (widget.professeur == null)
                _buildTextField(
                  controller: null,
                  label: 'Mot de passe (défaut: password)',
                  icon: Icons.lock,
                  isDarkMode: isDarkMode,
                  obscureText: true,
                  onChanged: (value) => _password = value,
                ),
              const SizedBox(height: 12),

              // Classes assignées
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classes assignées',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.classes.map((classe) {
                        final isSelected = _selectedClasseIds.contains(classe['id']);
                        return FilterChip(
                          label: Text(
                            classe['nom'] ?? '-',
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
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
                          backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_anneeScolaireId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez sélectionner une année'), backgroundColor: Colors.orange),
                );
                return;
              }
              final data = {
                'nom': _nomController.text,
                'prenom': _prenomController.text,
                'email': _emailController.text,
                'numero': _numeroController.text,
                'matiere_id': _matiereId,
                'classe_ids': _selectedClasseIds,
                'annee_scolaire_id': _anneeScolaireId,
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

  Widget _buildTextField({
    required TextEditingController? controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      onChanged: onChanged,
      decoration: _buildInputDecoration(label: label, icon: icon, isDarkMode: isDarkMode),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
      prefixIcon: Icon(icon, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF47C3C)),
      ),
    );
  }
}