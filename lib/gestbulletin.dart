// lib/screens/gestbulletin.dart

import 'package:flutter/material.dart';
import '../services/admin_bulletin_service.dart';
import '../model/bulletin_admin_model.dart';
import 'bulletin_detail_screen.dart';

class GestBulletinPage extends StatefulWidget {
  @override
  _GestBulletinPageState createState() => _GestBulletinPageState();
}

class _GestBulletinPageState extends State<GestBulletinPage> {
  final AdminBulletinService _service = AdminBulletinService();
  List<ClasseInfo> _classes = [];
  List<BulletinAdminModel> _bulletins = [];
  List<BulletinAdminModel> _filteredBulletins = [];
  bool _isLoading = true;
  bool _isLoadingList = false;
  bool _isExporting = false;
  String? _error;
  int? _selectedClasseId;
  String _selectedTrimestre = '1';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _trimestres = ['1', '2', '3'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
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
      _applyLocalFilter();
    });
  }

  void _applyLocalFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredBulletins = List.from(_bulletins);
      });
    } else {
      setState(() {
        _filteredBulletins = _bulletins.where((bulletin) {
          return bulletin.fullName.toLowerCase().contains(_searchQuery);
        }).toList();
      });
    }
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _service.getClasses();
      
      if (!mounted) return;
      
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty) {
          _selectedClasseId = _classes.first.id;
          _loadBulletins();
        }
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

  Future<void> _loadBulletins() async {
    if (_selectedClasseId == null) return;
    
    setState(() {
      _isLoadingList = true;
      _error = null;
    });

    try {
      final bulletins = await _service.getBulletinsByClasse(
        _selectedClasseId!, 
        _selectedTrimestre,
      );
      
      if (!mounted) return;
      
      setState(() {
        _bulletins = bulletins;
        _applyLocalFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  Future<void> _deleteBulletin(BulletinAdminModel bulletin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer le bulletin de ${bulletin.fullName} (Trimestre ${bulletin.trimestre}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoadingList = true);
      final success = await _service.deleteBulletin(bulletin.id);
      if (success) {
        await _loadBulletins();
        _showSnackBar('Bulletin supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoadingList = false);
      }
    }
  }

  Future<void> _editBulletin(BulletinAdminModel bulletin) async {
    // Navigation vers l'écran de détail avec génération
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulletinDetailScreen(
          eleveId: bulletin.eleveId,
          eleveNom: bulletin.fullName,
          classe: bulletin.classe,
          trimestre: bulletin.trimestre,  // ← AJOUTER LE TRIMESTRE
        ),
      ),
    );
    
    if (result == true) {
      _loadBulletins();
    }
  }

  Future<void> _viewBulletin(BulletinAdminModel bulletin) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulletinDetailScreen(
          eleveId: bulletin.eleveId,
          eleveNom: bulletin.fullName,
          classe: bulletin.classe,
          trimestre: bulletin.trimestre,  // ← AJOUTER LE TRIMESTRE
        ),
      ),
    );
    
    if (result == true) {
      _loadBulletins();
    }
  }

  Future<void> _generateBulletinForEleve(int eleveId, String eleveName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer un bulletin'),
        content: Text('Générer le bulletin pour $eleveName ?\nTrimestre $_selectedTrimestre'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Naviguer vers l'écran de détail qui va générer le bulletin
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BulletinDetailScreen(
            eleveId: eleveId,
            eleveNom: eleveName,
            classe: _classes.firstWhere((c) => c.id == _selectedClasseId).nom,
            trimestre: _selectedTrimestre,  // ← AJOUTER LE TRIMESTRE
          ),
        ),
      );
      
      if (result == true) {
        _loadBulletins();
      }
    }
  }

  Future<void> _generateAllBulletins() async {
    if (_selectedClasseId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer tous les bulletins'),
        content: Text('Générer les bulletins pour TOUS les élèves de cette classe ?\nTrimestre $_selectedTrimestre'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Générer tous'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoadingList = true);
      _showSnackBar('Vérification des notes en cours...', isError: false);
      
      final eleves = await _service.getElevesByClasse(_selectedClasseId!);
      List<Map<String, dynamic>> elevesSansNotes = [];
      
      for (var eleve in eleves) {
        // Vérifier si les notes sont disponibles
        final checkResult = await _service.checkNotesDisponibles(
          eleve['id'], 
          _selectedTrimestre,  // ← AJOUTER LE TRIMESTRE
        );
        
        if (!checkResult['toutes_disponibles']) {
          elevesSansNotes.add({
            'nom': eleve['nom'],
            'prenom': eleve['prenom'],
            'details': checkResult['details']
          });
        }
      }
      
      if (elevesSansNotes.isNotEmpty) {
        String message = '⚠️ Certains élèves n\'ont pas toutes les notes requises :\n\n';
        for (var eleve in elevesSansNotes) {
          message += '• ${eleve['prenom']} ${eleve['nom']}\n';
        }
        message += '\nVoulez-vous quand même continuer ?';
        
        final continueAnyway = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notes manquantes'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Continuer quand même'),
              ),
            ],
          ),
        );
        
        if (continueAnyway != true) {
          setState(() => _isLoadingList = false);
          return;
        }
      }
      
      _showSnackBar('Génération en cours...', isError: false);
      
      int successCount = 0;
      for (var eleve in eleves) {
        final result = await _service.generateBulletin(eleve['id'], _selectedTrimestre);
        if (result['success']) successCount++;
      }
      
      await _loadBulletins();
      _showSnackBar('$successCount bulletins générés sur ${eleves.length}', isError: false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _getMoyenneColor(double moyenne) {
    if (moyenne >= 16) return Colors.green;
    if (moyenne >= 14) return Colors.lightGreen;
    if (moyenne >= 12) return Colors.orange;
    if (moyenne >= 10) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des bulletins', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildClassSelector(),
                    _buildTrimestreSelector(),
                    _buildSearchBar(),
                    if (_selectedClasseId != null) ...[
                      _buildGenerateButton(),
                      Expanded(
                        child: _isLoadingList
                            ? const Center(child: CircularProgressIndicator())
                            : _filteredBulletins.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredBulletins.length,
                                    itemBuilder: (context, index) {
                                      final bulletin = _filteredBulletins[index];
                                      return _buildBulletinCard(bulletin);
                                    },
                                  ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un élève...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyLocalFilter();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      height: 45,
      margin: const EdgeInsets.all(12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._classes.map((classe) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(classe.nom),
              selected: _selectedClasseId == classe.id,
              onSelected: (_) {
                setState(() {
                  _selectedClasseId = classe.id;
                  _searchController.clear();
                  _searchQuery = '';
                });
                _loadBulletins();
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedClasseId == classe.id ? const Color(0xFFF47C3C) : Colors.grey[700],
                fontWeight: _selectedClasseId == classe.id ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrimestreSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTrimestre,
          isExpanded: true,
          items: _trimestres.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text('Trimestre $t'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTrimestre = value;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadBulletins();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generateAllBulletins,
              icon: const Icon(Icons.add),
              label: const Text('Générer tous les bulletins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun bulletin trouvé' : 'Aucun bulletin généré',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_searchQuery.isEmpty)
            const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Générez des bulletins pour cette classe',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildBulletinCard(BulletinAdminModel bulletin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: InkWell(
        onTap: () => _viewBulletin(bulletin),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF47C3C), Color(0xFFFF6B35)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    bulletin.fullName.isNotEmpty ? bulletin.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bulletin.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bulletin.classe,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trimestre ${bulletin.trimestre}',
                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMoyenneColor(bulletin.moyenneGenerale).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Moy: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getMoyenneColor(bulletin.moyenneGenerale),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () => _editBulletin(bulletin),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _deleteBulletin(bulletin),
                    tooltip: 'Supprimer',
                  ),
                ],
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
            onPressed: _loadClasses,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}