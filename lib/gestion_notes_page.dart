// lib/screens/gestion_notes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/note_service.dart';

class GestionNotesPage extends StatefulWidget {
  @override
  _GestionNotesPageState createState() => _GestionNotesPageState();
}

class _GestionNotesPageState extends State<GestionNotesPage> {
  List<Map<String, dynamic>> _groupedNotes = [];
  List<Map<String, dynamic>> _filteredGroupedNotes = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _matieres = [];
  bool _isLoading = true;
  
  // Filtres
  int? _selectedClasseId;
  int? _selectedMatiereId;
  int? _selectedTrimestre;
  
  // Statistiques
  int _totalNotes = 0;
  int _notesValidees = 0;
  int _notesEnAttente = 0;
  double _moyenneGenerale = 0;

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String cleanValue = value.replaceAll(',', '.');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  String _getTrimestreText(dynamic trimestre) {
    final t = _toInt(trimestre);
    switch (t) {
      case 1: return '1er Trim.';
      case 2: return '2ème Trim.';
      case 3: return '3ème Trim.';
      default: return 'T$t';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Chargement en parallèle pour plus de rapidité
    final results = await Future.wait([
      NoteService.getClasses(),
      NoteService.getMatieres(),
      NoteService.getNotesStats(),
      NoteService.getNotes(),
    ]);
    
    final classesResponse = results[0];
    final matieresResponse = results[1];
    final statsResponse = results[2];
    final notesResponse = results[3];
    
    // Préparer les données avant setState
    List<Map<String, dynamic>> newClasses = [];
    List<Map<String, dynamic>> newMatieres = [];
    
    if (classesResponse['success'] == true) {
      newClasses = List<Map<String, dynamic>>.from(classesResponse['data']);
    }
    
    if (matieresResponse['success'] == true) {
      newMatieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
    }
    
    // Traitement lourd déplacé hors UI
    List<Map<String, dynamic>> newGroupedNotes = [];
    if (notesResponse['success'] == true && notesResponse['data'] != null) {
      final notes = List<Map<String, dynamic>>.from(notesResponse['data']);
      
      // Utilisation de compute pour déplacer le traitement lourd hors UI
      if (kIsWeb) {
        // Web: traitement normal car compute n'est pas supporté
        newGroupedNotes = _processNotes(notes);
      } else {
        // Mobile: utilisation d'isolate
        newGroupedNotes = await compute(_processNotesInIsolate, notes);
      }
    }
    
    // Un seul setState pour tout mettre à jour
    setState(() {
      _classes = newClasses;
      _matieres = newMatieres;
      _groupedNotes = newGroupedNotes;
      _filteredGroupedNotes = newGroupedNotes;
      
      _totalNotes = statsResponse['total_notes'] ?? 0;
      _notesValidees = statsResponse['notes_validees'] ?? 0;
      _notesEnAttente = statsResponse['notes_en_attente'] ?? 0;
      _moyenneGenerale = _toDouble(statsResponse['moyenne_generale']);
      
      _isLoading = false;
    });
  }

  // Version optimisée du traitement des notes
  List<Map<String, dynamic>> _processNotes(List<Map<String, dynamic>> notes) {
    final Map<String, Map<String, dynamic>> grouped = {};
    
    // Optimisation: utiliser for standard au lieu de for-in pour de meilleures performances
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final trimestreValue = _toInt(note['trimestre']);
      final eleveId = note['eleve_id'];
      final matiereId = note['matiere_id'];
      final key = '${eleveId}_${matiereId}_$trimestreValue';
      
      Map<String, dynamic>? currentGroup = grouped[key];
      
      if (currentGroup == null) {
        currentGroup = {
          'eleve_id': eleveId,
          'eleve_nom': note['eleve_nom'] ?? 'Inconnu',
          'classe_id': note['classe_id'],
          'classe_nom': note['classe_nom'] ?? 'Inconnu',
          'matiere_id': matiereId,
          'matiere_nom': note['matiere_nom'] ?? 'Inconnu',
          'professeur_nom': note['professeur_nom'] ?? 'Inconnu',
          'trimestre': trimestreValue,
          'interrogations': <Map<String, dynamic>>[],
          'devoirs': <Map<String, dynamic>>[],
          'moyenne': 0.0,
        };
        grouped[key] = currentGroup;
      }
      
      final noteValue = _toDouble(note['note']);
      final noteWithData = {
        'id': note['id'],
        'note': noteValue,
        'type_note': note['type_note'],
        'trimestre': trimestreValue,
      };
      
      if (note['type_note'] == 'interrogation') {
        (currentGroup['interrogations'] as List).add(noteWithData);
      } else {
        (currentGroup['devoirs'] as List).add(noteWithData);
      }
      
      // Calcul optimisé de la moyenne
      double total = 0;
      int count = 0;
      final interrogations = currentGroup['interrogations'] as List;
      final devoirs = currentGroup['devoirs'] as List;
      
      for (int j = 0; j < interrogations.length; j++) {
        total += interrogations[j]['note'];
        count++;
      }
      for (int j = 0; j < devoirs.length; j++) {
        total += devoirs[j]['note'];
        count++;
      }
      currentGroup['moyenne'] = count > 0 ? total / count : 0;
    }
    
    return grouped.values.toList();
  }

  // Fonction pour le compute (doit être en dehors de la classe)
  void _applyFilters() {
    setState(() {
      _filteredGroupedNotes = _groupedNotes.where((note) {
        if (_selectedClasseId != null && note['classe_id'] != _selectedClasseId) return false;
        if (_selectedMatiereId != null && note['matiere_id'] != _selectedMatiereId) return false;
        if (_selectedTrimestre != null && _toInt(note['trimestre']) != _selectedTrimestre) return false;
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedClasseId = null;
      _selectedMatiereId = null;
      _selectedTrimestre = null;
    });
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final response = await NoteService.getNotes(
      classeId: _selectedClasseId,
      matiereId: _selectedMatiereId,
      trimestre: _selectedTrimestre,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final notes = List<Map<String, dynamic>>.from(response['data']);
      
      List<Map<String, dynamic>> newGroupedNotes = [];
      
      if (notes.isEmpty) {
        newGroupedNotes = [];
      } else {
        if (kIsWeb) {
          newGroupedNotes = _processNotes(notes);
        } else {
          newGroupedNotes = await compute(_processNotesInIsolate, notes);
        }
      }
      
      setState(() {
        _groupedNotes = newGroupedNotes;
        _filteredGroupedNotes = newGroupedNotes;
      });
    }
  }

  Future<void> _loadStats() async {
    final response = await NoteService.getNotesStats();
    
    if (response['success'] == true) {
      setState(() {
        _totalNotes = response['total_notes'] ?? 0;
        _notesValidees = response['notes_validees'] ?? 0;
        _notesEnAttente = response['notes_en_attente'] ?? 0;
        _moyenneGenerale = _toDouble(response['moyenne_generale']);
      });
    }
  }

  void _openFilterPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterPopupWidget(
        classes: _classes,
        matieres: _matieres,
        selectedClasseId: _selectedClasseId,
        selectedMatiereId: _selectedMatiereId,
        selectedTrimestre: _selectedTrimestre,
        onApply: (classeId, matiereId, trimestre) {
          setState(() {
            _selectedClasseId = classeId;
            _selectedMatiereId = matiereId;
            _selectedTrimestre = trimestre;
            _applyFilters();
          });
        },
        onReset: () {
          _resetFilters();
        },
      ),
    );
  }

  Future<void> _modifierNote(Map<String, dynamic> note) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ModifierNoteDialog(note: note),
    );
    
    if (result != null) {
      final response = await NoteService.updateNote(note['id'], result);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note modifiée avec succès'), backgroundColor: Colors.green),
        );
        _loadNotes();
        _loadStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _supprimerNote(Map<String, dynamic> note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer cette note ?'),
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
      final response = await NoteService.deleteNote(note['id']);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note supprimée avec succès'), backgroundColor: Colors.green),
        );
        _loadNotes();
        _loadStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getNoteColor(double note) {
    if (note >= 16) return Colors.green;
    if (note >= 14) return Colors.lightGreen;
    if (note >= 12) return Colors.orange;
    if (note >= 10) return Colors.amber;
    return Colors.red;
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            Text(title, 
              style: TextStyle(
                fontSize: 12, 
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: color
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des notes'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
                      _buildStatCard('Total notes', _totalNotes.toString(), const Color.fromARGB(255, 4, 252, 223)),
                      const SizedBox(width: 12),
                      _buildStatCard('Validées', _notesValidees.toString(), Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('En attente', _notesEnAttente.toString(), Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatCard('Moyenne', _moyenneGenerale.toStringAsFixed(2), const Color(0xFFF47C3C)),
                    ],
                  ),
                ),
                // Bouton filtre
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openFilterPopup,
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filtrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF47C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      if (_selectedClasseId != null || _selectedMatiereId != null || _selectedTrimestre != null)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Filtre actif',
                                style: TextStyle(fontSize: 11, color: Colors.green),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _resetFilters,
                                child: const Icon(Icons.close, size: 14, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // DATA TABLE
                Expanded(
                  child: _filteredGroupedNotes.isEmpty
                      ? const Center(child: Text('Aucune note trouvée'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 12,
                            headingRowColor: MaterialStateProperty.all(
                              isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
                            ),
                            columns: const [
                              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Élève', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Prof.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Trim.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Interro.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Devoirs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Moy.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                            rows: _filteredGroupedNotes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final moyenne = item['moyenne'] ?? 0;
                              
                              return DataRow(
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(item['eleve_nom'] ?? '-', maxLines: 1)),
                                  DataCell(Text(item['classe_nom'] ?? '-', maxLines: 1)),
                                  DataCell(Text(item['matiere_nom'] ?? '-', maxLines: 1)),
                                  DataCell(Text(item['professeur_nom'] ?? '-', maxLines: 1)),
                                  DataCell(Text(_getTrimestreText(item['trimestre']))),
                                  DataCell(
                                    Wrap(
                                      spacing: 4,
                                      children: (item['interrogations'] as List).map<Widget>((note) {
                                        return Chip(
                                          label: Text(note['note'].toString()),
                                          backgroundColor: _getNoteColor(note['note']).withOpacity(0.1),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  DataCell(
                                    Wrap(
                                      spacing: 4,
                                      children: (item['devoirs'] as List).map<Widget>((note) {
                                        return Chip(
                                          label: Text(note['note'].toString()),
                                          backgroundColor: _getNoteColor(note['note']).withOpacity(0.1),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(moyenne.toStringAsFixed(2)),
                                      backgroundColor: _getNoteColor(moyenne).withOpacity(0.2),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                          onPressed: () {
                                            if ((item['interrogations'] as List).isNotEmpty) {
                                              _modifierNote((item['interrogations'] as List)[0]);
                                            } else if ((item['devoirs'] as List).isNotEmpty) {
                                              _modifierNote((item['devoirs'] as List)[0]);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                          onPressed: () {
                                            if ((item['interrogations'] as List).isNotEmpty) {
                                              _supprimerNote((item['interrogations'] as List)[0]);
                                            } else if ((item['devoirs'] as List).isNotEmpty) {
                                              _supprimerNote((item['devoirs'] as List)[0]);
                                            }
                                          },
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
}

// Fonction pour le compute (doit être en dehors de la classe)
List<Map<String, dynamic>> _processNotesInIsolate(List<Map<String, dynamic>> notes) {
  final Map<String, Map<String, dynamic>> grouped = {};
  
  for (int i = 0; i < notes.length; i++) {
    final note = notes[i];
    final trimestreValue = (note['trimestre'] is int) 
        ? note['trimestre'] as int 
        : int.tryParse(note['trimestre'].toString()) ?? 1;
    
    final key = '${note['eleve_id']}_${note['matiere_id']}_$trimestreValue';
    
    Map<String, dynamic>? currentGroup = grouped[key];
    
    if (currentGroup == null) {
      currentGroup = {
        'eleve_id': note['eleve_id'],
        'eleve_nom': note['eleve_nom'] ?? 'Inconnu',
        'classe_id': note['classe_id'],
        'classe_nom': note['classe_nom'] ?? 'Inconnu',
        'matiere_id': note['matiere_id'],
        'matiere_nom': note['matiere_nom'] ?? 'Inconnu',
        'professeur_nom': note['professeur_nom'] ?? 'Inconnu',
        'trimestre': trimestreValue,
        'interrogations': <Map<String, dynamic>>[],
        'devoirs': <Map<String, dynamic>>[],
        'moyenne': 0.0,
      };
      grouped[key] = currentGroup;
    }
    
    final noteValue = (note['note'] is double) 
        ? note['note'] as double 
        : double.tryParse(note['note'].toString()) ?? 0.0;
    
    final noteWithData = {
      'id': note['id'],
      'note': noteValue,
      'type_note': note['type_note'],
      'trimestre': trimestreValue,
    };
    
    if (note['type_note'] == 'interrogation') {
      (currentGroup['interrogations'] as List).add(noteWithData);
    } else {
      (currentGroup['devoirs'] as List).add(noteWithData);
    }
    
    double total = 0;
    int count = 0;
    final interrogations = currentGroup['interrogations'] as List;
    final devoirs = currentGroup['devoirs'] as List;
    
    for (int j = 0; j < interrogations.length; j++) {
      total += interrogations[j]['note'];
      count++;
    }
    for (int j = 0; j < devoirs.length; j++) {
      total += devoirs[j]['note'];
      count++;
    }
    currentGroup['moyenne'] = count > 0 ? total / count : 0;
  }
  
  return grouped.values.toList();
}

// ================= FILTER POPUP WIDGET ISOLÉ =================

class FilterPopupWidget extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> matieres;
  final int? selectedClasseId;
  final int? selectedMatiereId;
  final int? selectedTrimestre;
  final Function(int?, int?, int?) onApply;
  final VoidCallback onReset;

  const FilterPopupWidget({
    Key? key,
    required this.classes,
    required this.matieres,
    required this.selectedClasseId,
    required this.selectedMatiereId,
    required this.selectedTrimestre,
    required this.onApply,
    required this.onReset,
  }) : super(key: key);

  @override
  _FilterPopupWidgetState createState() => _FilterPopupWidgetState();
}

class _FilterPopupWidgetState extends State<FilterPopupWidget> {
  late int? _tempClasseId;
  late int? _tempMatiereId;
  late int? _tempTrimestre;
  String _activeTab = 'classe';

  @override
  void initState() {
    super.initState();
    _tempClasseId = widget.selectedClasseId;
    _tempMatiereId = widget.selectedMatiereId;
    _tempTrimestre = widget.selectedTrimestre;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtrer les notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Onglets
          Row(
            children: [
              _buildTab('Classe', 'classe'),
              _buildTab('Matière', 'matiere'),
              _buildTab('Trimestre', 'trimestre'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contenu
          Container(
            constraints: const BoxConstraints(maxHeight: 350),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_activeTab == 'classe')
                    ..._buildClasseList()
                  else if (_activeTab == 'matiere')
                    ..._buildMatiereList()
                  else
                    ..._buildTrimestreList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text("Réinitialiser"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tempClasseId, _tempMatiereId, _tempTrimestre);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                  ),
                  child: const Text("Appliquer"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String tab) {
    final isSelected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF47C3C) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFF47C3C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClasseList() {
    return [
      RadioListTile<int?>(
        title: const Text("Toutes les classes"),
        value: null,
        groupValue: _tempClasseId,
        onChanged: (value) => setState(() => _tempClasseId = value),
        activeColor: const Color(0xFFF47C3C),
      ),
      const Divider(),
      ...widget.classes.map((c) => RadioListTile<int?>(
        title: Text(c['nom']),
        value: c['id'],
        groupValue: _tempClasseId,
        onChanged: (value) => setState(() => _tempClasseId = value),
        activeColor: const Color(0xFFF47C3C),
      )),
    ];
  }

  List<Widget> _buildMatiereList() {
    return [
      RadioListTile<int?>(
        title: const Text("Toutes les matières"),
        value: null,
        groupValue: _tempMatiereId,
        onChanged: (value) => setState(() => _tempMatiereId = value),
        activeColor: const Color(0xFFF47C3C),
      ),
      const Divider(),
      ...widget.matieres.map((m) => RadioListTile<int?>(
        title: Text(m['nom']),
        value: m['id'],
        groupValue: _tempMatiereId,
        onChanged: (value) => setState(() => _tempMatiereId = value),
        activeColor: const Color(0xFFF47C3C),
      )),
    ];
  }

  List<Widget> _buildTrimestreList() {
    return [
      RadioListTile<int?>(
        title: const Text("Tous les trimestres"),
        value: null,
        groupValue: _tempTrimestre,
        onChanged: (value) => setState(() => _tempTrimestre = value),
        activeColor: const Color(0xFFF47C3C),
      ),
      const Divider(),
      RadioListTile<int?>(
        title: const Text("1er Trimestre"),
        value: 1,
        groupValue: _tempTrimestre,
        onChanged: (value) => setState(() => _tempTrimestre = value),
        activeColor: const Color(0xFFF47C3C),
      ),
      RadioListTile<int?>(
        title: const Text("2ème Trimestre"),
        value: 2,
        groupValue: _tempTrimestre,
        onChanged: (value) => setState(() => _tempTrimestre = value),
        activeColor: const Color(0xFFF47C3C),
      ),
      RadioListTile<int?>(
        title: const Text("3ème Trimestre"),
        value: 3,
        groupValue: _tempTrimestre,
        onChanged: (value) => setState(() => _tempTrimestre = value),
        activeColor: const Color(0xFFF47C3C),
      ),
    ];
  }
}

// Dialogue pour modifier une note
class _ModifierNoteDialog extends StatefulWidget {
  final Map<String, dynamic> note;
  const _ModifierNoteDialog({required this.note});

  @override
  __ModifierNoteDialogState createState() => __ModifierNoteDialogState();
}

class __ModifierNoteDialogState extends State<_ModifierNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noteController;
  late String _typeNote;
  late int _trimestre;

  int _toInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note['note'].toString());
    _typeNote = widget.note['type_note'];
    _trimestre = _toInt(widget.note['trimestre']);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier la note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Note actuelle: ${widget.note['note']}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nouvelle note (0-20)', border: OutlineInputBorder()),
              validator: (v) {
                final note = double.tryParse(v ?? '');
                if (note == null || note < 0 || note > 20) return 'Note invalide (0-20)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _typeNote,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'interrogation', child: Text('Interrogation')),
                DropdownMenuItem(value: 'devoir', child: Text('Devoir')),
              ],
              onChanged: (value) => setState(() => _typeNote = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _trimestre,
              decoration: const InputDecoration(labelText: 'Trimestre', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1er Trimestre')),
                DropdownMenuItem(value: 2, child: Text('2ème Trimestre')),
                DropdownMenuItem(value: 3, child: Text('3ème Trimestre')),
              ],
              onChanged: (value) => setState(() => _trimestre = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'note': double.parse(_noteController.text),
                'type_note': _typeNote,
                'trimestre': _trimestre,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: const Text('MODIFIER'),
        ),
      ],
    );
  }
}