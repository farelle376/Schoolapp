// lib/screens/gestion_notes_page.dart

import 'package:flutter/material.dart';
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
  bool _showFilterPopup = false; // Pour contrôler l'affichage du popup
  String _activeFilterType = 'classe'; // 'classe', 'matiere', 'trimestre'
  
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
    
    final classesResponse = await NoteService.getClasses();
    if (classesResponse['success'] == true) {
      setState(() {
        _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
      });
    }
    
    final matieresResponse = await NoteService.getMatieres();
    if (matieresResponse['success'] == true) {
      setState(() {
        _matieres = List<Map<String, dynamic>>.from(matieresResponse['data']);
      });
    }
    
    await _loadNotes();
    await _loadStats();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotes() async {
    final response = await NoteService.getNotes(
      classeId: _selectedClasseId,
      matiereId: _selectedMatiereId,
      trimestre: _selectedTrimestre,
    );
    
    if (response['success'] == true && response['data'] != null) {
      final notes = List<Map<String, dynamic>>.from(response['data']);
      
      if (notes.isEmpty) {
        setState(() {
          _groupedNotes = [];
          _filteredGroupedNotes = [];
        });
        return;
      }
      
      final Map<String, Map<String, dynamic>> grouped = {};
      
      for (var note in notes) {
        final trimestreValue = _toInt(note['trimestre']);
        final key = '${note['eleve_id']}_${note['matiere_id']}_$trimestreValue';
        
        if (!grouped.containsKey(key)) {
          grouped[key] = {
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
        }
        
        final currentGroup = grouped[key]!;
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
        
        double total = 0;
        int count = 0;
        for (var interro in currentGroup['interrogations'] as List) {
          total += interro['note'];
          count++;
        }
        for (var devoir in currentGroup['devoirs'] as List) {
          total += devoir['note'];
          count++;
        }
        currentGroup['moyenne'] = count > 0 ? total / count : 0;
      }
      
      setState(() {
        _groupedNotes = grouped.values.toList();
        _filteredGroupedNotes = _groupedNotes;
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

  Widget _buildRadioList<T>({
    required String title,
    required T value,
    required T? groupValue,
    required Function(T?) onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFFF47C3C),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
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
      body: Stack(
        children: [
          // Contenu principal
          Column(
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
              // Bouton filtre à gauche
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Bouton filtre à gauche
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFilterPopup = !_showFilterPopup;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _showFilterPopup 
                              ? const Color(0xFFF47C3C) 
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF47C3C).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: _showFilterPopup ? Colors.white : const Color(0xFFF47C3C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filtrer',
                              style: TextStyle(
                                fontSize: 13,
                                color: _showFilterPopup ? Colors.white : const Color(0xFFF47C3C),
                              ),
                            ),
                            Icon(
                              _showFilterPopup ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              size: 18,
                              color: _showFilterPopup ? Colors.white : const Color(0xFFF47C3C),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Affichage du filtre actif (optionnel)
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
                              onTap: () {
                                _resetFilters();
                              },
                              child: const Icon(Icons.close, size: 14, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
          // Popup de filtre (superposé)
          if (_showFilterPopup)
            Positioned(
              top: 110,
              left: 16,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 280,
                  constraints: const BoxConstraints(maxHeight: 450),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // En-tête avec onglets
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C3C).withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeFilterType = 'classe';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _activeFilterType == 'classe' 
                                        ? const Color(0xFFF47C3C) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Classe',
                                      style: TextStyle(
                                        color: _activeFilterType == 'classe' 
                                            ? Colors.white 
                                            : const Color(0xFFF47C3C),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeFilterType = 'matiere';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _activeFilterType == 'matiere' 
                                        ? const Color(0xFFF47C3C) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Matière',
                                      style: TextStyle(
                                        color: _activeFilterType == 'matiere' 
                                            ? Colors.white 
                                            : const Color(0xFFF47C3C),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeFilterType = 'trimestre';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _activeFilterType == 'trimestre' 
                                        ? const Color(0xFFF47C3C) 
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Trimestre',
                                      style: TextStyle(
                                        color: _activeFilterType == 'trimestre' 
                                            ? Colors.white 
                                            : const Color(0xFFF47C3C),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Contenu
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              if (_activeFilterType == 'classe') ...[
                                _buildRadioList<int?>(
                                  title: 'Toutes les classes',
                                  value: null,
                                  groupValue: _selectedClasseId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClasseId = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                                const Divider(),
                                ..._classes.map((classe) => _buildRadioList<int?>(
                                  title: classe['nom'],
                                  value: classe['id'],
                                  groupValue: _selectedClasseId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedClasseId = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                )),
                              ] else if (_activeFilterType == 'matiere') ...[
                                _buildRadioList<int?>(
                                  title: 'Toutes les matières',
                                  value: null,
                                  groupValue: _selectedMatiereId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMatiereId = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                                const Divider(),
                                ..._matieres.map((matiere) => _buildRadioList<int?>(
                                  title: matiere['nom'],
                                  value: matiere['id'],
                                  groupValue: _selectedMatiereId,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMatiereId = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                )),
                              ] else if (_activeFilterType == 'trimestre') ...[
                                _buildRadioList<int?>(
                                  title: 'Tous les trimestres',
                                  value: null,
                                  groupValue: _selectedTrimestre,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTrimestre = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                                const Divider(),
                                _buildRadioList<int?>(
                                  title: '1er Trimestre',
                                  value: 1,
                                  groupValue: _selectedTrimestre,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTrimestre = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                                _buildRadioList<int?>(
                                  title: '2ème Trimestre',
                                  value: 2,
                                  groupValue: _selectedTrimestre,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTrimestre = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                                _buildRadioList<int?>(
                                  title: '3ème Trimestre',
                                  value: 3,
                                  groupValue: _selectedTrimestre,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTrimestre = value;
                                      _applyFilters();
                                      _showFilterPopup = false;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  _resetFilters();
                                  _showFilterPopup = false;
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Réinitialiser tous les filtres'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
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
            ),
        ],
      ),
    );
  }
}

// Dialogue pour modifier une note (inchangé)
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