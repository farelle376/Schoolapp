// lib/widgets/edit_classe_panel.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';

class EditClassePanel extends StatefulWidget {
  final Map<String, dynamic> classe;
  final List<Map<String, dynamic>> matieres;
  final VoidCallback onUpdate;

  const EditClassePanel({
    Key? key,
    required this.classe,
    required this.matieres,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditClassePanelState createState() => _EditClassePanelState();
}

class _EditClassePanelState extends State<EditClassePanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  List<Map<String, dynamic>> _selectedMatieres = [];
  Map<int, int> _coefficients = {};
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
    
    _nomController.text = widget.classe['nom'] ?? '';
    
    final matieres = widget.classe['matieres'] as List? ?? [];
    for (var m in matieres) {
      _selectedMatieres.add({
        'id': m['id'],
        'nom': m['nom'],
      });
      _coefficients[m['id']] = m['coefficient'] ?? 1;
    }
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nomController.dispose();
    super.dispose();
  }

  void _toggleMatiere(Map<String, dynamic> matiere) {
    setState(() {
      final exists = _selectedMatieres.any((m) => m['id'] == matiere['id']);
      if (exists) {
        _selectedMatieres.removeWhere((m) => m['id'] == matiere['id']);
        _coefficients.remove(matiere['id']);
      } else {
        _selectedMatieres.add(matiere);
        _coefficients[matiere['id']] = 1;
      }
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final matieresList = _selectedMatieres.map((m) => ({
        'id': m['id'],
        'coefficient': _coefficients[m['id']] ?? 1,
      })).toList();
      
      final response = await ClassmatService.updateClasse(widget.classe['id'], {
        'nom': _nomController.text,
        'matieres': matieresList,
      });
      
      setState(() => _isSaving = false);
      
      if (response['success'] == true) {
        _showSnackBar('Classe modifiée avec succès', Colors.green);
        await _controller.reverse();
        widget.onUpdate();
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
                              Expanded(
                                child: Text(
                                  'Modifier ${widget.classe['nom']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                      child: Icon(Icons.edit, size: 50, color: Colors.white),
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
                                            'Sélectionnées',
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
                                  
                                  if (_selectedMatieres.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Coefficients',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: _selectedMatieres.map((matiere) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    matiere['nom'],
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: TextFormField(
                                                    initialValue: _coefficients[matiere['id']]?.toString() ?? '1',
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Coefficient',
                                                      border: OutlineInputBorder(),
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    ),
                                                    onChanged: (value) {
                                                      _coefficients[matiere['id']] = int.tryParse(value) ?? 1;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 30),
                                  
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
                                              'MODIFIER LA CLASSE',
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