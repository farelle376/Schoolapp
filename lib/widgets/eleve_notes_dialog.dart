// lib/widgets/eleve_notes_dialog.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../services/dashboard_service.dart';

class EleveNotesDialog extends StatefulWidget {
  final Map<String, dynamic> eleve;
  final int professeurId;
  final Function onNoteUpdated;

  const EleveNotesDialog({
    Key? key,
    required this.eleve,
    required this.professeurId,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  _EleveNotesDialogState createState() => _EleveNotesDialogState();
}

class _EleveNotesDialogState extends State<EleveNotesDialog> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _dashboardService.setProfesseurId(widget.professeurId);
    _loadNotes();
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
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.grade, color: Color(0xFFF47C3C)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notes de $displayName',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: 400),
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
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final noteValue = _toDouble(note['note']);
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getNoteColor(noteValue).withOpacity(0.1),
                            child: Text(
                              noteValue.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getNoteColor(noteValue),
                              ),
                            ),
                          ),
                          title: Text(
                          note['type_note'] == 'interrogation' ? 'Interro' : 'Devoir',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                       ),
                          subtitle: Text('Trimestre ${note['trimestre']}'),
                          trailing: note['is_validated'] == true
                              ? Chip(
                                  label: Text('Validé', style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.green.shade100,
                                )
                              : Chip(
                                  label: Text('En attente', style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.orange.shade100,
                                ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer'),
        ),
      ],
    );
  }
}