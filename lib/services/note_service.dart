// lib/services/note_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class NoteService {
  // Récupérer toutes les notes (avec filtres optionnels)
  static Future<Map<String, dynamic>> getNotes({
    int? classeId,
    int? matiereId,
    int? trimestre,
  }) async {
    try {
      final token = await _getToken();
      String url = '${Constants.baseUrl}/admin/notes';
      
      print('📊 Token: $token');
    print('📊 URL: $url');
    
      // Ajouter les paramètres de filtre
      List<String> params = [];
      if (classeId != null) params.add('classe_id=$classeId');
      if (matiereId != null) params.add('matiere_id=$matiereId');
      if (trimestre != null) params.add('trimestre=$trimestre');
      if (params.isNotEmpty) url += '?' + params.join('&');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Récupérer les statistiques des notes
  static Future<Map<String, dynamic>> getNotesStats() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/notes/stats');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Récupérer les classes
  static Future<Map<String, dynamic>> getClasses() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/classes/list');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Récupérer les matières
  static Future<Map<String, dynamic>> getMatieres() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/matieres');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

// Supprimer une note
static Future<Map<String, dynamic>> deleteNote(int noteId) async {
  try {
    final token = await _getToken();
    final url = Uri.parse('${Constants.baseUrl}/admin/notes/$noteId');
    
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

// Modifier une note
static Future<Map<String, dynamic>> updateNote(int noteId, Map<String, dynamic> data) async {
  try {
    final token = await _getToken();
    final url = Uri.parse('${Constants.baseUrl}/admin/notes/$noteId');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }
}