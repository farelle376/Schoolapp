// lib/screens/gestemploi.dart

import 'package:flutter/material.dart';
import '../services/admin_emploi_service.dart';
import '../model/emploi_du_temps_admin_model.dart';

class GestEmploiPage extends StatefulWidget {
  @override
  _GestEmploiPageState createState() => _GestEmploiPageState();
}

class _GestEmploiPageState extends State<GestEmploiPage> {
  final AdminEmploiService _emploiService = AdminEmploiService();
  List<EmploiDuTempsAdminModel> _allEmplois = [];
  List<EmploiDuTempsAdminModel> _coursList = [];
  List<EmploiDuTempsAdminModel> _tdList = [];
  List<EmploiDuTempsAdminModel> _evaluationList = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _professeurs = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedClasseId;
  int _selectedTab = 0;
  
  // Pour le panel latéral
  bool _isPanelOpen = false;
  EmploiDuTempsAdminModel? _editingEmploi;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final emplois = await _emploiService.getEmplois();
      final classes = await _emploiService.getClasses();
      final matieres = await _emploiService.getMatieres();
      final professeurs = await _emploiService.getProfesseurs();
      
      if (!mounted) return;
      
      setState(() {
        _allEmplois = emplois;
        _classes = classes;
        _matieres = matieres;
        _professeurs = professeurs;
        _filterByType();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterByType() {
    if (!mounted) return;
    
    List<EmploiDuTempsAdminModel> source = _selectedClasseId == null 
        ? _allEmplois 
        : _allEmplois.where((e) => e.classeId == _selectedClasseId).toList();
    
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

  void _openAddPanel() {
    if (_classes.isEmpty) {
      _showSnackBar('Chargement des classes en cours...', isError: false);
      return;
    }
    if (_matieres.isEmpty) {
      _showSnackBar('Chargement des matières en cours...', isError: false);
      return;
    }
    if (_professeurs.isEmpty) {
      _showSnackBar('Chargement des professeurs en cours...', isError: false);
      return;
    }
    
    setState(() {
      _editingEmploi = null;
      _isPanelOpen = true;
    });
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

  Future<void> _deleteEmploi(EmploiDuTempsAdminModel emploi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer le cours de ${emploi.matiereNom} du ${emploi.jourLabel} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      
      final success = await _emploiService.deleteEmploi(emploi.id);
      
      if (!mounted) return;
      
      if (success) {
        await _loadData();
        _showSnackBar('Cours supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoading = false);
      }
    }
  }

  List<DropdownMenuItem<String>> _generateHours() {
    List<DropdownMenuItem<String>> hours = [];
    for (int i = 7; i <= 18; i++) {
      String hour = i.toString().padLeft(2, '0');
      hours.add(DropdownMenuItem(value: '$hour:00', child: Text('$hour:00')));
      hours.add(DropdownMenuItem(value: '$hour:30', child: Text('$hour:30')));
    }
    return hours;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Contenu principal
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorWidget()
                  : Column(
                      children: [
                        _buildFilters(),
                        _buildTabs(),
                        Expanded(
                          child: _getCurrentList().isEmpty
                              ? const Center(child: Text('Aucun cours trouvé'))
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
          
          // Panel latéral coulissant
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            right: _isPanelOpen ? 0 : -MediaQuery.of(context).size.width * 0.9,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPanel,
        backgroundColor: const Color(0xFFF47C3C),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPanelHeader() {
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
                  _editingEmploi == null ? 'Ajouter un cours' : 'Modifier',
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

  Widget _buildForm() {
    final formKey = GlobalKey<FormState>();
    int? selectedClasseId = _editingEmploi?.classeId;
    int? selectedMatiereId = _editingEmploi?.matiereId;
    int? selectedProfesseurId = _editingEmploi?.professeurId;
    String selectedJour = _editingEmploi?.jour ?? 'lundi';
    String selectedHeureDebut = _editingEmploi?.heureDebut ?? '08:00';
    String selectedHeureFin = _editingEmploi?.heureFin ?? '10:00';
    String selectedTypeCours = _editingEmploi?.typeCours ?? 'cours';

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du cours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 16),
          
          // Classe
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Classe',
                prefixIcon: Icon(Icons.class_, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: selectedClasseId,
              items: _classes.map<DropdownMenuItem<int>>((c) {
                String label = c['nom_complet']?.toString() ?? '';
                if (label.isEmpty) label = 'Classe ${c['id']}';
                return DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) => selectedClasseId = value,
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 12),
          
          // Matière
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Matière',
                prefixIcon: Icon(Icons.book, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: selectedMatiereId,
              items: _matieres.map<DropdownMenuItem<int>>((m) {
                String label = m['nom']?.toString() ?? 'Matière';
                return DropdownMenuItem<int>(
                  value: m['id'] as int,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) => selectedMatiereId = value,
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 12),
          
          // Professeur
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Professeur',
                prefixIcon: Icon(Icons.person, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: selectedProfesseurId,
              items: _professeurs.map<DropdownMenuItem<int>>((p) {
                String label = p['nom_complet']?.toString() ?? '';
                if (label.isEmpty) {
                  label = p['prenom']?.toString() ?? '';
                  if (label.isNotEmpty) label += ' ${p['nom'] ?? ''}';
                  if (label.isEmpty) label = 'Professeur ${p['id']}';
                }
                return DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) => selectedProfesseurId = value,
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 12),
          
          // Jour
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Jour',
                prefixIcon: Icon(Icons.calendar_today, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Heure début',
                      prefixIcon: Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    value: selectedHeureDebut,
                    items: _generateHours(),
                    onChanged: (value) => selectedHeureDebut = value!,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Heure fin',
                      prefixIcon: Icon(Icons.access_time, color: Color(0xFFF47C3C)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type de cours',
                prefixIcon: Icon(Icons.category, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
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
          
          // Bouton d'envoi
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  _closePanel();
                  setState(() => _isLoading = true);
                  
                  bool success;
                  if (_editingEmploi == null) {
                    success = await _emploiService.createEmploi({
                      'classe_id': selectedClasseId,
                      'matiere_id': selectedMatiereId,
                      'professeur_id': selectedProfesseurId,
                      'jour': selectedJour,
                      'heure_debut': selectedHeureDebut,
                      'heure_fin': selectedHeureFin,
                      'type_cours': selectedTypeCours,
                      'est_active': true,
                    });
                  } else {
                    success = await _emploiService.updateEmploi(_editingEmploi!.id, {
                      'classe_id': selectedClasseId,
                      'matiere_id': selectedMatiereId,
                      'professeur_id': selectedProfesseurId,
                      'jour': selectedJour,
                      'heure_debut': selectedHeureDebut,
                      'heure_fin': selectedHeureFin,
                      'type_cours': selectedTypeCours,
                    });
                  }
                  
                  if (mounted) {
                    if (success) {
                      await _loadData();
                      _showSnackBar(_editingEmploi == null ? 'Cours ajouté' : 'Cours modifié', isError: false);
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
              child: Text(
                _editingEmploi == null ? 'AJOUTER' : 'MODIFIER',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
            backgroundColor: Colors.grey[200],
            selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
            labelStyle: TextStyle(
              color: _selectedClasseId == null ? const Color(0xFFF47C3C) : Colors.grey[700],
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
                backgroundColor: Colors.grey[200],
                selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _selectedClasseId == classe['id'] ? const Color(0xFFF47C3C) : Colors.grey[700],
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
            color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[300]!,
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
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
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
      case 0: return _coursList;
      case 1: return _tdList;
      case 2: return _evaluationList;
      default: return [];
    }
  }

  // Carte réduite et compacte
  Widget _buildEmploiCard(EmploiDuTempsAdminModel emploi) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        onTap: () => _openEditPanel(emploi),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Icône colorée selon le type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emploi.typeCoursColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  emploi.typeCours == 'cours' ? Icons.menu_book :
                  emploi.typeCours == 'evaluation' ? Icons.assignment :
                  Icons.computer,
                  color: emploi.typeCoursColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emploi.matiereNom,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emploi.classeNom,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: 10, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            emploi.professeurNom,
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Jour et heure
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
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
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Icône type
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
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
}