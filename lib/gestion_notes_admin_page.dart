// lib/screens/gestion_notes_admin_page.dart

import 'package:flutter/material.dart';
import '../services/note_admin_service.dart';
import '../services/annee_scolaire_service.dart';
import '../services/eleve_service.dart';
import '../model/annee_scolaire_model.dart';

class GestionNotesAdminPage extends StatefulWidget {
  @override
  _GestionNotesAdminPageState createState() => _GestionNotesAdminPageState();
}

class _GestionNotesAdminPageState extends State<GestionNotesAdminPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Services
  final NoteAdminService _noteService = NoteAdminService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();
  final EleveService _eleveService = EleveService();

  // Données
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _matieres = [];
  List<AnneeScolaire> _anneesScolaires = [];
  // Liste des élèves de la classe sélectionnée (pour compléter la liste
  // avec des tirets quand un élève n'a aucune note correspondant aux
  // filtres actuels).
  List<Map<String, dynamic>> _classeRoster = [];
  int? _selectedAnneeId;
  bool _isLoading = true;

  // Filtres
  int? _selectedClasseId;
  int? _selectedMatiereId;
  int? _selectedTrimestre;
  bool _showFilters = false;

  // Recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _trimestreOptions = [
    {'id': null, 'nom': 'Tous trimestres'},
    {'id': 1, 'nom': '1er Trimestre'},
    {'id': 2, 'nom': '2ème Trimestre'},
    {'id': 3, 'nom': '3ème Trimestre'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyLocalFilters();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Charger les années
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

    // Charger les classes et matières
    final results = await Future.wait([
      _noteService.getClasses(),
      _noteService.getMatieres(),
    ]);

    if (results[0]['success'] == true) {
      _classes = List<Map<String, dynamic>>.from(results[0]['data']);
      _classes.insert(0, {'id': null, 'nom': 'Toutes classes'});
    }

    if (results[1]['success'] == true) {
      _matieres = List<Map<String, dynamic>>.from(results[1]['data']);
      _matieres.insert(0, {'id': null, 'nom': 'Toutes matières'});
    }

    await _loadAllNotes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllNotes() async {
    // Appel avec filtre année
    final response = await _noteService.getNotes(
      classeId: _selectedClasseId,
      matiereId: _selectedMatiereId,
      trimestre: _selectedTrimestre,
      anneeScolaireId: _selectedAnneeId,
    );

    // Charge la liste des élèves de la classe sélectionnée pour pouvoir
    // compléter le tableau (élèves sans note -> tirets).
    await _loadClasseRoster();

    // Même si la récupération des notes échoue (ex: 404/erreur réseau
    // temporaire), on affiche quand même la liste des élèves de la classe
    // sélectionnée (avec des tirets), au lieu de laisser le tableau vide.
    if (response['success'] == true) {
      _allNotes = List<Map<String, dynamic>>.from(response['data']);
    } else {
      _allNotes = [];
    }
    _applyLocalFilters();
  }

  /// Récupère les élèves de la classe (et année) sélectionnées.
  Future<void> _loadClasseRoster() async {
    if (_selectedClasseId == null || _selectedAnneeId == null) {
      _classeRoster = [];
      return;
    }
    try {
      final response = await _eleveService.getElevesByClasse(
        _selectedClasseId!,
        anneeScolaireId: _selectedAnneeId!,
      );
      if (response['success'] == true) {
        _classeRoster = List<Map<String, dynamic>>.from(response['data']);
      } else {
        _classeRoster = [];
      }
    } catch (e) {
      _classeRoster = [];
    }
  }

  double _calculateMoyenne(List<dynamic> interrogations, List<dynamic> devoirs) {
    double moyenneInterrogations = 0;
    int nbInterrogations = interrogations.length;
    if (nbInterrogations > 0) {
      double sumInterro = 0;
      for (var note in interrogations) {
        sumInterro += _getNoteValue(note);
      }
      moyenneInterrogations = sumInterro / nbInterrogations;
    }

    List<double> notesDevoirs = [];
    for (var note in devoirs) {
      notesDevoirs.add(_getNoteValue(note));
    }

    List<double> notesPourMoyenne = [];
    if (nbInterrogations > 0) {
      notesPourMoyenne.add(moyenneInterrogations);
    }
    notesPourMoyenne.addAll(notesDevoirs);

    if (notesPourMoyenne.isEmpty) return 0;

    double sum = 0;
    for (var note in notesPourMoyenne) {
      sum += note;
    }
    return sum / notesPourMoyenne.length;
  }

  double _getNoteValue(dynamic note) {
    if (note['note'] is String) {
      return double.tryParse(note['note']) ?? 0;
    } else if (note['note'] is num) {
      return (note['note'] as num).toDouble();
    }
    return 0;
  }

  void _applyLocalFilters() {
    final filtered = _allNotes.where((note) {
      if (_selectedClasseId != null && note['classe_id'] != _selectedClasseId) return false;
      if (_selectedMatiereId != null && note['matiere_id'] != _selectedMatiereId) return false;
      // ⚠️ note['trimestre'] vient du backend sous forme de String (colonne
      // enum '1'/'2'/'3'), alors que _selectedTrimestre est un int (1/2/3)
      // choisi dans le filtre. En Dart, `"1" != 1` est TOUJOURS vrai (types
      // différents), donc ce filtre rejetait systématiquement TOUTES les
      // notes dès qu'un trimestre était sélectionné — même si le serveur
      // avait déjà correctement renvoyé les bonnes notes pour ce trimestre.
      if (_selectedTrimestre != null &&
          note['trimestre']?.toString() != _selectedTrimestre.toString()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final eleveNom = note['eleve_nom']?.toLowerCase() ?? '';
        final matiereNom = note['matiere_nom']?.toLowerCase() ?? '';
        final classeNom = note['classe_nom']?.toLowerCase() ?? '';
        if (!eleveNom.contains(_searchQuery) &&
            !matiereNom.contains(_searchQuery) &&
            !classeNom.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Une classe est sélectionnée : compléter la liste avec les élèves de
    // cette classe qui n'ont aucune note correspondant aux filtres actuels
    // (matière/trimestre éventuellement sélectionnés), pour qu'ils
    // apparaissent quand même dans le tableau, avec des tirets.
    if (_selectedClasseId != null && _classeRoster.isNotEmpty) {
      final eleveIdsAvecNotes = filtered.map((n) => n['eleve_id']).toSet();
      final classeNom = _getClasseNom();

      for (final eleve in _classeRoster) {
        if (eleveIdsAvecNotes.contains(eleve['id'])) continue;

        final eleveNom = (eleve['full_name'] ??
                '${eleve['prenom'] ?? ''} ${eleve['nom'] ?? ''}'.trim())
            .toString();

        if (_searchQuery.isNotEmpty && !eleveNom.toLowerCase().contains(_searchQuery)) {
          continue;
        }

        filtered.add({
          'inscription_id': eleve['inscription_id'],
          'eleve_id': eleve['id'],
          'eleve_nom': eleveNom.isEmpty ? 'Inconnu' : eleveNom,
          'classe_id': eleve['classe_id'],
          'classe_nom': classeNom,
          'annee_scolaire_id': eleve['annee_scolaire_id'],
          'matiere_id': null,
          'matiere_nom': null,
          'professeur_nom': null,
          'trimestre': null,
          'interrogations': [],
          'devoirs': [],
          'moyenne': 0,
        });
      }

      filtered.sort((a, b) =>
          (a['eleve_nom'] ?? '').toString().compareTo((b['eleve_nom'] ?? '').toString()));
    }

    setState(() {
      _filteredNotes = filtered;
    });
  }

  void _onFilterChanged() {
    _loadAllNotes();
  }

  String _getClasseNom() {
    if (_selectedClasseId == null) return 'Toutes classes';
    final classe = _classes.firstWhere((c) => c['id'] == _selectedClasseId,
        orElse: () => {'nom': 'Toutes classes'});
    return classe['nom'];
  }

  String _getMatiereNom() {
    if (_selectedMatiereId == null) return 'Toutes matières';
    final matiere = _matieres.firstWhere((m) => m['id'] == _selectedMatiereId,
        orElse: () => {'nom': 'Toutes matières'});
    return matiere['nom'];
  }

  String _getTrimestreNom() {
    if (_selectedTrimestre == null) return 'Tous trimestres';
    final trimestre = _trimestreOptions.firstWhere((t) => t['id'] == _selectedTrimestre);
    return trimestre['nom'];
  }

  String _getAnneeLibelle() {
    if (_selectedAnneeId == null) return 'Toutes années';
    final annee = _anneesScolaires.firstWhere((a) => a.id == _selectedAnneeId,
        orElse: () => AnneeScolaire(id: 0, libelle: 'Année inconnue', dateDebut: '', dateFin: ''));
    return annee.libelle ?? 'Année ${annee.id}';
  }

  void _showManageNotesDialog(Map<String, dynamic> noteGroup) {
    showDialog(
      context: context,
      builder: (context) => _ManageNotesDialog(
        noteGroup: noteGroup,
        onNoteUpdated: () {
          _loadAllNotes();
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Color _getNoteColor(double note) {
    if (note >= 16) return Colors.green;
    if (note >= 14) return Colors.lightGreen;
    if (note >= 12) return Colors.orange;
    if (note >= 10) return Colors.amber;
    return Colors.red;
  }

  String _getTrimestreText(dynamic trimestre) {
    switch (trimestre) {
      case null:
        return '-';
      case 1:
        return '1er';
      case 2:
        return '2ème';
      case 3:
        return '3ème';
      default:
        return 'T$trimestre';
    }
  }

  void _showFilterDialog(String filterType) {
    List<Map<String, dynamic>> items = [];
    String title = '';
    int? currentValue;

    if (filterType == 'classe') {
      items = _classes;
      title = 'Sélectionner une classe';
      currentValue = _selectedClasseId;
    } else if (filterType == 'matiere') {
      items = _matieres;
      title = 'Sélectionner une matière';
      currentValue = _selectedMatiereId;
    } else {
      items = _trimestreOptions;
      title = 'Sélectionner un trimestre';
      currentValue = _selectedTrimestre;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              title: Text(title, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
              content: Container(
                width: 280,
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView(
                  shrinkWrap: true,
                  children: items.map((item) {
                    final isSelected = currentValue == item['id'];
                    return ListTile(
                      title: Text(item['nom'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFF47C3C).withOpacity(0.1),
                      onTap: () {
                        if (filterType == 'classe') {
                          _selectedClasseId = item['id'];
                        } else if (filterType == 'matiere') {
                          _selectedMatiereId = item['id'];
                        } else {
                          _selectedTrimestre = item['id'];
                        }
                        Navigator.pop(context);
                        _onFilterChanged();
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des notes'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllNotes, tooltip: 'Actualiser'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // SÉLECTEUR D'ANNÉE
                if (_anneesScolaires.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                    child: Row(
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
                              });
                              await _loadAllNotes();
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
                    controller: _searchController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par élève, matière ou classe...',
                      hintStyle:
                          TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18,
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder:
                          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF47C3C), width: 1),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PANEL DES FILTRES
                      Container(
                        width: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showFilters = !_showFilters),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showFilters
                                      ? const Color(0xFFF47C3C)
                                      : (isDarkMode ? Colors.grey.shade800 : Colors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFF47C3C).withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.filter_list, size: 16,
                                        color: _showFilters ? Colors.white : const Color(0xFFF47C3C)),
                                    const SizedBox(width: 4),
                                    Text('Filtrer',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _showFilters ? Colors.white : const Color(0xFFF47C3C))),
                                    Icon(_showFilters ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        size: 16,
                                        color: _showFilters ? Colors.white : const Color(0xFFF47C3C)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_showFilters) ...[
                              _buildFilterChip(
                                  label: _getClasseNom(),
                                  onTap: () => _showFilterDialog('classe'),
                                  isActive: _selectedClasseId != null,
                                  isDarkMode: isDarkMode),
                              const SizedBox(height: 8),
                              _buildFilterChip(
                                  label: _getMatiereNom(),
                                  onTap: () => _showFilterDialog('matiere'),
                                  isActive: _selectedMatiereId != null,
                                  isDarkMode: isDarkMode),
                              const SizedBox(height: 8),
                              _buildFilterChip(
                                  label: _getTrimestreNom(),
                                  onTap: () => _showFilterDialog('trimestre'),
                                  isActive: _selectedTrimestre != null,
                                  isDarkMode: isDarkMode),
                            ],
                          ],
                        ),
                      ),
                      // DATATABLE
                      // Toujours afficher le tableau (avec ses en-têtes),
                      // même sans aucune note : seul le contenu des lignes
                      // change. Un message s'affiche sous l'en-tête quand
                      // la liste est vide, au lieu de masquer tout le
                      // tableau.
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DataTable(
                                    columnSpacing: 12,
                                    headingRowColor: MaterialStateProperty.all(
                                        isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1)),
                                    headingTextStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: isDarkMode ? Colors.white : Colors.black87),
                                    dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) =>
                                        isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : null),
                                    dividerThickness: 0,
                                    columns: const [
                                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Élève', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Prof.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Trim.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Interro.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Devoirs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Moy.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
                                    ],
                                    rows: _filteredNotes.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      final interrogations = item['interrogations'] as List? ?? [];
                                      final devoirs = item['devoirs'] as List? ?? [];
                                      final hasNotes = interrogations.isNotEmpty || devoirs.isNotEmpty;
                                      final moyenne = _calculateMoyenne(interrogations, devoirs);

                                      return DataRow(
                                        color: MaterialStateProperty.resolveWith<Color?>((states) {
                                          if (index % 2 == 0)
                                            return isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
                                          return null;
                                        }),
                                        cells: [
                                          DataCell(Text('${index + 1}',
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          DataCell(Text(item['eleve_nom'] ?? '-',
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          DataCell(Text(item['classe_nom'] ?? '-',
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          DataCell(Text(item['matiere_nom'] ?? '-',
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          DataCell(Text(item['professeur_nom'] ?? '-',
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          DataCell(Text(_getTrimestreText(item['trimestre']),
                                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11))),
                                          // Interrogations
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: interrogations.isEmpty
                                                      ? [
                                                          Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                  color: isDarkMode
                                                                      ? Colors.grey.shade800
                                                                      : Colors.grey.shade200,
                                                                  borderRadius: BorderRadius.circular(5)),
                                                              child: Text('-',
                                                                  style: TextStyle(
                                                                      fontSize: 9,
                                                                      color: isDarkMode
                                                                          ? Colors.grey.shade500
                                                                          : Colors.grey)))
                                                        ]
                                                      : interrogations.map<Widget>((note) {
                                                          return Container(
                                                            margin: const EdgeInsets.only(right: 2),
                                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFF47C3C).withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(5),
                                                              border: Border.all(
                                                                  color: const Color(0xFFF47C3C).withOpacity(0.3),
                                                                  width: 0.5),
                                                            ),
                                                            child: Text(_getNoteValue(note).toString(),
                                                                style: const TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Color(0xFFF47C3C))),
                                                          );
                                                        }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Devoirs
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: devoirs.isEmpty
                                                      ? [
                                                          Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                  color: isDarkMode
                                                                      ? Colors.grey.shade800
                                                                      : Colors.grey.shade200,
                                                                  borderRadius: BorderRadius.circular(5)),
                                                              child: Text('-',
                                                                  style: TextStyle(
                                                                      fontSize: 9,
                                                                      color: isDarkMode
                                                                          ? Colors.grey.shade500
                                                                          : Colors.grey)))
                                                        ]
                                                      : devoirs.map<Widget>((note) {
                                                          return Container(
                                                            margin: const EdgeInsets.only(right: 2),
                                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(5),
                                                              border: Border.all(
                                                                  color: Colors.green.withOpacity(0.3),
                                                                  width: 0.5),
                                                            ),
                                                            child: Text(_getNoteValue(note).toString(),
                                                                style: const TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.green)),
                                                          );
                                                        }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Moyenne
                                          DataCell(
                                            hasNotes
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                        color: _getNoteColor(moyenne).withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(8)),
                                                    child: Text(moyenne.toStringAsFixed(2),
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: _getNoteColor(moyenne))),
                                                  )
                                                : Text('-',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey)),
                                          ),
                                          // Actions
                                          DataCell(
                                            hasNotes
                                                ? IconButton(
                                                    icon: const Icon(Icons.edit, color: Color(0xFFF47C3C), size: 18),
                                                    onPressed: () => _showManageNotesDialog(item),
                                                    tooltip: 'Modifier les notes',
                                                  )
                                                : Text('-',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey)),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                ),
                                if (_filteredNotes.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Text('Aucune note trouvée',
                                        style: TextStyle(
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFF47C3C).withOpacity(0.1)
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive
                  ? const Color(0xFFF47C3C)
                  : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt, size: 14,
                color: isActive
                    ? const Color(0xFFF47C3C)
                    : (isDarkMode ? Colors.grey.shade500 : Colors.grey)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? const Color(0xFFF47C3C)
                        : (isDarkMode ? Colors.white : Colors.black87))),
          ],
        ),
      ),
    );
  }
}

// ==================== DIALOGUE DE GESTION DES NOTES ====================

class _ManageNotesDialog extends StatefulWidget {
  final Map<String, dynamic> noteGroup;
  final VoidCallback onNoteUpdated;
  const _ManageNotesDialog({Key? key, required this.noteGroup, required this.onNoteUpdated})
      : super(key: key);

  @override
  State<_ManageNotesDialog> createState() => _ManageNotesDialogState();
}

class _ManageNotesDialogState extends State<_ManageNotesDialog> {
  List<Map<String, dynamic>> _interrogations = [];
  List<Map<String, dynamic>> _devoirs = [];

  @override
  void initState() {
    super.initState();
    _interrogations = List<Map<String, dynamic>>.from(widget.noteGroup['interrogations'] ?? []);
    _devoirs = List<Map<String, dynamic>>.from(widget.noteGroup['devoirs'] ?? []);
  }

  double _getNoteValue(dynamic note) {
    if (note['note'] is String) return double.tryParse(note['note']) ?? 0;
    else if (note['note'] is num) return (note['note'] as num).toDouble();
    return 0;
  }

  Future<void> _modifierNote(Map<String, dynamic> note) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (context) => _ModifierNoteDialog(note: note));
    if (result != null) {
      final response = await NoteAdminService.updateNoteStatic(note['id'], result);
      if (response['success'] == true) {
        _showSnackBar('Note modifiée avec succès', Colors.green);
        widget.onNoteUpdated();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _supprimerNote(Map<String, dynamic> note) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text('Confirmation', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        content: Text('Voulez-vous vraiment supprimer cette note (${_getNoteValue(note)}/20) ?',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final response = await NoteAdminService.deleteNoteStatic(note['id']);
      if (response['success'] == true) {
        _showSnackBar('Note supprimée avec succès', Colors.green);
        widget.onNoteUpdated();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Color _getNoteColor(double note) {
    if (note >= 16) return Colors.green;
    if (note >= 14) return Colors.lightGreen;
    if (note >= 12) return Colors.orange;
    if (note >= 10) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final eleveNom = widget.noteGroup['eleve_nom'] ?? 'Élève';
    final matiereNom = widget.noteGroup['matiere_nom'] ?? 'Matière';
    final trimestre = widget.noteGroup['trimestre'] ?? 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestion des notes',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                      const SizedBox(height: 4),
                      Text('$eleveNom - $matiereNom',
                          style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey.shade400 : Colors.grey)),
                      Text('Trimestre $trimestre', style: const TextStyle(fontSize: 12, color: Color(0xFFF47C3C))),
                    ],
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_interrogations.isNotEmpty) ...[
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Container(width: 4, height: 20, color: Colors.blue, margin: const EdgeInsets.only(right: 8)),
                            Text('INTERROGATIONS',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue))
                          ])),
                      ..._interrogations.map((note) => _buildNoteCard(note)),
                      const SizedBox(height: 16),
                    ],
                    if (_devoirs.isNotEmpty) ...[
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Container(width: 4, height: 20, color: Colors.orange, margin: const EdgeInsets.only(right: 8)),
                            Text('DEVOIRS',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange))
                          ])),
                      ..._devoirs.map((note) => _buildNoteCard(note)),
                      const SizedBox(height: 16),
                    ],
                    if (_interrogations.isEmpty && _devoirs.isEmpty)
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text('Aucune note pour ce trimestre',
                                  style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('FERMER', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final noteValue = _getNoteValue(note);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: _getNoteColor(noteValue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getNoteColor(noteValue).withOpacity(0.3))),
            child: Center(
                child: Text(noteValue.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: _getNoteColor(noteValue)))),
          ),
          const SizedBox(width: 16),
          const Expanded(child: SizedBox()),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _modifierNote(note),
                  tooltip: 'Modifier'),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _supprimerNote(note),
                  tooltip: 'Supprimer'),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== DIALOGUE DE MODIFICATION D'UNE NOTE ====================

class _ModifierNoteDialog extends StatefulWidget {
  final Map<String, dynamic> note;
  const _ModifierNoteDialog({required this.note});

  @override
  State<_ModifierNoteDialog> createState() => __ModifierNoteDialogState();
}

class __ModifierNoteDialogState extends State<_ModifierNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _noteController;
  late String _typeNote;
  late int _trimestre;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.note['note'].toString());
    _typeNote = widget.note['type_note'] ?? 'interrogation';
    _trimestre = widget.note['trimestre'] ?? 1;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double _getCurrentNoteValue() {
    if (widget.note['note'] is String) return double.tryParse(widget.note['note']) ?? 0;
    else if (widget.note['note'] is num) return (widget.note['note'] as num).toDouble();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      title: Text('Modifier la note', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Note actuelle: ${_getCurrentNoteValue().toStringAsFixed(2)}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Nouvelle note (0-20)',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF47C3C))),
              ),
              validator: (v) {
                final note = double.tryParse(v ?? '');
                if (note == null || note < 0 || note > 20) return 'Note invalide (0-20)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _typeNote,
              dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF47C3C))),
              ),
              items: const [
                DropdownMenuItem(value: 'interrogation', child: Text('Interrogation')),
                DropdownMenuItem(value: 'devoir', child: Text('Devoir')),
              ],
              onChanged: (value) => setState(() => _typeNote = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _trimestre,
              dropdownColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Trimestre',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF47C3C))),
              ),
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