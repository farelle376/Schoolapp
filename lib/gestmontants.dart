// lib/screens/gestmontants.dart

import 'package:flutter/material.dart';
import '../services/admin_scolarite_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/scolarite_model.dart';
import '../model/annee_scolaire_model.dart';

class GestMontantsPage extends StatefulWidget {
  @override
  _GestMontantsPageState createState() => _GestMontantsPageState();
}

class _GestMontantsPageState extends State<GestMontantsPage> {
  final AdminScolariteService _service = AdminScolariteService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  List<ClasseInfo> _classes = [];
  List<AnneeScolaire> _anneesScolaires = [];
  List<Map<String, dynamic>> _tranches = [];
  // Sélection d'une seule classe à la fois, via une liste déroulante.
  // Rien n'est sélectionné par défaut : l'utilisateur doit choisir une
  // classe avant de pouvoir enregistrer des tranches.
  int? _selectedClasseId;
  int? _selectedAnneeId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFormExpanded = false;
  String? _error;

  // Contrôleurs pour chaque tranche (1 à 4)
  final List<TextEditingController> _montantControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _libelleControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _descriptionControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _dateLimiteControllers = List.generate(5, (_) => TextEditingController());

  final Map<int, String> _defaultLibelles = {
    1: '📚 Inscription',
    2: '📖 1er Trimestre',
    3: '📝 2ème Trimestre',
    4: '🎓 3ème Trimestre',
  };

  final Map<int, IconData> _trancheIcons = {
    1: Icons.app_registration,
    2: Icons.book,
    3: Icons.edit_note,
    4: Icons.school,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _montantControllers) controller.dispose();
    for (var controller in _libelleControllers) controller.dispose();
    for (var controller in _descriptionControllers) controller.dispose();
    for (var controller in _dateLimiteControllers) controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les années
      final annees = await _anneeService.getAnneesScolaires();
      _anneesScolaires = annees;

      // Définir l'année par défaut (en cours ou première)
      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }

      // Charger les classes réellement enregistrées pour l'année sélectionnée
      final classes = await _service.getClasses(anneeScolaireId: _selectedAnneeId);
      _classes = classes;

      // Si la classe précédemment sélectionnée n'existe plus dans la
      // nouvelle liste (changement d'année par ex.), on réinitialise.
      if (_selectedClasseId != null && !classes.any((c) => c.id == _selectedClasseId)) {
        _selectedClasseId = null;
      }

      // Si une classe est sélectionnée, recharger ses tranches avec l'année
      if (_selectedClasseId != null && _selectedAnneeId != null) {
        await _loadTranches(_selectedClasseId!, _selectedAnneeId!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTranches(int classeId, int anneeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.getTranchesByClasse(
        classeId,
        anneeScolaireId: anneeId,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _tranches = List<Map<String, dynamic>>.from(data);
        });

        _fillControllersFromTranches();
      } else {
        _resetAllControllers();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fillControllersFromTranches() {
    for (int i = 1; i <= 4; i++) {
      final existing = _tranches.firstWhere(
        (t) => t['numero'] == i,
        orElse: () => {},
      );

      _libelleControllers[i].text = existing['libelle'] ?? _defaultLibelles[i] ?? '';
      _descriptionControllers[i].text = existing['description'] ?? '';
      _montantControllers[i].text = (existing['montant'] ?? 0) > 0
          ? (existing['montant'] as num).toStringAsFixed(0)
          : '';

      if (existing['date_limite'] != null && existing['date_limite'].toString().isNotEmpty) {
        String dateStr = existing['date_limite'].toString();
        if (dateStr.contains('-')) {
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            _dateLimiteControllers[i].text = '${parts[2]}/${parts[1]}/${parts[0]}';
          }
        } else {
          _dateLimiteControllers[i].text = dateStr;
        }
      } else {
        _dateLimiteControllers[i].text = '';
      }
    }
  }

  void _resetAllControllers() {
    for (int i = 1; i <= 4; i++) {
      _libelleControllers[i].text = _defaultLibelles[i] ?? '';
      _descriptionControllers[i].text = '';
      _montantControllers[i].text = '';
      _dateLimiteControllers[i].text = '';
    }
  }

  Future<void> _saveAllTranches() async {
    if (_selectedClasseId == null || _selectedAnneeId == null) {
      _showSnackBar('Veuillez sélectionner une classe et une année');
      return;
    }

    List<Map<String, dynamic>> tranchesToSave = [];

    for (int i = 1; i <= 4; i++) {
      double montant = double.tryParse(_montantControllers[i].text.replaceAll(',', '.')) ?? 0;

      if (montant > 0 || _libelleControllers[i].text != _defaultLibelles[i]) {
        String dateLimite = '';
        if (_dateLimiteControllers[i].text.isNotEmpty) {
          final parts = _dateLimiteControllers[i].text.split('/');
          if (parts.length == 3) {
            dateLimite = '${parts[2]}-${parts[1]}-${parts[0]}';
          } else {
            dateLimite = _dateLimiteControllers[i].text;
          }
        }

        tranchesToSave.add({
          'numero': i,
          'montant': montant,
          'libelle': _libelleControllers[i].text.isNotEmpty
              ? _libelleControllers[i].text
              : _defaultLibelles[i],
          'description': _descriptionControllers[i].text,
          'date_limite': dateLimite,
        });
      }
    }

    if (tranchesToSave.isEmpty) {
      _showSnackBar('Veuillez saisir au moins un montant valide');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await _service.saveTranchesByClasse(
        _selectedClasseId!,
        tranchesToSave,
        anneeScolaireId: _selectedAnneeId!,
      );

      if (response['success'] == true) {
        _showSnackBar('Toutes les tranches ont été enregistrées', isError: false);
      } else {
        _showSnackBar(response['message'] ?? 'Erreur lors de l\'enregistrement');
      }

      await _loadTranches(_selectedClasseId!, _selectedAnneeId!);
      setState(() {
        _isFormExpanded = false;
      });
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteTranche(int numero) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer la tranche $numero ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && _selectedClasseId != null && _selectedAnneeId != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final updatedTranches = _tranches
            .where((t) => t['numero'] != numero)
            .map((t) => {
                  'numero': t['numero'],
                  'montant': t['montant'] ?? 0,
                  'libelle': t['libelle'] ?? '',
                  'description': t['description'] ?? '',
                  'date_limite': t['date_limite'] ?? '',
                })
            .toList();

        final response = await _service.saveTranchesByClasse(
          _selectedClasseId!,
          updatedTranches,
          anneeScolaireId: _selectedAnneeId!,
        );

        if (response['success'] == true) {
          _montantControllers[numero].clear();
          _dateLimiteControllers[numero].clear();
          _descriptionControllers[numero].clear();
          _libelleControllers[numero].text = _defaultLibelles[numero] ?? '';

          await _loadTranches(_selectedClasseId!, _selectedAnneeId!);
          _showSnackBar('Tranche $numero supprimée', isError: false);
        } else {
          _showSnackBar(response['message'] ?? 'Erreur');
        }
      } catch (e) {
        _showSnackBar('Erreur: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
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

  bool get _hasAnyTranche {
    return _tranches.any((t) => (t['montant'] ?? 0) > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des montants', style: TextStyle(color: Colors.white)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Sélecteur d'année
                    if (_anneesScolaires.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Text('Année : ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<int>(
                                value: _selectedAnneeId,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Sélectionnez une année'),
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
                                    // Les classes dépendent de l'année : on
                                    // réinitialise la classe sélectionnée.
                                    _selectedClasseId = null;
                                    _tranches.clear();
                                    _resetAllControllers();
                                    _isFormExpanded = false;
                                  });
                                  if (value != null) {
                                    await _loadData();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildClasseDropdown(),
                    if (_selectedAnneeId != null) ...[
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_isFormExpanded) _buildCompleteForm(),
                              if (!_isFormExpanded && _hasAnyTranche) _buildTranchesList(),
                              if (!_isFormExpanded && !_hasAnyTranche) _buildEmptyState(),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_selectedAnneeId == null)
                      const Expanded(
                        child: Center(
                          child: Text('Veuillez sélectionner une année'),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _selectedAnneeId != null &&
              !_isFormExpanded
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isFormExpanded = true;
                });
              },
              backgroundColor: const Color(0xFFF47C3C),
              child: const Icon(Icons.edit_note),
            )
          : null,
    );
  }

  void _onClasseChanged(int? classeId) {
    setState(() {
      _selectedClasseId = classeId;
      _isFormExpanded = false;
      _tranches.clear();
      _resetAllControllers();
    });
    if (_selectedClasseId != null && _selectedAnneeId != null) {
      _loadTranches(_selectedClasseId!, _selectedAnneeId!);
    }
  }

  Widget _buildClasseDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Text('Classe : ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<int>(
              value: _selectedClasseId,
              isDense: true,
              isExpanded: false,
              underline: const SizedBox(),
              hint: const Text('Sélectionnez une classe', style: TextStyle(fontSize: 13)),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: _classes.map((classe) {
                return DropdownMenuItem<int>(
                  value: classe.id,
                  child: Text(classe.nom),
                );
              }).toList(),
              onChanged: _onClasseChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        ...List.generate(4, (index) {
          int trancheNum = index + 1;
          return _buildTrancheCard(trancheNum);
        }),
        const SizedBox(height: 16),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTrancheCard(int numero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // En-tête de la tranche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2B4E).withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF47C3C), Color(0xFFFF6B3D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_trancheIcons[numero], color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tranche $numero',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2B4E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _defaultLibelles[numero]!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (_montantControllers[numero].text.isNotEmpty && 
                      double.tryParse(_montantControllers[numero].text) != null &&
                      double.parse(_montantControllers[numero].text) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Configuré',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            // Corps du formulaire
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _libelleControllers[numero],
                    decoration: InputDecoration(
                      labelText: 'Libellé',
                      hintText: _defaultLibelles[numero],
                      prefixIcon: Icon(Icons.label, color: const Color(0xFFF47C3C), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _montantControllers[numero],
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      hintText: 'Ex: 150000',
                      prefixIcon: Icon(Icons.attach_money, color: const Color(0xFFF47C3C), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateLimiteControllers[numero],
                    decoration: InputDecoration(
                      labelText: 'Date limite',
                      hintText: 'JJ/MM/AAAA',
                      prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFFF47C3C), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionControllers[numero],
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: Icon(Icons.description, color: const Color(0xFFF47C3C), size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _isFormExpanded = false;
              _resetAllControllers();
              if (_selectedClasseId != null && _selectedAnneeId != null) {
                _loadTranches(_selectedClasseId!, _selectedAnneeId!);
              }
            });
          },
          icon: const Icon(Icons.close),
          label: const Text('Annuler'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade400),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAllTranches,
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: const Text('Enregistrer tout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF47C3C),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTranchesList() {
    final visibleTranches = _tranches.where((t) => (t['montant'] ?? 0) > 0).toList();
    
    if (visibleTranches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Tranches configurées',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E)),
        ),
        const SizedBox(height: 12),
        ...visibleTranches.map((tranche) => _buildTrancheCardCompact(tranche)),
      ],
    );
  }

  Widget _buildTrancheCardCompact(Map<String, dynamic> tranche) {
    final numero = tranche['numero'] as int;
    String formattedDate = '';
    
    dynamic dateValue = tranche['date_limite'];
    if (dateValue != null && dateValue.toString().isNotEmpty && dateValue.toString() != 'null') {
      String dateStr = dateValue.toString();
      if (dateStr.contains('T')) dateStr = dateStr.split('T')[0];
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      } else {
        formattedDate = dateStr;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditDialog(tranche),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF47C3C), Color(0xFFFF6B3D)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tranche['libelle'] ?? 'Tranche $numero',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(tranche['montant'] ?? 0).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                    if (formattedDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 12, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Limite: $formattedDate',
                              style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteTranche(numero),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> tranche) {
    int numero = tranche['numero'];
    String displayDate = '';
    
    if (tranche['date_limite'] != null && tranche['date_limite'].toString().isNotEmpty) {
      String dateStr = tranche['date_limite'].toString();
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      } else {
        displayDate = dateStr;
      }
    }
    
    final montantController = TextEditingController(text: (tranche['montant'] ?? 0).toString());
    final libelleController = TextEditingController(text: tranche['libelle'] ?? '');
    final descriptionController = TextEditingController(text: tranche['description'] ?? '');
    final dateLimiteController = TextEditingController(text: displayDate);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_trancheIcons[numero], color: const Color(0xFFF47C3C)),
            const SizedBox(width: 8),
            Text('Tranche $numero'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: libelleController,
                decoration: InputDecoration(
                  labelText: 'Libellé',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: montantController,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateLimiteController,
                decoration: InputDecoration(
                  labelText: 'Date limite (JJ/MM/AAAA)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              String dateLimite = dateLimiteController.text;
              if (dateLimite.isNotEmpty && dateLimite.contains('/')) {
                final parts = dateLimite.split('/');
                if (parts.length == 3) dateLimite = '${parts[2]}-${parts[1]}-${parts[0]}';
              }
              
              _updateSingleTranche({
                'numero': numero,
                'montant': double.tryParse(montantController.text) ?? 0,
                'libelle': libelleController.text,
                'description': descriptionController.text,
                'date_limite': dateLimite,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSingleTranche(Map<String, dynamic> updatedTranche) async {
  if (_selectedClasseId == null || _selectedAnneeId == null) return;

  setState(() {
    _isSaving = true;
  });

  try {
    final updatedTranches = _tranches.map((t) {
      if (t['numero'] == updatedTranche['numero']) return updatedTranche;
      return t;
    }).toList();

    final response = await _service.saveTranchesByClasse(
      _selectedClasseId!,
      updatedTranches,
      anneeScolaireId: _selectedAnneeId!,
    );

    if (response['success'] == true) {
      _showSnackBar('Tranche mise à jour', isError: false);
      await _loadTranches(_selectedClasseId!, _selectedAnneeId!);
    } else {
      _showSnackBar(response['message'] ?? 'Erreur');
    }
  } catch (e) {
    _showSnackBar('Erreur: $e');
  } finally {
    setState(() {
      _isSaving = false;
    });
  }
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF47C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.attach_money, size: 50, color: Color(0xFFF47C3C)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune tranche configurée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cliquez sur le formulaire ci-dessus pour',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Text(
            'définir les montants des 4 tranches',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),
        ],
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
          onPressed: _loadData, // ✅
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );
}
}