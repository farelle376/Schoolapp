// lib/widgets/add_eleve_panel.dart

import 'package:flutter/material.dart';
import '../services/eleve_service.dart';

class AddElevePanel extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final VoidCallback onAdd;

  const AddElevePanel({
    Key? key,
    required this.classes,
    required this.onAdd,
  }) : super(key: key);

  @override
  _AddElevePanelState createState() => _AddElevePanelState();
}

class _AddElevePanelState extends State<AddElevePanel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  String _sexe = 'M';
  int? _classeId;
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
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _ajouterEleve() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'sexe': _sexe == 'M' ? 'Masculin' : 'Feminin',
        'telephone': _telephoneController.text,
        'classe_id': _classeId,
      };

      final response = await EleveService.addEleve(data);

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSnackBar('Élève ajouté avec succès', Colors.green);
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
                                'Ajouter un élève',
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
                                    'Informations de l\'élève',
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
                                  
                                  // Téléphone
                                  TextFormField(
                                    controller: _telephoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Téléphone',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Sexe
                                  DropdownButtonFormField<String>(
                                    value: _sexe,
                                    decoration: InputDecoration(
                                      labelText: 'Sexe',
                                      prefixIcon: const Icon(Icons.wc),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                      DropdownMenuItem(value: 'F', child: Text('Féminin')),
                                    ],
                                    onChanged: (value) => setState(() => _sexe = value!),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Classe
                                  DropdownButtonFormField<int>(
                                    value: _classeId,
                                    decoration: InputDecoration(
                                      labelText: 'Classe',
                                      prefixIcon: const Icon(Icons.class_),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: widget.classes.map<DropdownMenuItem<int>>((c) {
                                      return DropdownMenuItem<int>(
                                        value: c['id'],
                                        child: Text(c['nom']),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _classeId = value),
                                    validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton d'ajout
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _ajouterEleve,
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
                                              'AJOUTER L\'ÉLÈVE',
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