// lib/widgets/add_professeur_panel.dart

import 'package:flutter/material.dart';
import '../services/professeur_service.dart';

class AddProfesseurPanel extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final List<Map<String, dynamic>> classes;
  final VoidCallback onAdd;

  const AddProfesseurPanel({
    Key? key,
    required this.matieres,
    required this.classes,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddProfesseurPanelState createState() => _AddProfesseurPanelState();
}

class _AddProfesseurPanelState extends State<AddProfesseurPanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int? _matiereId;
  List<int> _selectedClasseIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    _prenomController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleClasseSelection(int classeId) {
    setState(() {
      if (_selectedClasseIds.contains(classeId)) {
        _selectedClasseIds.remove(classeId);
      } else {
        _selectedClasseIds.add(classeId);
      }
    });
  }

  Future<void> _ajouterProfesseur() async {
    if (_formKey.currentState!.validate()) {
      if (_matiereId == null) {
        _showSnackBar('Veuillez sélectionner une matière', Colors.orange);
        return;
      }

      setState(() => _isLoading = true);

      final data = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'numero': _numeroController.text,
        'matiere_id': _matiereId,
        'classe_ids': _selectedClasseIds,
      };
      
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      final response = await ProfesseurService.addProfesseur(data);

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSnackBar('Professeur ajouté avec succès', Colors.green);
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
                                'Ajouter un professeur',
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
                                      child: Icon(Icons.person_add, size: 50, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  const Text(
                                    'Informations du professeur',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Nom
                                  TextFormField(
                                    controller: _nomController,
                                    decoration: InputDecoration(
                                      labelText: 'Nom',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Prénom
                                  TextFormField(
                                    controller: _prenomController,
                                    decoration: InputDecoration(
                                      labelText: 'Prénom',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Numéro de téléphone
                                  TextFormField(
                                    controller: _numeroController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Numéro de téléphone',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Mot de passe (optionnel)
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Mot de passe (optionnel)',
                                      hintText: 'Laissez vide pour utiliser "1234"',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Matière
                                  DropdownButtonFormField<int>(
                                    value: _matiereId,
                                    decoration: InputDecoration(
                                      labelText: 'Matière enseignée',
                                      prefixIcon: const Icon(Icons.book),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: widget.matieres.map<DropdownMenuItem<int>>((m) {
                                      return DropdownMenuItem<int>(
                                        value: m['id'],
                                        child: Text(m['nom']),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _matiereId = value),
                                    validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Classes assignées
                                  const Text(
                                    'Classes assignées',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: widget.classes.map((classe) {
                                        final isSelected = _selectedClasseIds.contains(classe['id']);
                                        return FilterChip(
                                          label: Text(classe['nom']),
                                          selected: isSelected,
                                          onSelected: (_) => _toggleClasseSelection(classe['id']),
                                          backgroundColor: Colors.grey.shade200,
                                          selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
                                          checkmarkColor: const Color(0xFFF47C3C),
                                          labelStyle: TextStyle(
                                            color: isSelected ? const Color(0xFFF47C3C) : Colors.black87,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton d'ajout
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _ajouterProfesseur,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF47C3C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'AJOUTER LE PROFESSEUR',
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