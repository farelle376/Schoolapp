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
  String _sexe = 'M';
  int? _classeId;
  bool _isLoading = false;
  
  // Liste des parents (supports pour 1 ou 2 parents)
  List<Map<String, dynamic>> _parents = [];
  int _nombreParents = 1; // 1 ou 2

  @override
  void initState() {
    super.initState();
    
    // Initialiser avec 1 parent par défaut
    _ajouterParent();
    
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

  void _ajouterParent() {
    setState(() {
      _parents.add({
        'type': 'pere', // 'pere', 'mere', ou 'tuteur'
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

  @override
  void dispose() {
    _controller.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _ajouterEleve() async {
    // Valider le formulaire principal
    if (!_formKey.currentState!.validate()) return;
    
    // Valider les parents
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
      'sexe': _sexe == 'M' ? 'M' : 'F',  // Envoie 'M' ou 'F' comme demandé par l'API
      'classe_id': _classeId,
      'parents': _parents.map((parent) => {
        'type_parent': parent['type'],
        'nom': parent['nom'],
        'prenom': parent['prenom'],
        'telephone': parent['telephone'],
        'email': parent['email'].isEmpty ? null : parent['email'],
      }).toList(),
    };

    print('Données envoyées: $data'); // Pour debug

    final response = await EleveService.addEleve(data);

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
                                  
                                  // Section Parents
                                  const Row(
                                    children: [
                                      Icon(Icons.family_restroom, color: Color(0xFF0D2B4E)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Informations des parents',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Sélecteur du nombre de parents
                                  Row(
                                    children: [
                                      const Text('Nombre de parents:'),
                                      const SizedBox(width: 16),
                                      SegmentedButton<int>(
                                        segments: const [
                                          ButtonSegment(value: 1, label: Text('1 Parent')),
                                          ButtonSegment(value: 2, label: Text('2 Parents')),
                                        ],
                                        selected: {_nombreParents},
                                        onSelectionChanged: (Set<int> selection) {
                                          setState(() {
                                            _nombreParents = selection.first;
                                            // Ajuster le nombre de parents
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
                                  const SizedBox(height: 20),
                                  
                                  // Formulaire pour chaque parent
                                  ...List.generate(_parents.length, (index) {
                                    return _buildParentForm(index);
                                  }),
                                  
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

  Widget _buildParentForm(int index) {
    final parent = _parents[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _supprimerParent(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type de parent
            DropdownButtonFormField<String>(
              value: parent['type'],
              decoration: const InputDecoration(
                labelText: 'Type de parent',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pere', child: Text('Père')),
                DropdownMenuItem(value: 'mere', child: Text('Mère')),
                DropdownMenuItem(value: 'tuteur', child: Text('Tuteur')),
              ],
              onChanged: (value) => _mettreAJourParent(index, 'type', value!),
              validator: (v) => v == null ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            
            // Nom du parent
            TextFormField(
              initialValue: parent['nom'],
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _mettreAJourParent(index, 'nom', value),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            
            // Prénom du parent
            TextFormField(
              initialValue: parent['prenom'],
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _mettreAJourParent(index, 'prenom', value),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            
            // Téléphone
            TextFormField(
              initialValue: parent['telephone'],
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _mettreAJourParent(index, 'telephone', value),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              initialValue: parent['email'],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _mettreAJourParent(index, 'email', value),
            ),
          ],
        ),
      ),
    );
  }
}