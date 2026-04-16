// lib/services/eleve_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class EleveService {
  // Récupérer toutes les classes

static Future<Map<String, dynamic>> getClasses() async {
  try {
    final token = await _getToken();
    print('=== ELEVE SERVICE ===');
    print('Token: $token');
    
    if (token == null) {
      print('ERREUR: Token null');
      return {'success': false, 'message': 'Non authentifié'};
    }
    
    // ✅ Utilise la bonne URL (sans /admin)
    final url = Uri.parse('${Constants.baseUrl}/classes');
    print('URL: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('Status code: ${response.statusCode}');
    print('Réponse: ${response.body}');
    
    if (response.statusCode == 401) {
      return {'success': false, 'message': 'Session expirée'};
    }
    
    return jsonDecode(response.body);
  } catch (e) {
    print('Erreur getClasses: $e');
    return {'success': false, 'message': e.toString()};
  }
}
  
  // Récupérer les élèves d'une classe

static Future<Map<String, dynamic>> getElevesByClasse(int classeId) async {
  try {
    final token = await _getToken();
    // ✅ Utilise la bonne route
    final url = Uri.parse('${Constants.baseUrl}/classes/$classeId/eleves');
    
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

  // Ajouter un élève
  static Future<Map<String, dynamic>> addEleve(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/eleves');
      
      final response = await http.post(
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
  
  // Modifier un élève
  static Future<Map<String, dynamic>> updateEleve(int eleveId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/eleves/$eleveId');
      
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
  
  // Supprimer un élève
  static Future<Map<String, dynamic>> deleteEleve(int eleveId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/eleves/$eleveId');
      
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
  
  // Récupérer le token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }
}