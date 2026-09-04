// lib/screens/gestion_matieres_page.dart

import 'package:flutter/material.dart';
import '../services/matiere_service.dart';
import '../services/classmat_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/annee_scolaire_model.dart';

class GestionMatieresPage extends StatefulWidget {
  @override
  _GestionMatieresPageState createState() => _GestionMatieresPageState();
}

class _GestionMatieresPageState extends State<GestionMatieresPage> {
  final MatiereService _matiereService = MatiereService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _filteredMatieres = [];
  List<AnneeScolaire> _anneesScolaires = [];
  int? _selectedAnneeId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les années
      final annees = await _anneeService.getAnneesScolaires();
      _anneesScolaires = annees;

      // Déterminer l'année par défaut (en cours ou première)
      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }

      // Charger les matières avec le filtre année
      await _chargerMatieres();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

Future<void> _chargerMatieres() async {
  setState(() => _isLoading = true);

  try {
    // ✅ Utiliser getMatieresList()
    final matieres = await _matiereService.getMatieresList(
      anneeScolaireId: _selectedAnneeId,
    );

    setState(() {
      _matieres = matieres;
      _filteredMatieres = matieres;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    _showSnackBar('Erreur: $e', Colors.red);
  }
}

  void _filterMatieres() {
    setState(() {
      _filteredMatieres = _matieres.where((matiere) {
        final nom = matiere['nom'].toLowerCase();
        return nom.contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _ajouterMatiere() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterModifierMatiereDialog(),
    );

    if (result != null) {
      final response = await _matiereService.addMatiere(result);
      if (response['success'] == true) {
        _showSnackBar('Matière ajoutée avec succès', Colors.green);
        await _chargerMatieres();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _modifierMatiere(Map<String, dynamic> matiere) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterModifierMatiereDialog(matiere: matiere),
    );

    if (result != null) {
      final response = await _matiereService.updateMatiere(matiere['id'], result);
      if (response['success'] == true) {
        _showSnackBar('Matière modifiée avec succès', Colors.green);
        await _chargerMatieres();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _supprimerMatiere(Map<String, dynamic> matiere) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer la matière ${matiere['nom']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _matiereService.deleteMatiere(matiere['id']);
      if (response['success'] == true) {
        _showSnackBar('Matière supprimée avec succès', Colors.green);
        await _chargerMatieres();
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
        title: const Text('Gestion des matières'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterMatiere,
            tooltip: 'Ajouter une matière',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerMatieres,
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
                          'Année : ',
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
                              await _chargerMatieres();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                // STATS CARDS
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard('Total matières', _matieres.length.toString(), const Color.fromARGB(255, 4, 252, 223)),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Coef. moyen',
                        _matieres.isEmpty
                            ? '0'
                            : (_matieres.fold(0.0, (sum, m) => sum + (m['coefficient'] ?? 1)) / _matieres.length)
                                .toStringAsFixed(1),
                        const Color(0xFFF47C3C),
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
                      _filterMatieres();
                    },
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une matière...',
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
                        borderSide: const BorderSide(color: Color(0xFFF47C3C), width: 1),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    ),
                  ),
                ),
                // DATA TABLE
                Expanded(
                  child: _filteredMatieres.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _selectedAnneeId == null
                                    ? 'Veuillez sélectionner une année'
                                    : 'Aucune matière trouvée pour cette année',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
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
                              (states) => isDarkMode ? const Color(0xFF2A2A2A) : Colors.transparent,
                            ),
                            dividerThickness: 0,
                            columns: const [
                              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Nom de la matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Coefficient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(matiere['nom'])),
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
                                        'Coef. ${matiere['coefficient'] ?? 1}',
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          onPressed: () => _modifierMatiere(matiere),
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _supprimerMatiere(matiere),
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

// Dialogue pour ajouter/modifier une matière (inchangé)
class _AjouterModifierMatiereDialog extends StatefulWidget {
  final Map<String, dynamic>? matiere;

  const _AjouterModifierMatiereDialog({this.matiere});

  @override
  __AjouterModifierMatiereDialogState createState() => __AjouterModifierMatiereDialogState();
}

class __AjouterModifierMatiereDialogState extends State<_AjouterModifierMatiereDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _coefficientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.matiere != null) {
      _nomController.text = widget.matiere!['nom'] ?? '';
      _coefficientController.text = (widget.matiere!['coefficient'] ?? 1).toString();
    } else {
      _coefficientController.text = '1';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _coefficientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.matiere == null ? 'Ajouter une matière' : 'Modifier la matière'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: 'Nom de la matière',
                prefixIcon: const Icon(Icons.book),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coefficientController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coefficient',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                final coef = int.tryParse(v);
                if (coef == null || coef < 1 || coef > 10) return 'Coefficient entre 1 et 10';
                return null;
              },
            ),
          ],
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
              Navigator.pop(context, {
                'nom': _nomController.text,
                'coefficient': int.parse(_coefficientController.text),
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: Text(widget.matiere == null ? 'AJOUTER' : 'MODIFIER'),
        ),
      ],
    );
  }
}