// lib/widgets/add_classe_panel.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';

class AddClassePanel extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final VoidCallback onAdd;

  const AddClassePanel({
    Key? key,
    required this.matieres,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddClassePanelState createState() => _AddClassePanelState();
}

class _AddClassePanelState extends State<AddClassePanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  List<Map<String, dynamic>> _selectedMatieres = [];
  Map<int, TextEditingController> _coefficientControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nomController.dispose();
    for (var controller in _coefficientControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleMatiere(Map<String, dynamic> matiere) {
    setState(() {
      final exists = _selectedMatieres.any((m) => m['id'] == matiere['id']);
      if (exists) {
        _selectedMatieres.removeWhere((m) => m['id'] == matiere['id']);
        // Supprimer le contrôleur de coefficient
        final controller = _coefficientControllers[matiere['id']];
        if (controller != null) {
          controller.dispose();
          _coefficientControllers.remove(matiere['id']);
        }
      } else {
        _selectedMatieres.add(matiere);
        // Créer un contrôleur pour le coefficient
        final controller = TextEditingController(text: '1');
        _coefficientControllers[matiere['id']] = controller;
      }
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final matieresList = _selectedMatieres.map((m) => ({
        'id': m['id'],
        'coefficient': int.tryParse(_coefficientControllers[m['id']]?.text ?? '1') ?? 1,
      })).toList();
      
      final response = await ClassmatService.addClasse({
        'nom': _nomController.text,
        'matieres': matieresList,
      });
      
      setState(() => _isSaving = false);
      
      if (response['success'] == true) {
        _showSnackBar('Classe ajoutée avec succès', Colors.green);
        await _controller.reverse();
        widget.onAdd();
        if (mounted) Navigator.pop(context);
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
    return GestureDetector(
      onTap: () => _controller.reverse().then((_) => Navigator.pop(context)),
      child: Container(
        color: Colors.black54,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () {},
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2B4E),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => _controller.reverse().then((_) => Navigator.pop(context)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ajouter une classe',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Color(0xFFF47C3C),
                                      child: Icon(Icons.class_, size: 50, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  const Text(
                                    'Informations de la classe',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Nom de la classe
                                  TextFormField(
                                    controller: _nomController,
                                    decoration: InputDecoration(
                                      labelText: 'Nom de la classe',
                                      prefixIcon: const Icon(Icons.class_),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  const Text(
                                    'Matières assignées',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Chips des matières sélectionnées
                                  if (_selectedMatieres.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Matières sélectionnées',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _selectedMatieres.map((matiere) {
                                              return Chip(
                                                label: Text(matiere['nom']),
                                                backgroundColor: const Color(0xFFF47C3C).withOpacity(0.2),
                                                deleteIcon: const Icon(Icons.close, size: 16),
                                                onDeleted: () => _toggleMatiere(matiere),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  const Text(
                                    'Toutes les matières',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 250),
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: widget.matieres.map((matiere) {
                                          final isSelected = _selectedMatieres.any((m) => m['id'] == matiere['id']);
                                          return FilterChip(
                                            label: Text(matiere['nom']),
                                            selected: isSelected,
                                            onSelected: (_) => _toggleMatiere(matiere),
                                            backgroundColor: Colors.grey.shade200,
                                            selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                                            checkmarkColor: const Color(0xFFF47C3C),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  
                                  // Section des coefficients
                                  if (_selectedMatieres.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFF47C3C).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calculate,
                                                size: 20,
                                                color: const Color(0xFFF47C3C),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Coefficients des matières',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D2B4E),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ..._selectedMatieres.map((matiere) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 2,
                                                    child: Text(
                                                      matiere['nom'],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    flex: 1,
                                                    child: TextFormField(
                                                      controller: _coefficientControllers[matiere['id']],
                                                      keyboardType: TextInputType.number,
                                                      decoration: InputDecoration(
                                                        labelText: 'Coef.',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                      ),
                                                      validator: (value) {
                                                        if (value == null || value.isEmpty) {
                                                          return 'Requis';
                                                        }
                                                        final coef = int.tryParse(value);
                                                        if (coef == null || coef < 1 || coef > 10) {
                                                          return '1-10';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton d'ajout
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF47C3C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'AJOUTER LA CLASSE',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}