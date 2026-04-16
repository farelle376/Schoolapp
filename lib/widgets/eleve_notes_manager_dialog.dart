// lib/widgets/eleve_notes_manager_dialog.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../services/dashboard_service.dart';

class EleveNotesManagerDialog extends StatefulWidget {
  final Map<String, dynamic> eleve;
  final int professeurId;
  final int matiereId;
  final Function onNoteUpdated;

  const EleveNotesManagerDialog({
    Key? key,
    required this.eleve,
    required this.professeurId,
    required this.matiereId,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  _EleveNotesManagerDialogState createState() => _EleveNotesManagerDialogState();
}

class _EleveNotesManagerDialogState extends State<EleveNotesManagerDialog> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  bool _isEditing = false;
  Map<int, TextEditingController> _editControllers = {};
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _dashboardService.setProfesseurId(widget.professeurId);
    _loadNotes();
  }

  @override
  void dispose() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dashboardService.getEleveNotes(widget.eleve['id']);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement notes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNote(int noteId, double newValue) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/professeur/notes/$noteId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'note': newValue,
          'professeur_id': widget.professeurId,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        await _loadNotes();
        widget.onNoteUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note modifiée avec succès'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Erreur update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion'), backgroundColor: Colors.red),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color _getNoteColor(double note) {
    if (note >= 16) return Colors.green;
    if (note >= 14) return Colors.lightGreen;
    if (note >= 12) return Colors.orange;
    if (note >= 10) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Raccourcir le nom pour l'affichage
    String displayName = widget.eleve['full_name'] ?? '${widget.eleve['prenom']} ${widget.eleve['nom']}';
    if (displayName.length > 20) {
      displayName = displayName.substring(0, 18) + '...';
    }
    
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 500),
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
              child: Row(
                children: [
                  Icon(Icons.school, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Gestion des notes',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Contenu
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grade_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Aucune note enregistrée'),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.add),
                                label: Text('Ajouter une note'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF47C3C),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final noteValue = _toDouble(note['note']);
                            
                            final isEditing = _editControllers[index] != null;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: note['type_note'] == 'interrogation' 
                                                ? Colors.blue.shade50 
                                                : Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            note['type_note'] == 'interrogation' ? 'Interrogation' : 'Devoir',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: note['type_note'] == 'interrogation' 
                                                  ? Colors.blue 
                                                  : Colors.purple,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'T${note['trimestre']}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Spacer(),
                                        if (!_isEditing || !isEditing)
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 20, color: Color(0xFFF47C3C)),
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                                _editControllers[index] = TextEditingController(
                                                  text: noteValue.toString(),
                                                );
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    if (isEditing && _editControllers[index] != null)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _editControllers[index],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Note',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.check, color: Colors.green),
                                            onPressed: () async {
                                              final newValue = double.tryParse(_editControllers[index]!.text);
                                              if (newValue != null && newValue >= 0 && newValue <= 20) {
                                                await _updateNote(note['id'], newValue);
                                                setState(() {
                                                  _editControllers.remove(index);
                                                  _isEditing = false;
                                                });
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Note invalide (0-20)'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _editControllers[index]?.dispose();
                                                _editControllers.remove(index);
                                                _isEditing = false;
                                              });
                                            },
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundColor: _getNoteColor(noteValue).withOpacity(0.1),
                                            child: Text(
                                              noteValue.toString(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _getNoteColor(noteValue),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  note['type_note'] == 'interrogation' ? 'Interrogation' : 'Devoir',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  'Trimestre ${note['trimestre']}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                                if (note['date'] != null)
                                                  Text(
                                                    'Date: ${note['date']}',
                                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (note['is_validated'] == true)
                                            Chip(
                                              label: Text('Validé', style: TextStyle(fontSize: 10)),
                                              backgroundColor: Colors.green.shade100,
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}