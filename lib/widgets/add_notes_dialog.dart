// lib/widgets/add_notes_dialog.dart

import 'package:flutter/material.dart';

class AddNotesDialog extends StatefulWidget {
  final int classeId;
  final String className;
  final List<Map<String, dynamic>> eleves;
  final Function(Map<String, dynamic>) onSave;

  const AddNotesDialog({
    Key? key,
    required this.classeId,
    required this.className,
    required this.eleves,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddNotesDialogState createState() => _AddNotesDialogState();
}

class _AddNotesDialogState extends State<AddNotesDialog> {
  String _typeNote = 'interrogation';
  String _trimestre = '1';
  String _codeSecret = '';
  Map<int, TextEditingController> _noteControllers = {};
  bool _isSubmitting = false;
  bool _showCodeError = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.eleves.length; i++) {
      _noteControllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ✅ Fonction pour raccourcir le nom
  String _getShortName(String fullName) {
    if (fullName.length > 25) {
      return fullName.substring(0, 22) + '...';
    }
    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Raccourcir le nom de la classe
    String shortClassName = widget.className;
    if (shortClassName.length > 20) {
      shortClassName = shortClassName.substring(0, 18) + '...';
    }

    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 650),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0D2B4E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Saisie des notes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Classe: $shortClassName',
                    style: TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section type de note et trimestre
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  title: Text('Interrogation', style: TextStyle(fontWeight: FontWeight.w500)),
                                  value: 'interrogation',
                                  groupValue: _typeNote,
                                  onChanged: (value) => setState(() => _typeNote = value.toString()),
                                  activeColor: Color(0xFFF47C3C),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile(
                                  title: Text('Devoir', style: TextStyle(fontWeight: FontWeight.w500)),
                                  value: 'devoir',
                                  groupValue: _typeNote,
                                  onChanged: (value) => setState(() => _typeNote = value.toString()),
                                  activeColor: Color(0xFFF47C3C),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Trimestre', style: TextStyle(fontWeight: FontWeight.w500)),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButton(
                                  value: _trimestre,
                                  items: ['1', '2', '3'].map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('Trimestre $t'),
                                  )).toList(),
                                  onChanged: (value) => setState(() => _trimestre = value.toString()),
                                  underline: SizedBox(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Liste des élèves
                    Text(
                      'Notes des élèves',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E)),
                    ),
                    SizedBox(height: 8),
                    
                    ...List.generate(widget.eleves.length, (index) {
                      final eleve = widget.eleves[index];
                      // ✅ Raccourcir le nom de l'élève
                      final shortName = _getShortName(eleve['full_name'] ?? 'Élève');
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shortName,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Matricule: ${eleve['matricule'] ?? 'Non défini'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _noteControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Note',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    SizedBox(height: 20),
                    
                    // Section code secret
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showCodeError ? Colors.red : Colors.orange.shade200,
                          width: _showCodeError ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lock, color: _showCodeError ? Colors.red : Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Validation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _showCodeError ? Colors.red : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Entrez votre code secret pour valider l\'enregistrement des notes',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            obscureText: true,
                            onChanged: (value) {
                              setState(() {
                                _codeSecret = value;
                                _showCodeError = false;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Code secret',
                              hintText: 'Votre code personnel',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              errorText: _showCodeError ? 'Code incorrect' : null,
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Annuler'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF47C3C),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('VALIDER LES NOTES'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitNotes() {
    if (_codeSecret.isEmpty) {
      setState(() => _showCodeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer votre code secret'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_codeSecret.length < 4) {
      setState(() => _showCodeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code secret trop court (minimum 4 caractères)'), backgroundColor: Colors.orange),
      );
      return;
    }

    List<Map<String, dynamic>> notes = [];
    bool hasEmptyNote = false;
    
    for (int i = 0; i < widget.eleves.length; i++) {
      final noteText = _noteControllers[i]!.text.trim();
      if (noteText.isNotEmpty) {
        final note = double.tryParse(noteText);
        if (note != null && note >= 0 && note <= 20) {
          notes.add({
            'eleve_id': widget.eleves[i]['id'],
            'note': note,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note invalide pour ${widget.eleves[i]['full_name']} (0-20)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        hasEmptyNote = true;
      }
    }

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucune note saisie'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous allez enregistrer ${notes.length} note(s) pour ${widget.className}'),
            if (hasEmptyNote)
              Text(
                '⚠️ ${widget.eleves.length - notes.length} élève(s) sans note seront ignorés',
                style: TextStyle(color: Colors.orange),
              ),
            SizedBox(height: 10),
            Text('Type: ${_typeNote == 'interrogation' ? 'Interrogation' : 'Devoir'}'),
            Text('Trimestre: $_trimestre'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isSubmitting = true);
              widget.onSave({
                'classe_id': widget.classeId,
                'type_note': _typeNote,
                'trimestre': _trimestre,
                'notes': notes,
                'code_secret': _codeSecret,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF47C3C)),
            child: Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }
}