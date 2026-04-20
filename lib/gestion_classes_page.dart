import 'package:flutter/material.dart';
import '../services/classe_service.dart';

class GestionClassesPage extends StatefulWidget {
  @override
  _GestionClassesPageState createState() => _GestionClassesPageState();
}

class _GestionClassesPageState extends State<GestionClassesPage> {
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _filteredClasses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final response = await ClasseService.getClasses();
    
    if (response['success'] == true) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response['data']);
        _filteredClasses = _classes;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
    }
  }

  void _filterClasses() {
    setState(() {
      _filteredClasses = _classes.where((classe) {
        final nom = classe['nom'].toLowerCase();
        return nom.contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _ajouterClasse() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterModifierClasseDialog(),
    );
    
    if (result != null) {
      final response = await ClasseService.addClasse(result);
      if (response['success'] == true) {
        _showSnackBar('Classe ajoutée avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _modifierClasse(Map<String, dynamic> classe) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterModifierClasseDialog(classe: classe),
    );
    
    if (result != null) {
      final response = await ClasseService.updateClasse(classe['id'], result);
      if (response['success'] == true) {
        _showSnackBar('Classe modifiée avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _supprimerClasse(Map<String, dynamic> classe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer la classe ${classe['nom']} ?'),
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
      final response = await ClasseService.deleteClasse(classe['id']);
      if (response['success'] == true) {
        _showSnackBar('Classe supprimée avec succès', Colors.green);
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
        title: const Text('Gestion des classes'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterClasse,
            tooltip: 'Ajouter une classe',
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
               // STATS CARDS
              Container(
              padding: const EdgeInsets.all(16),
              child: Row(
              children: [
              _buildStatCard('Total classes', _classes.length.toString(), const Color.fromARGB(255, 4, 252, 223)),
              const SizedBox(width: 12),
              _buildStatCard('Total élèves', _classes.fold<int>(0, (sum, c) => sum + (c['effectif'] as int? ?? 0)).toString(), const Color(0xFFF47C3C)),
              const SizedBox(width: 12),
              _buildStatCard('Moyenne/classe', _classes.isEmpty ? '0' : (_classes.fold<double>(0, (sum, c) => sum + (c['effectif'] as int? ?? 0)) / _classes.length).toStringAsFixed(1), Colors.green),
              ],
              ),
              ),
                // BARRE DE RECHERCHE
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterClasses();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une classe...',
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
                  child: _filteredClasses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('Aucune classe trouvée'),
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
                            columns: const [
                              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Nom de la classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${classe['effectif'] ?? 0} élèves',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
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
                                          onPressed: () => _modifierClasse(classe),
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _supprimerClasse(classe),
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

// Dialogue pour ajouter/modifier une classe
class _AjouterModifierClasseDialog extends StatefulWidget {
  final Map<String, dynamic>? classe;

  const _AjouterModifierClasseDialog({this.classe});

  @override
  __AjouterModifierClasseDialogState createState() => __AjouterModifierClasseDialogState();
}

class __AjouterModifierClasseDialogState extends State<_AjouterModifierClasseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.classe != null) {
      _nomController.text = widget.classe!['nom'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classe == null ? 'Ajouter une classe' : 'Modifier la classe'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nomController,
          decoration: InputDecoration(
            labelText: 'Nom de la classe',
            prefixIcon: const Icon(Icons.class_),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
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
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: Text(widget.classe == null ? 'AJOUTER' : 'MODIFIER'),
        ),
      ],
    );
  }
}