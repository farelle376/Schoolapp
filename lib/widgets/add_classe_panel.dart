// lib/widgets/add_classe_panel.dart

import 'package:flutter/material.dart';
import '../services/classmat_service.dart';
import '../model/annee_scolaire_model.dart';

class AddClassePanel extends StatefulWidget {
  final List<Map<String, dynamic>> matieres;
  final List<Map<String, dynamic>> professeurs;
  final List<AnneeScolaire> anneesScolaires;
  final int? initialAnneeId;
  final VoidCallback onAdd;

  const AddClassePanel({
    Key? key,
    required this.matieres,
    required this.professeurs,
    required this.anneesScolaires,
    this.initialAnneeId,
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
  int? _selectedAnneeId;
  Map<int, int?> _professeurParMatiere = {};
  bool _isSaving = false;

  // ✅ Instance du service
  final ClassmatService _service = ClassmatService();

  @override
  void initState() {
    super.initState();

    // Préselectionner l'année en cours transmise par la page parente
    // (plutôt que la plus récemment créée) : sinon une classe ajoutée
    // pendant qu'une année future existe déjà se retrouve enregistrée
    // sous la mauvaise année.
    if (widget.initialAnneeId != null &&
        widget.anneesScolaires.any((a) => a.id == widget.initialAnneeId)) {
      _selectedAnneeId = widget.initialAnneeId;
    } else if (widget.anneesScolaires.isNotEmpty) {
      _selectedAnneeId = widget.anneesScolaires.first.id;
    }

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
        final controller = _coefficientControllers[matiere['id']];
        if (controller != null) {
          controller.dispose();
          _coefficientControllers.remove(matiere['id']);
        }
        _professeurParMatiere.remove(matiere['id']);
      } else {
        _selectedMatieres.add(matiere);
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
        'professeur_id': _professeurParMatiere[m['id']],
      })).toList();

      final response = await _service.addClasse({
        'nom': _nomController.text,
        'annee_scolaire_id': _selectedAnneeId,
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
                                  Icons.class_,
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
                                      'NOUVELLE CLASSE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
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
                                        'Informations de la classe',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Nom de la classe
                                  _buildFormField(
                                    label: 'Nom de la classe',
                                    icon: Icons.class_,
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: _getInputDecoration(),
                                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Année scolaire
                                  _buildFormField(
                                    label: 'Année scolaire',
                                    icon: Icons.calendar_today,
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedAnneeId,
                                      hint: const Text('Sélectionner une année'),
                                      items: widget.anneesScolaires.map((a) {
                                        return DropdownMenuItem<int>(
                                          value: a.id,
                                          child: Text(a.libelle ?? 'Année ${a.id}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _selectedAnneeId = value),
                                      validator: (v) => v == null ? 'Sélectionnez une année' : null,
                                      decoration: _getInputDecoration(),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Titre section matières
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
                                        'Matières assignées',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Matières sélectionnées (Chips)
                                  if (_selectedMatieres.isNotEmpty)
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
                                                'Matières sélectionnées',
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
                                            children: _selectedMatieres.map((matiere) {
                                              return Chip(
                                                label: Text(matiere['nom']),
                                                backgroundColor: const Color(0xFFF47C3C).withOpacity(0.1),
                                                deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFFF47C3C)),
                                                onDeleted: () => _toggleMatiere(matiere),
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

                                  // Liste des matières disponibles
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
                                                'Toutes les matières',
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
                                            children: widget.matieres.map((matiere) {
                                              final isSelected = _selectedMatieres.any((m) => m['id'] == matiere['id']);
                                              return FilterChip(
                                                label: Text(matiere['nom']),
                                                selected: isSelected,
                                                onSelected: (_) => _toggleMatiere(matiere),
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

                                  // Section des coefficients + professeurs
                                  if (_selectedMatieres.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFF47C3C).withOpacity(0.05),
                                            Colors.white,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
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
                                              Container(
                                                width: 3,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF47C3C),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'Coefficients et professeurs',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D2B4E),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // ✅ Un seul bloc : coefficient + professeur filtré par matière
                                          ..._selectedMatieres.map((matiere) {
                                            final profsCompatibles = widget.professeurs
                                                .where((p) => p['matiere_id'] == matiere['id'])
                                                .toList();

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.grey[200]!),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.book,
                                                              size: 14,
                                                              color: const Color(0xFFF47C3C),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                matiere['nom'],
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        flex: 1,
                                                        child: TextFormField(
                                                          controller: _coefficientControllers[matiere['id']],
                                                          keyboardType: TextInputType.number,
                                                          textAlign: TextAlign.center,
                                                          decoration: InputDecoration(
                                                            labelText: 'Coef.',
                                                            labelStyle: const TextStyle(fontSize: 10),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            contentPadding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
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
                                                  const SizedBox(height: 10),
                                                  DropdownButtonFormField<int>(
                                                    value: _professeurParMatiere[matiere['id']],
                                                    hint: Text(
                                                      profsCompatibles.isEmpty
                                                          ? 'Aucun professeur pour cette matière'
                                                          : 'Choisir un professeur',
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                    items: profsCompatibles.map((p) {
                                                      return DropdownMenuItem<int>(
                                                        value: p['id'],
                                                        child: Text(
                                                          p['nom_complet'],
                                                          style: const TextStyle(fontSize: 13),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: profsCompatibles.isEmpty
                                                        ? null
                                                        : (value) => setState(
                                                            () => _professeurParMatiere[matiere['id']] = value),
                                                    validator: (v) => v == null ? 'Professeur requis' : null,
                                                    decoration: InputDecoration(
                                                      labelText: 'Professeur',
                                                      labelStyle: const TextStyle(fontSize: 11),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
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

                                  const SizedBox(height: 32),

                                  // Bouton d'ajout stylisé
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
                                                Icon(Icons.add, color: Colors.white, size: 22),
                                                SizedBox(width: 12),
                                                Text(
                                                  'AJOUTER LA CLASSE',
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