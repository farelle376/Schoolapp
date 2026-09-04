// lib/widgets/add_eleve_panel.dart

import 'package:flutter/material.dart';
import '../services/eleve_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/annee_scolaire_model.dart'; // Assurez-vous d'avoir importé le modèle

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
  String _sexe = 'M';
  int? _classeId;
  int? _anneeScolaireId;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _parents = [];
  int _nombreParents = 1;
  
  // ✅ Liste des années (pour le dropdown)
  List<Map<String, dynamic>> _anneesScolaires = [];
  bool _isLoadingAnnees = false;
  
  // ✅ Instance du service
  final AnneeScolaireService _anneeService = AnneeScolaireService();

  @override
  void initState() {
    super.initState();
    
    _ajouterParent();
    _chargerAnneesScolaires();

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
      reverseCurve: Curves.easeInCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _chargerAnneesScolaires() async {
    setState(() => _isLoadingAnnees = true);
    try {
      // ✅ Appel de la méthode d'instance (pas de Static)
      final annees = await _anneeService.getAnneesScolaires();
      
      // ✅ Conversion en List<Map> pour le dropdown
      final List<Map<String, dynamic>> anneesMap = annees.map((annee) {
        return {
          'id': annee.id,
          'libelle': annee.libelle ?? 'Année ${annee.id}',
          'est_encours': false, // On n'a pas cette info ici, mais ce n'est pas grave
        };
      }).toList();
      
      setState(() {
        _anneesScolaires = anneesMap;
        // Sélectionner l'année par défaut (la plus récente ou via un autre critère)
        if (_anneesScolaires.isNotEmpty) {
          // Par défaut, prendre la première (qui est la plus récente si triée)
          _anneeScolaireId = _anneesScolaires.first['id'];
        }
      });
      
      // Optionnel : essayer de récupérer l'année en cours pour la sélectionner par défaut
      final anneeEnCours = await _anneeService.getAnneeEnCours();
      if (anneeEnCours != null) {
        final exists = _anneesScolaires.any((a) => a['id'] == anneeEnCours.id);
        if (exists) {
          setState(() {
            _anneeScolaireId = anneeEnCours.id;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement années: $e');
    } finally {
      setState(() => _isLoadingAnnees = false);
    }
  }

  void _ajouterParent() {
    setState(() {
      _parents.add({
        'type': 'pere',
        'nom': '',
        'prenom': '',
        'telephone': '',
        'email': '',
      });
    });
  }

  void _supprimerParent(int index) {
    setState(() {
      _parents.removeAt(index);
    });
  }

  void _mettreAJourParent(int index, String champ, String valeur) {
    setState(() {
      _parents[index][champ] = valeur;
    });
  }

  Future<void> _ajouterEleve() async {
    if (!_formKey.currentState!.validate()) return;
    
    for (int i = 0; i < _parents.length; i++) {
      final parent = _parents[i];
      if (parent['nom'].isEmpty || 
          parent['prenom'].isEmpty || 
          parent['telephone'].isEmpty) {
        _showSnackBar('Veuillez remplir tous les champs du parent ${i+1}', Colors.red);
        return;
      }
    }
    
    setState(() => _isLoading = true);

    final data = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'sexe': _sexe == 'M' ? 'M' : 'F',
      'classe_id': _classeId,
      'annee_scolaire_id': _anneeScolaireId, // ✅ Envoi de l'année
      'parents': _parents.map((parent) => {
        'type_parent': parent['type'],
        'nom': parent['nom'],
        'prenom': parent['prenom'],
        'telephone': parent['telephone'],
        'email': parent['email'].isEmpty ? null : parent['email'],
      }).toList(),
    };

    print('📤 Données envoyées: $data');

    final response = await EleveService.addEleveStatic(data);

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      _showSnackBar('Élève ajouté avec succès', Colors.green);
      await _controller.reverse();
      widget.onAdd();
      if (mounted) Navigator.pop(context);
    } else {
      _showSnackBar(response['message'] ?? 'Erreur lors de l\'ajout', Colors.red);
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
                        // Header (inchangé)
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
                                      'NOUVEL ÉLÈVE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
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
                                  // Titre section informations élève
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
                                        'Informations de l\'élève',
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
                                  
                                  // Sexe
                                  _buildFormField(
                                    label: 'Sexe',
                                    icon: Icons.wc,
                                    child: DropdownButtonFormField<String>(
                                      value: _sexe,
                                      items: const [
                                        DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                        DropdownMenuItem(value: 'F', child: Text('Féminin')),
                                      ],
                                      onChanged: (value) => setState(() => _sexe = value!),
                                      decoration: _getInputDecoration(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Classe
                                  _buildFormField(
                                    label: 'Classe',
                                    icon: Icons.class_,
                                    child: DropdownButtonFormField<int>(
                                      value: _classeId,
                                      hint: const Text('Sélectionner une classe'),
                                      items: widget.classes.map<DropdownMenuItem<int>>((c) {
                                        return DropdownMenuItem<int>(
                                          value: c['id'],
                                          child: Text(c['nom']),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _classeId = value),
                                      validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                                      decoration: _getInputDecoration(),
                                    ),
                                  ),
                                  
                                  // ✅ Année scolaire (nouveau champ)
                                  const SizedBox(height: 16),
                                  _buildFormField(
                                    label: 'Année scolaire',
                                    icon: Icons.calendar_today,
                                    child: _isLoadingAnnees
                                        ? const CircularProgressIndicator()
                                        : DropdownButtonFormField<int>(
                                            value: _anneeScolaireId,
                                            hint: const Text('Sélectionner une année'),
                                            items: _anneesScolaires.map<DropdownMenuItem<int>>((a) {
                                              return DropdownMenuItem<int>(
                                                value: a['id'],
                                                child: Text(a['libelle'] ?? 'Année ${a['id']}'),
                                              );
                                            }).toList(),
                                            onChanged: (value) => setState(() => _anneeScolaireId = value),
                                            validator: (v) => v == null ? 'Sélectionnez une année' : null,
                                            decoration: _getInputDecoration(),
                                          ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Titre section parents (inchangé)
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
                                        'Informations des parents',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2B4E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Sélecteur du nombre de parents (inchangé)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.family_restroom, color: Color(0xFFF47C3C), size: 20),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Nombre de parents:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0D2B4E),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SegmentedButton<int>(
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                                              if (states.contains(MaterialState.selected)) {
                                                return const Color(0xFFF47C3C);
                                              }
                                              return Colors.grey[200];
                                            }),
                                            foregroundColor: MaterialStateProperty.resolveWith((states) {
                                              if (states.contains(MaterialState.selected)) {
                                                return Colors.white;
                                              }
                                              return Colors.grey[700];
                                            }),
                                          ),
                                          segments: const [
                                            ButtonSegment(value: 1, label: Text('1 Parent')),
                                            ButtonSegment(value: 2, label: Text('2 Parents')),
                                          ],
                                          selected: {_nombreParents},
                                          onSelectionChanged: (Set<int> selection) {
                                            setState(() {
                                              _nombreParents = selection.first;
                                              while (_parents.length < _nombreParents) {
                                                _ajouterParent();
                                              }
                                              while (_parents.length > _nombreParents) {
                                                _parents.removeLast();
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Formulaire pour chaque parent (inchangé)
                                  ...List.generate(_parents.length, (index) {
                                    return _buildParentForm(index);
                                  }),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Bouton d'ajout
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
                                      onPressed: _isLoading ? null : _ajouterEleve,
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
                                                  'AJOUTER L\'ÉLÈVE',
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

  // Formulaire pour chaque parent (inchangé)
  Widget _buildParentForm(int index) {
    final parent = _parents[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF47C3C).withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF47C3C).withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF47C3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: const Color(0xFFF47C3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Parent ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B4E),
                    ),
                  ),
                ),
                if (_parents.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _supprimerParent(index),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type de parent
            _buildFormField(
              label: 'Type de parent',
              icon: Icons.family_restroom,
              child: DropdownButtonFormField<String>(
                value: parent['type'],
                items: const [
                  DropdownMenuItem(value: 'pere', child: Text('Père')),
                  DropdownMenuItem(value: 'mere', child: Text('Mère')),
                  DropdownMenuItem(value: 'tuteur', child: Text('Tuteur')),
                ],
                onChanged: (value) => _mettreAJourParent(index, 'type', value!),
                validator: (v) => v == null ? 'Champ requis' : null,
                decoration: _getInputDecoration(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Nom du parent
            _buildFormField(
              label: 'Nom',
              icon: Icons.person_outline,
              child: TextFormField(
                initialValue: parent['nom'],
                decoration: _getInputDecoration(),
                onChanged: (value) => _mettreAJourParent(index, 'nom', value),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 12),
            
            // Prénom du parent
            _buildFormField(
              label: 'Prénom',
              icon: Icons.person_outline,
              child: TextFormField(
                initialValue: parent['prenom'],
                decoration: _getInputDecoration(),
                onChanged: (value) => _mettreAJourParent(index, 'prenom', value),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 12),
            
            // Téléphone
            _buildFormField(
              label: 'Téléphone',
              icon: Icons.phone,
              child: TextFormField(
                initialValue: parent['telephone'],
                keyboardType: TextInputType.phone,
                decoration: _getInputDecoration(),
                onChanged: (value) => _mettreAJourParent(index, 'telephone', value),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 12),
            
            // Email
            _buildFormField(
              label: 'Email',
              icon: Icons.email,
              child: TextFormField(
                initialValue: parent['email'],
                keyboardType: TextInputType.emailAddress,
                decoration: _getInputDecoration(),
                onChanged: (value) => _mettreAJourParent(index, 'email', value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}