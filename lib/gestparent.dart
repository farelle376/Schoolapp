// lib/screens/gestparent.dart

import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../model/parent_model.dart';

class GestParentPage extends StatefulWidget {
  @override
  _GestParentPageState createState() => _GestParentPageState();
}

class _GestParentPageState extends State<GestParentPage> {
  final ParentService _parentService = ParentService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ParentModel> _parents = [];
  List<ParentModel> _filteredParents = []; // Pour le filtrage local
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  
  // Pour le panel latéral
  bool _isPanelOpen = false;
  ParentModel? _editingParent;

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
      _applyLocalFilter(); // Filtrage local uniquement
    });
  }

  void _applyLocalFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredParents = List.from(_parents);
      });
    } else {
      setState(() {
        _filteredParents = _parents.where((parent) {
          return parent.fullName.toLowerCase().contains(_searchQuery) ||
                 parent.numTelephone.contains(_searchQuery) ||
                 (parent.email?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      });
    }
  }

  Future<void> _loadData({bool resetParents = true}) async {
    if (resetParents) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _parentService.getParents(
        search: null, // Pas de recherche API, on filtre localement
        page: _currentPage,
      );
      
      if (resetParents) {
        final stats = await _parentService.getStats();
        if (mounted) {
          setState(() {
            _stats = stats;
          });
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        if (resetParents) {
          _parents = result['parents'];
          _applyLocalFilter(); // Appliquer le filtre local après chargement
        } else {
          _parents.addAll(result['parents']);
          _applyLocalFilter(); // Re-filtrer après ajout
        }
        _currentPage = result['currentPage'];
        _lastPage = result['lastPage'];
        _error = null;
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
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (_currentPage < _lastPage && !_isLoadingMore && !_isLoading) {
      _currentPage++;
      _loadData(resetParents: false);
    }
  }

  Future<void> _deleteParent(ParentModel parent) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer ${parent.fullName} ?'),
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
      final success = await _parentService.deleteParent(parent.id);
      
      if (!mounted) return;
      
      if (success) {
        _currentPage = 1;
        await _loadData(resetParents: true);
        _showSnackBar('Parent supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoading = false);
      }
    }
  }

  void _openAddPanel() {
    setState(() {
      _editingParent = null;
      _isPanelOpen = true;
    });
  }

  void _openEditPanel(ParentModel parent) {
    setState(() {
      _editingParent = parent;
      _isPanelOpen = true;
    });
  }

  void _closePanel() {
    setState(() {
      _isPanelOpen = false;
      _editingParent = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des parents', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _searchQuery = '';
              _currentPage = 1;
              _loadData(resetParents: true);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          _buildSidePanel(),
        ],
      ),
      
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return _buildErrorWidget();
    }
    
    return Column(
      children: [
        _buildStatsWidget(),
        _buildSearchBar(),
        Expanded(
          child: _filteredParents.isEmpty
              ? _buildEmptyState()
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >= 
                        scrollInfo.metrics.maxScrollExtent - 200 &&
                        !_isLoadingMore &&
                        _currentPage < _lastPage &&
                        _searchQuery.isEmpty) { // Seulement si pas de recherche active
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredParents.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredParents.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildParentCard(_filteredParents[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSidePanel() {
    return AnimatedPositioned(
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
                child: _ParentForm(
                  parent: _editingParent,
                  onSuccess: () {
                    _closePanel();
                    _currentPage = 1;
                    _searchController.clear();
                    _searchQuery = '';
                    _loadData(resetParents: true);
                  },
                ),
              ),
            ),
          ],
        ),
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
              _editingParent == null ? Icons.person_add : Icons.edit,
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
                  _editingParent == null ? 'Ajouter un parent' : 'Modifier',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _editingParent == null ? 'Nouveau parent' : _editingParent!.fullName,
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

  Widget _buildStatsWidget() {
    final total = _stats['total'] ?? _filteredParents.length;
    final hommes = (_stats['pere'] ?? 0) + (_stats['tuteur'] ?? 0);
    final femmes = _stats['mere'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, 'Total', total.toString(), Colors.white),
          _buildStatItem(Icons.man, 'Hommes', hommes.toString(), Colors.lightBlueAccent),
          _buildStatItem(Icons.woman, 'Femmes', femmes.toString(), Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
            hintText: 'Rechercher un parent...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyLocalFilter();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildParentCard(ParentModel parent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _openEditPanel(parent),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF47C3C), Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    parent.initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2B4E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          parent.numTelephone,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (parent.email != null && parent.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.email, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                parent.email!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _openEditPanel(parent),
                      tooltip: 'Modifier',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteParent(parent),
                      tooltip: 'Supprimer',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF47C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 50,
              color: const Color(0xFFF47C3C),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun parent trouvé' : 'Aucun parent enregistré',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Cliquez sur le bouton + pour ajouter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            const SizedBox(height: 16),
          if (_searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _applyLocalFilter();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _error!,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _searchQuery = '';
              _currentPage = 1;
              _loadData(resetParents: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// Formulaire stylisé dans un widget séparé
class _ParentForm extends StatefulWidget {
  final ParentModel? parent;
  final VoidCallback onSuccess;

  const _ParentForm({this.parent, required this.onSuccess});

  @override
  _ParentFormState createState() => _ParentFormState();
}

class _ParentFormState extends State<_ParentForm> {
  final ParentService _parentService = ParentService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late String _typeParent;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.parent?.nom ?? '');
    _prenomController = TextEditingController(text: widget.parent?.prenom ?? '');
    _telephoneController = TextEditingController(text: widget.parent?.numTelephone ?? '');
    _emailController = TextEditingController(text: widget.parent?.email ?? '');
    _typeParent = widget.parent?.typeParent ?? 'pere';
  }

  @override
  void didUpdateWidget(covariant _ParentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parent != oldWidget.parent) {
      _nomController.text = widget.parent?.nom ?? '';
      _prenomController.text = widget.parent?.prenom ?? '';
      _telephoneController.text = widget.parent?.numTelephone ?? '';
      _emailController.text = widget.parent?.email ?? '';
      _typeParent = widget.parent?.typeParent ?? 'pere';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final data = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'type_parent': _typeParent,
        'num_telephone': _telephoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'is_active': true,
      };
      
      bool success;
      if (widget.parent == null) {
        success = await _parentService.createParent(data);
      } else {
        success = await _parentService.updateParent(widget.parent!.id, data);
      }
      
      if (mounted) {
        setState(() => _isSaving = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.parent == null ? 'Parent ajouté avec succès' : 'Parent modifié avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'enregistrement'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez le nom',
                prefixIcon: Icon(Icons.person, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) => v!.isEmpty ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                hintText: 'Entrez le prénom',
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) => v!.isEmpty ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Type de parent',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<String>(
              value: _typeParent,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.family_restroom, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'pere', child: Text('👨 Père')),
                DropdownMenuItem(value: 'mere', child: Text('👩 Mère')),
                DropdownMenuItem(value: 'tuteur', child: Text('👤 Tuteur')),
              ],
              onChanged: (value) => setState(() => _typeParent = value!),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B4E),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: 'Entrez le numéro de téléphone',
                prefixIcon: Icon(Icons.phone, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Champ requis' : null,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'exemple@email.com',
                prefixIcon: Icon(Icons.email, color: Color(0xFFF47C3C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.parent == null ? Icons.save : Icons.update,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.parent == null ? 'ENREGISTRER' : 'METTRE À JOUR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}