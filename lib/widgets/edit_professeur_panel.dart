// lib/widgets/edit_professeur_panel.dart

import 'package:flutter/material.dart';
import '../services/professeur_service.dart';

class EditProfesseurPanel extends StatefulWidget {
  final Map<String, dynamic> professeur;
  final List<Map<String, dynamic>> matieres;
  final VoidCallback onUpdate;

  const EditProfesseurPanel({
    Key? key,
    required this.professeur,
    required this.matieres,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _EditProfesseurPanelState createState() => _EditProfesseurPanelState();
}

class _EditProfesseurPanelState extends State<EditProfesseurPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroController = TextEditingController();
  int? _matiereId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nomController.text = widget.professeur['nom'] ?? '';
    _prenomController.text = widget.professeur['prenom'] ?? '';
    _emailController.text = widget.professeur['email'] ?? '';
    _numeroController.text = widget.professeur['numero'] ?? '';
    _matiereId = widget.professeur['matiere_id'];

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
    _prenomController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _updateProfesseur() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_matiereId == null) {
      _showSnackBar('Veuillez sélectionner une matière', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final response = await ProfesseurService.updateProfesseur(
      widget.professeur['id'],
      {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'email': _emailController.text,
        'numero': _numeroController.text,
        'matiere_id': _matiereId,
      },
    );

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      _showSnackBar('Professeur modifié avec succès', Colors.green);
      await _controller.reverse();
      widget.onUpdate();
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(response['message'] ?? 'Erreur lors de la modification', Colors.red);
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
                                'Modifier le professeur',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Body
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
                                      child: Icon(Icons.person, size: 50, color: Colors.white),
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
                                  // Numéro
                                  TextFormField(
                                    controller: _numeroController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Téléphone',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
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
                                    items: widget.matieres.map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m['id'],
                                        child: Text(m['nom']),
                                      );
                                    }).toList(),
                                    onChanged: (value) => setState(() => _matiereId = value),
                                    validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                                  ),
                                  const SizedBox(height: 30),
                                  // Bouton
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _updateProfesseur,
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
                                              'ENREGISTRER',
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