// lib/widgets/edit_matiere_panel.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';

class EditMatierePanel extends StatefulWidget {
  final Map<String, dynamic> matiere;
  final List<Map<String, dynamic>> classes;
  final VoidCallback onUpdate;

  const EditMatierePanel({
    Key? key,
    required this.matiere,
    required this.classes,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditMatierePanelState createState() => _EditMatierePanelState();
}

class _EditMatierePanelState extends State<EditMatierePanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _coefficientController = TextEditingController();
  List<Map<String, dynamic>> _selectedClasses = [];
  bool _isSaving = false;

  // ✅ Créer une instance du service
  final ClassmatService _service = ClassmatService();

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    
    _nomController.text = widget.matiere['nom'] ?? '';
    _coefficientController.text = (widget.matiere['coefficient'] ?? 1).toString();
    
    final classes = widget.matiere['classes'] as List? ?? [];
    for (var c in classes) {
      _selectedClasses.add({
        'id': c['id'],
        'nom': c['nom'],
      });
    }
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nomController.dispose();
    _coefficientController.dispose();
    super.dispose();
  }

  void _toggleClasse(Map<String, dynamic> classe) {
    setState(() {
      final exists = _selectedClasses.any((c) => c['id'] == classe['id']);
      if (exists) {
        _selectedClasses.removeWhere((c) => c['id'] == classe['id']);
      } else {
        _selectedClasses.add(classe);
      }
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final classesList = _selectedClasses.map((c) => ({'id': c['id']})).toList();
      
      // ✅ Utiliser l'instance au lieu de la méthode statique
      final response = await _service.updateMatiere(widget.matiere['id'], {
        'nom': _nomController.text,
        'coefficient': int.parse(_coefficientController.text),
        'classes': classesList,
      });
      
      setState(() => _isSaving = false);
      
      if (response['success'] == true) {
        _showSnackBar('Matière modifiée avec succès', Colors.green);
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

  InputDecoration _getInputDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF47C3C), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF47C3C)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D2B4E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _controller.reverse().then((_) => Navigator.pop(context)),
      child: Container(
        color: Colors.black.withOpacity(0.5),
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
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
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
                        // Header stylisé
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79), Color(0xFF2E6B9E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'MODIFICATION',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.matiere['nom'] ?? 'Matière',
                                      style: const TextStyle(
                                        fontSize: 20,
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
                                  onPressed: () => _controller.reverse().then((_) => Navigator.pop(context)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content stylisé
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Titre section informations
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF47C3C),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Informations de la matière',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Nom de la matière
                                  _buildFormField(
                                    label: 'Nom de la matière',
                                    icon: Icons.book,
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Coefficient
                                  _buildFormField(
                                    label: 'Coefficient (1-10)',
                                    icon: Icons.numbers,
                                    child: TextFormField(
                                      controller: _coefficientController,
                                      keyboardType: TextInputType.number,
                                      decoration: _getInputDecoration(),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Champ requis';
                                        final coef = int.tryParse(v);
                                        if (coef == null || coef < 1 || coef > 10) {
                                          return 'Coefficient entre 1 et 10';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Titre section classes
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF47C3C),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Classes assignées',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Classes sélectionnées
                                  if (_selectedClasses.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: const Color(0xFFF47C3C),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Classes sélectionnées',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0D2B4E),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _selectedClasses.map((classe) {
                                              return Chip(
                                                label: Text(classe['nom']),
                                                backgroundColor: const Color(0xFFF47C3C).withOpacity(0.1),
                                                deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFFF47C3C)),
                                                onDeleted: () => _toggleClasse(classe),
                                                labelStyle: TextStyle(
                                                  color: const Color(0xFFF47C3C),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Liste des classes disponibles
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.list,
                                                size: 16,
                                                color: const Color(0xFFF47C3C),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Toutes les classes',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0D2B4E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: widget.classes.map((classe) {
                                              final isSelected = _selectedClasses.any((c) => c['id'] == classe['id']);
                                              return FilterChip(
                                                label: Text(classe['nom']),
                                                selected: isSelected,
                                                onSelected: (_) => _toggleClasse(classe),
                                                backgroundColor: Colors.grey[200],
                                                selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                                                checkmarkColor: const Color(0xFFF47C3C),
                                                labelStyle: TextStyle(
                                                  color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[700],
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Bouton de modification stylisé
                                  Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF47C3C), Color(0xFFD35400)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF47C3C).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
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
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.save, color: Colors.white, size: 22),
                                                SizedBox(width: 12),
                                                Text(
                                                  'MODIFIER LA MATIÈRE',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    letterSpacing: 1.2,
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