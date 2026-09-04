// lib/widgets/add_professeur_panel.dart

import 'package:flutter/material.dart';
import '../services/professeur_service.dart';

class AddProfesseurPanel extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final VoidCallback onAdd;

  const AddProfesseurPanel({
    Key? key,
    required this.matieres,
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
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureCode = true;

  int? _matiereId;
  bool _isLoading = false;

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
    _codeController.dispose();
    super.dispose();
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
      };

      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (_codeController.text.isNotEmpty) {
        data['code'] = _codeController.text;
      }

      final response = await ProfesseurService.addProfesseurStatic(data);

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
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NOUVEAU PROFESSEUR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
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

                                  // Mot de passe
                                  _buildFormField(
                                    label: 'Mot de passe',
                                    icon: Icons.lock,
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: _getInputDecoration(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Code de validation
                                  _buildFormField(
                                    label: 'Code de validation',
                                    icon: Icons.security,
                                    child: TextFormField(
                                      controller: _codeController,
                                      obscureText: _obscureCode,
                                      decoration: _getInputDecoration(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureCode ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureCode = !_obscureCode;
                                            });
                                          },
                                        ),
                                      ),
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
                                      items: widget.matieres.map<DropdownMenuItem<int>>((m) {
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

                                  const SizedBox(height: 16),

                                  // Note informative : l'assignation aux classes se fait ailleurs
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF47C3C).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFF47C3C).withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline, color: Color(0xFFF47C3C), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'L\'assignation de ce professeur à une ou plusieurs classes '
                                            'se fait depuis la gestion des classes, en choisissant '
                                            'le professeur pour chaque matière.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                          ),
                                        ),
                                      ],
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
                                      onPressed: _isLoading ? null : _ajouterProfesseur,
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
                                                Icon(Icons.add, color: Colors.white, size: 22),
                                                SizedBox(width: 12),
                                                Text(
                                                  'AJOUTER LE PROFESSEUR',
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