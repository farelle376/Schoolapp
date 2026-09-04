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

    final response = await ProfesseurService.updateProfesseurStatic(
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

  InputDecoration _getInputDecoration({String? hint, Widget? suffixIcon}) {
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
      suffixIcon: suffixIcon,
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
                                      '${widget.professeur['prenom']} ${widget.professeur['nom']}',
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
                        // Body stylisé
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Titre de section
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
                                        'Informations personnelles',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Nom
                                  _buildFormField(
                                    label: 'Nom',
                                    icon: Icons.person,
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Prénom
                                  _buildFormField(
                                    label: 'Prénom',
                                    icon: Icons.person_outline,
                                    child: TextFormField(
                                      controller: _prenomController,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Email
                                  _buildFormField(
                                    label: 'Email',
                                    icon: Icons.email,
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Téléphone
                                  _buildFormField(
                                    label: 'Numéro de téléphone',
                                    icon: Icons.phone,
                                    child: TextFormField(
                                      controller: _numeroController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Matière
                                  _buildFormField(
                                    label: 'Matière enseignée',
                                    icon: Icons.book,
                                    child: DropdownButtonFormField<int>(
                                      value: _matiereId,
                                      hint: const Text('Sélectionner une matière'),
                                      items: widget.matieres.map((m) {
                                        return DropdownMenuItem<int>(
                                          value: m['id'],
                                          child: Text(m['nom']),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _matiereId = value),
                                      validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                                      decoration: _getInputDecoration(),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Bouton d'envoi stylisé
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
                                      onPressed: _isLoading ? null : _updateProfesseur,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
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
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.save, color: Colors.white, size: 22),
                                                SizedBox(width: 12),
                                                Text(
                                                  'MODIFIER LE PROFESSEUR',
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