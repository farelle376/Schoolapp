// lib/screens/gestemploi.dart

import 'package:flutter/material.dart';
import '../services/admin_emploi_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/emploi_du_temps_admin_model.dart';
import '../model/annee_scolaire_model.dart';

class GestEmploiPage extends StatefulWidget {
  @override
  _GestEmploiPageState createState() => _GestEmploiPageState();
}

class _GestEmploiPageState extends State<GestEmploiPage> {
  final AdminEmploiService _emploiService = AdminEmploiService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  List<EmploiDuTempsAdminModel> _allEmplois = [];
  List<EmploiDuTempsAdminModel> _coursList = [];
  List<EmploiDuTempsAdminModel> _tdList = [];
  List<EmploiDuTempsAdminModel> _evaluationList = [];

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _professeurs = [];
  List<AnneeScolaire> _anneesScolaires = [];

  bool _isLoading = true;
  String? _error;
  int? _selectedClasseId;
  int? _selectedAnneeId;
  int _selectedTab = 0;

  bool _isPanelOpen = false;
  EmploiDuTempsAdminModel? _editingEmploi;

  // ==================== AJOUT MULTIPLE D'EMPLOI DE Temps ====================
  // Quand on ajoute (pas quand on modifie), l'utilisateur choisit une classe
  // et un nombre de séances, puis remplit chaque séance en une seule fois.
  int? _batchClasseId;
  int _nombreSeances = 1;
  List<Map<String, dynamic>> _seances = [];

  Map<String, dynamic> _newSeance() => {
        'matiereId': null,
        'professeurId': null,
        'jour': 'lundi',
        'heureDebut': '08:00',
        'heureFin': '10:00',
        'typeCours': 'cours',
      };

  // Un professeur n'enseigne qu'une seule matière (colonne matiere_id sur
  // `professeurs`) : on ne propose donc que les professeurs de la matière
  // sélectionnée.
  List<Map<String, dynamic>> _professeursForMatiere(int? matiereId) {
    if (matiereId == null) return _professeurs;
    return _professeurs.where((p) => p['matiere_id'] == matiereId).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Charger les années
      final annees = await _anneeService.getAnneesScolaires();
      if (!mounted) return;
      setState(() {
        _anneesScolaires = annees;
      });

      // 2. Déterminer l'année par défaut (en cours ou première)
      final anneeEnCours = await _anneeService.getAnneeEnCours();
      if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
        _selectedAnneeId = anneeEnCours.id;
      } else if (annees.isNotEmpty) {
        _selectedAnneeId = annees.first.id;
      }

      // 3. Charger les autres données
      await _chargerEmplois();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _chargerEmplois() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ✅ Utiliser les nouvelles méthodes qui retournent des List directement
      final emploisFuture = _emploiService.getEmploisList(anneeScolaireId: _selectedAnneeId);
      final classesFuture = _emploiService.getClassesForEmploi();
      final matieresFuture = _emploiService.getMatieresForEmploi();
      final professeursFuture = _emploiService.getProfesseursForEmploi();

      final results = await Future.wait([
        emploisFuture,
        classesFuture,
        matieresFuture,
        professeursFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _allEmplois = results[0] as List<EmploiDuTempsAdminModel>;
        _classes = results[1] as List<Map<String, dynamic>>;
        _matieres = results[2] as List<Map<String, dynamic>>;
        _professeurs = results[3] as List<Map<String, dynamic>>;
        _filterByType();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ==================== FILTRES ====================

  void _filterByType() {
    if (!mounted) return;

    List<EmploiDuTempsAdminModel> source = _allEmplois
        .where((e) =>
            (_selectedClasseId == null || e.classeId == _selectedClasseId) &&
            (_selectedAnneeId == null || e.anneeScolaireId == _selectedAnneeId))
        .toList();

    setState(() {
      _coursList = source.where((e) => e.typeCours == 'cours').toList();
      _tdList = source.where((e) => e.typeCours == 'td' || e.typeCours == 'tp').toList();
      _evaluationList = source.where((e) => e.typeCours == 'evaluation').toList();
    });
  }

  void _filterByClasse(int? classeId) {
    if (!mounted) return;
    setState(() {
      _selectedClasseId = classeId;
      _filterByType();
    });
  }

  void _filterByAnnee(int? anneeId) async {
    if (!mounted) return;
    setState(() {
      _selectedAnneeId = anneeId;
      _isLoading = true;
    });

    try {
      // ✅ Utiliser getEmploisList
      final emplois = await _emploiService.getEmploisList(anneeScolaireId: anneeId);
      if (!mounted) return;
      setState(() {
        _allEmplois = emplois;
        _filterByType();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ==================== PANEL D'AJOUT / MODIFICATION ====================

  void _openAddPanel() {
    if (_selectedAnneeId == null) {
      _showSnackBar('Veuillez sélectionner une année scolaire');
      return;
    }
    if (_classes.isEmpty || _matieres.isEmpty || _professeurs.isEmpty) {
      _showSnackBar('Les données de référence sont en cours de chargement...', isError: false);
      return;
    }
    setState(() {
      _editingEmploi = null;
      _batchClasseId = _selectedClasseId;
      _nombreSeances = 1;
      _seances = [_newSeance()];
      _isPanelOpen = true;
    });
  }

  void _setNombreSeances(int n) {
    if (n < 1) n = 1;
    if (n > 12) n = 12;
    setState(() {
      _nombreSeances = n;
      if (_seances.length < n) {
        _seances.addAll(List.generate(n - _seances.length, (_) => _newSeance()));
      } else if (_seances.length > n) {
        _seances = _seances.sublist(0, n);
      }
    });
  }

  Future<void> _submitBatch() async {
    if (_batchClasseId == null) {
      _showSnackBar('Veuillez sélectionner une classe');
      return;
    }
    if (_selectedAnneeId == null) {
      _showSnackBar('Veuillez sélectionner une année scolaire');
      return;
    }
    for (int i = 0; i < _seances.length; i++) {
      final s = _seances[i];
      if (s['matiereId'] == null || s['professeurId'] == null) {
        _showSnackBar('Veuillez compléter la séance ${i + 1}');
        return;
      }
    }

    _closePanel();
    setState(() => _isLoading = true);

    int successCount = 0;
    int failCount = 0;
    for (final s in _seances) {
      final data = {
        'classe_id': _batchClasseId,
        'matiere_id': s['matiereId'],
        'professeur_id': s['professeurId'],
        'jour': s['jour'],
        'heure_debut': s['heureDebut'],
        'heure_fin': s['heureFin'],
        'type_cours': s['typeCours'],
        'annee_scolaire_id': _selectedAnneeId!,
        'est_active': true,
      };
      final ok = await _emploiService.createEmploi(data);
      if (ok) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;
    await _chargerEmplois();
    if (failCount == 0) {
      _showSnackBar(
        successCount > 1 ? '$successCount séances ajoutées' : 'Séance ajoutée',
        isError: false,
      );
    } else {
      _showSnackBar('$successCount ajoutée(s), $failCount échec(s)');
    }
  }

  void _openEditPanel(EmploiDuTempsAdminModel emploi) {
    setState(() {
      _editingEmploi = emploi;
      _isPanelOpen = true;
    });
  }

  void _closePanel() {
    setState(() {
      _isPanelOpen = false;
      _editingEmploi = null;
    });
  }

  // ==================== CRUD ====================

  Future<void> _deleteEmploi(EmploiDuTempsAdminModel emploi) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          'Confirmation',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Supprimer le cours de ${emploi.matiereNom} du ${emploi.jourLabel} ?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
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

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      final success = await _emploiService.deleteEmploi(emploi.id);
      if (!mounted) return;
      if (success) {
        await _chargerEmplois();
        _showSnackBar('Cours supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== GÉNÉRATION D'HEURES (dropdown) ====================

  List<DropdownMenuItem<String>> _generateHours() {
    List<DropdownMenuItem<String>> hours = [];
    for (int i = 7; i <= 18; i++) {
      String hour = i.toString().padLeft(2, '0');
      hours.add(DropdownMenuItem(value: '$hour:00', child: Text('$hour:00')));
      hours.add(DropdownMenuItem(value: '$hour:30', child: Text('$hour:30')));
    }
    return hours;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Emplois du temps', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : Column(
                      children: [
                        // SÉLECTEUR D'ANNÉE
                        _buildAnneeSelector(),
                        // FILTRES (classes)
                        _buildFilters(),
                        // TABS
                        _buildTabs(),
                        // LISTE DES COURS
                        Expanded(
                          child: _getCurrentList().isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucun cours trouvé pour cette année',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _getCurrentList().length,
                                  itemBuilder: (context, index) {
                                    final emploi = _getCurrentList()[index];
                                    return _buildEmploiCard(emploi);
                                  },
                                ),
                        ),
                      ],
                    ),
          // BOUTON D'AJOUT
          // Placé dans le Stack (et non via Scaffold.floatingActionButton,
          // qui est toujours affiché par-dessus le body) pour qu'il passe
          // derrière le panneau latéral une fois celui-ci ouvert.
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_emplois',
              onPressed: _openAddPanel,
              backgroundColor: const Color(0xFFF47C3C),
              child: const Icon(Icons.add),
            ),
          ),
          // PANEL LATÉRAL
          // Plein écran sur mobile, limité à la moitié de l'écran sur
          // tablette/desktop (au lieu de 0.9 partout).
          Builder(builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final panelWidth = screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.5;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: 0,
              bottom: 0,
              right: _isPanelOpen ? 0 : -panelWidth,
              child: Container(
                width: panelWidth,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.3),
                      blurRadius: 20,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPanelHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildForm(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildAnneeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_anneesScolaires.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Aucune année scolaire disponible'),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAnneeId,
          isExpanded: true,
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
          onChanged: (value) {
            _filterByAnnee(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 45,
      margin: const EdgeInsets.all(12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Toutes les classes'),
            selected: _selectedClasseId == null,
            onSelected: (_) => _filterByClasse(null),
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey[200],
            selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
            labelStyle: TextStyle(
              color: _selectedClasseId == null ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
              fontWeight: _selectedClasseId == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          ..._classes.map((classe) {
            String nomClasse = classe['nom_complet']?.toString() ?? classe['nom']?.toString() ?? 'Classe ${classe['id']}';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(nomClasse),
                selected: _selectedClasseId == classe['id'],
                onSelected: (_) => _filterByClasse(classe['id']),
                backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey[200],
                selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _selectedClasseId == classe['id'] ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
                  fontWeight: _selectedClasseId == classe['id'] ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildTab('Cours', 0, _coursList.length),
          const SizedBox(width: 8),
          _buildTab('TD/TP', 1, _tdList.length),
          const SizedBox(width: 8),
          _buildTab('Évaluations', 2, _evaluationList.length),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, int count) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF47C3C)
                : (isDarkMode ? Colors.grey.shade800 : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF47C3C)
                  : (isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
                  ),
                ),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDarkMode ? Colors.grey.shade700 : Colors.grey[300]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<EmploiDuTempsAdminModel> _getCurrentList() {
    switch (_selectedTab) {
      case 0:
        return _coursList;
      case 1:
        return _tdList;
      case 2:
        return _evaluationList;
      default:
        return [];
    }
  }

  Widget _buildEmploiCard(EmploiDuTempsAdminModel emploi) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: InkWell(
        onTap: () => _openEditPanel(emploi),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emploi.typeCoursColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  emploi.typeCours == 'cours' ? Icons.menu_book
                      : emploi.typeCours == 'evaluation' ? Icons.assignment
                      : Icons.computer,
                  color: emploi.typeCoursColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emploi.matiereNom,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emploi.classeNom,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: 10, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            emploi.professeurNom,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      emploi.jourLabel,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${emploi.heureDebut} - ${emploi.heureFin}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: emploi.typeCoursColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emploi.typeCoursLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: emploi.typeCoursColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ==================== PANEL HEADER ====================

  Widget _buildPanelHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _editingEmploi == null ? Icons.calendar_today : Icons.edit_calendar,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingEmploi == null ? 'Ajouter des séances' : 'Modifier',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _editingEmploi == null ? 'Nouvel emploi du temps' : _editingEmploi!.matiereNom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _closePanel,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORMULAIRE ====================

  Widget _buildForm() {
    // Modification : un seul cours à la fois (comportement inchangé).
    // Ajout : sélection de la classe + du nombre de séances, puis
    // remplissage de toutes les séances en une fois.
    if (_editingEmploi != null) {
      return _buildEditForm();
    }
    return _buildMultiAddForm();
  }

  Widget _dropdownContainer({required Widget child, required bool isDarkMode}) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[200]!),
      ),
      child: child,
    );
  }

  // ---------- Formulaire de MODIFICATION (une seule séance) ----------

  Widget _buildEditForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();

    int? selectedClasseId = _editingEmploi?.classeId;
    int? selectedMatiereId = _editingEmploi?.matiereId;
    int? selectedProfesseurId = _editingEmploi?.professeurId;
    String selectedJour = _editingEmploi?.jour ?? 'lundi';
    String selectedHeureDebut = _editingEmploi?.heureDebut ?? '08:00';
    String selectedHeureFin = _editingEmploi?.heureFin ?? '10:00';
    String selectedTypeCours = _editingEmploi?.typeCours ?? 'cours';

    return StatefulBuilder(builder: (context, setLocalState) {
      final professeursDisponibles = _professeursForMatiere(selectedMatiereId);
      if (selectedProfesseurId != null &&
          !professeursDisponibles.any((p) => p['id'] == selectedProfesseurId)) {
        selectedProfesseurId = null;
      }

      return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du cours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF0D2B4E),
              ),
            ),
            const SizedBox(height: 16),

            // Classe
            _dropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Classe',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.class_, color: Color(0xFFF47C3C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                value: selectedClasseId,
                items: _classes.map<DropdownMenuItem<int>>((c) {
                  String label = c['nom_complet']?.toString() ?? '';
                  if (label.isEmpty) label = 'Classe ${c['id']}';
                  return DropdownMenuItem<int>(value: c['id'] as int, child: Text(label));
                }).toList(),
                onChanged: (value) => selectedClasseId = value,
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Matière
            _dropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Matière',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.book, color: Color(0xFFF47C3C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                value: selectedMatiereId,
                items: _matieres.map<DropdownMenuItem<int>>((m) {
                  String label = m['nom']?.toString() ?? m['libelle']?.toString() ?? 'Matière';
                  return DropdownMenuItem<int>(value: m['id'] as int, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  setLocalState(() {
                    selectedMatiereId = value;
                    // Le prof précédemment choisi peut ne plus correspondre
                    // à la nouvelle matière : on le réinitialise.
                    selectedProfesseurId = null;
                  });
                },
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 12),

            // Professeur (filtré par matière)
            _dropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Professeur',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFFF47C3C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                value: selectedProfesseurId,
                items: professeursDisponibles.map<DropdownMenuItem<int>>((p) {
                  String label = p['nom_complet']?.toString() ?? '';
                  if (label.isEmpty) {
                    label = p['prenom']?.toString() ?? '';
                    if (label.isNotEmpty) label += ' ${p['nom'] ?? ''}';
                    if (label.isEmpty) label = 'Professeur ${p['id']}';
                  }
                  return DropdownMenuItem<int>(value: p['id'] as int, child: Text(label));
                }).toList(),
                onChanged: selectedMatiereId == null
                    ? null
                    : (value) => setLocalState(() => selectedProfesseurId = value),
                validator: (v) => v == null ? 'Champ requis' : null,
                hint: selectedMatiereId == null ? const Text('Choisissez une matière d\'abord') : null,
              ),
            ),
            const SizedBox(height: 12),

            // Jour
            _dropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Jour',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFF47C3C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                value: selectedJour,
                items: const [
                  DropdownMenuItem(value: 'lundi', child: Text('Lundi')),
                  DropdownMenuItem(value: 'mardi', child: Text('Mardi')),
                  DropdownMenuItem(value: 'mercredi', child: Text('Mercredi')),
                  DropdownMenuItem(value: 'jeudi', child: Text('Jeudi')),
                  DropdownMenuItem(value: 'vendredi', child: Text('Vendredi')),
                  DropdownMenuItem(value: 'samedi', child: Text('Samedi')),
                ],
                onChanged: (value) => selectedJour = value!,
              ),
            ),
            const SizedBox(height: 12),

            // Heures
            Row(
              children: [
                Expanded(
                  child: _dropdownContainer(
                    isDarkMode: isDarkMode,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Heure début',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        prefixIcon: const Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      value: selectedHeureDebut,
                      items: _generateHours(),
                      onChanged: (value) => selectedHeureDebut = value!,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dropdownContainer(
                    isDarkMode: isDarkMode,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Heure fin',
                        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                        prefixIcon: const Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      value: selectedHeureFin,
                      items: _generateHours(),
                      onChanged: (value) => selectedHeureFin = value!,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type de cours
            _dropdownContainer(
              isDarkMode: isDarkMode,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Type de cours',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.category, color: Color(0xFFF47C3C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                value: selectedTypeCours,
                items: const [
                  DropdownMenuItem(value: 'cours', child: Text('Cours')),
                  DropdownMenuItem(value: 'td', child: Text('TD')),
                  DropdownMenuItem(value: 'tp', child: Text('TP')),
                  DropdownMenuItem(value: 'evaluation', child: Text('Évaluation')),
                ],
                onChanged: (value) => selectedTypeCours = value!,
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (_selectedAnneeId == null) {
                      _showSnackBar('Veuillez sélectionner une année scolaire');
                      return;
                    }

                    final emploiEnCours = _editingEmploi!;
                    _closePanel();
                    setState(() => _isLoading = true);

                    final Map<String, dynamic> data = {
                      'classe_id': selectedClasseId,
                      'matiere_id': selectedMatiereId,
                      'professeur_id': selectedProfesseurId,
                      'jour': selectedJour,
                      'heure_debut': selectedHeureDebut,
                      'heure_fin': selectedHeureFin,
                      'type_cours': selectedTypeCours,
                      'annee_scolaire_id': _selectedAnneeId!,
                    };

                    final success = await _emploiService.updateEmploi(emploiEnCours.id, data);

                    if (mounted) {
                      if (success) {
                        await _chargerEmplois();
                        _showSnackBar('Cours modifié', isError: false);
                      } else {
                        _showSnackBar('Erreur lors de l\'enregistrement');
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C3C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'MODIFIER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---------- Formulaire d'AJOUT (classe + N séances remplies ensemble) ----------

  Widget _buildMultiAddForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouvelles séances',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 16),

          // Classe (partagée par toutes les séances)
          _dropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Classe',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                prefixIcon: const Icon(Icons.class_, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              value: _batchClasseId,
              items: _classes.map<DropdownMenuItem<int>>((c) {
                String label = c['nom_complet']?.toString() ?? '';
                if (label.isEmpty) label = 'Classe ${c['id']}';
                return DropdownMenuItem<int>(value: c['id'] as int, child: Text(label));
              }).toList(),
              onChanged: (value) => setState(() => _batchClasseId = value),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 16),

          // Nombre de séances à ajouter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.event_repeat, color: const Color(0xFFF47C3C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nombre de séances',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFF47C3C),
                  onPressed: () => _setNombreSeances(_nombreSeances - 1),
                ),
                Text(
                  '$_nombreSeances',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFFF47C3C),
                  onPressed: () => _setNombreSeances(_nombreSeances + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Une carte de formulaire par séance
          ...List.generate(_seances.length, (i) => _buildSeanceCard(i, isDarkMode)),

          const SizedBox(height: 12),

          // Bouton Enregistrer
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _submitBatch();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text( 'AJOUTER',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeanceCard(int index, bool isDarkMode) {
    final seance = _seances[index];
    final matiereId = seance['matiereId'] as int?;
    final professeursDisponibles = _professeursForMatiere(matiereId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Séance ${index + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF47C3C),
            ),
          ),
          const SizedBox(height: 10),

          // Matière
          _dropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Matière',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                prefixIcon: const Icon(Icons.book, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              value: matiereId,
              items: _matieres.map<DropdownMenuItem<int>>((m) {
                String label = m['nom']?.toString() ?? m['libelle']?.toString() ?? 'Matière';
                return DropdownMenuItem<int>(value: m['id'] as int, child: Text(label));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _seances[index]['matiereId'] = value;
                  // Le prof précédemment choisi peut ne plus enseigner
                  // cette matière : on le réinitialise.
                  _seances[index]['professeurId'] = null;
                });
              },
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 10),

          // Professeur (filtré par matière)
          _dropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Professeur',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                prefixIcon: const Icon(Icons.person, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              value: seance['professeurId'] as int?,
              items: professeursDisponibles.map<DropdownMenuItem<int>>((p) {
                String label = p['nom_complet']?.toString() ?? '';
                if (label.isEmpty) {
                  label = p['prenom']?.toString() ?? '';
                  if (label.isNotEmpty) label += ' ${p['nom'] ?? ''}';
                  if (label.isEmpty) label = 'Professeur ${p['id']}';
                }
                return DropdownMenuItem<int>(value: p['id'] as int, child: Text(label));
              }).toList(),
              onChanged: matiereId == null
                  ? null
                  : (value) => setState(() => _seances[index]['professeurId'] = value),
              validator: (v) => v == null ? 'Champ requis' : null,
              hint: matiereId == null ? const Text('Choisissez une matière d\'abord') : null,
            ),
          ),
          const SizedBox(height: 10),

          // Jour
          _dropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Jour',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              value: seance['jour'] as String,
              items: const [
                DropdownMenuItem(value: 'lundi', child: Text('Lundi')),
                DropdownMenuItem(value: 'mardi', child: Text('Mardi')),
                DropdownMenuItem(value: 'mercredi', child: Text('Mercredi')),
                DropdownMenuItem(value: 'jeudi', child: Text('Jeudi')),
                DropdownMenuItem(value: 'vendredi', child: Text('Vendredi')),
                DropdownMenuItem(value: 'samedi', child: Text('Samedi')),
              ],
              onChanged: (value) => setState(() => _seances[index]['jour'] = value!),
            ),
          ),
          const SizedBox(height: 10),

          // Heures
          Row(
            children: [
              Expanded(
                child: _dropdownContainer(
                  isDarkMode: isDarkMode,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Heure début',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    value: seance['heureDebut'] as String,
                    items: _generateHours(),
                    onChanged: (value) => setState(() => _seances[index]['heureDebut'] = value!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdownContainer(
                  isDarkMode: isDarkMode,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Heure fin',
                      labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    value: seance['heureFin'] as String,
                    items: _generateHours(),
                    onChanged: (value) => setState(() => _seances[index]['heureFin'] = value!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Type de cours
          _dropdownContainer(
            isDarkMode: isDarkMode,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type de cours',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                prefixIcon: const Icon(Icons.category, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              value: seance['typeCours'] as String,
              items: const [
                DropdownMenuItem(value: 'cours', child: Text('Cours')),
                DropdownMenuItem(value: 'td', child: Text('TD')),
                DropdownMenuItem(value: 'tp', child: Text('TP')),
                DropdownMenuItem(value: 'evaluation', child: Text('Évaluation')),
              ],
              onChanged: (value) => setState(() => _seances[index]['typeCours'] = value!),
            ),
          ),
        ],
      ),
    );
  }
}
