// lib/widgets/eleve_notes_dialog.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../services/dashboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // ✅ Récupérer l'inscription_id
    final inscriptionId = widget.eleve['inscription_id'];
    if (inscriptionId == null) {
      print('❌ Aucun inscription_id trouvé pour cet élève');
      setState(() {
        _isLoading = false;
        _notes = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger les notes : inscription non trouvée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Utiliser inscription_id au lieu de eleve_id
      final response = await _dashboardService.getEleveNotes(inscriptionId);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur chargement notes: $e');
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

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer cette note (${note['note']}/20) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('professeur_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée, veuillez vous reconnecter'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final url = Uri.parse('${Constants.baseUrl}/professeur/notes/${note['id']}');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note supprimée avec succès'), backgroundColor: Colors.green),
          );
          await _loadNotes();
          widget.onNoteUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('❌ Erreur suppression: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.eleve['full_name'] ?? '${widget.eleve['prenom']} ${widget.eleve['nom']}';
    if (displayName.length > 20) {
      displayName = displayName.substring(0, 18) + '...';
    }
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.grade, color: const Color(0xFFF47C3C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notes de $displayName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grade_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text('Aucune note enregistrée'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final noteValue = _toDouble(note['note']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
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
                            note['type_note'] == 'interrogation' ? 'Interrogation' : 'Devoir',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Trimestre ${note['trimestre']}'),
                              if (note['created_at'] != null)
                                Text(
                                  'Date: ${_formatDate(note['created_at'])}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteNote(note),
                            tooltip: 'Supprimer',
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}