// lib/services/professeur_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class ProfesseurService {
  // Récupérer tous les professeurs
  static Future<Map<String, dynamic>> getProfesseurs() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/professeurs');
      
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

  // Récupérer les classes (pour le filtre)
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
  // Ajouter un professeur
  static Future<Map<String, dynamic>> addProfesseur(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/professeurs');
      
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
  
  // Modifier un professeur
  static Future<Map<String, dynamic>> updateProfesseur(int professeurId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/professeurs/$professeurId');
      
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
  
  // Supprimer un professeur
  static Future<Map<String, dynamic>> deleteProfesseur(int professeurId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/professeurs/$professeurId');
      
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
  
  // Ajouter des classes à un professeur
  static Future<Map<String, dynamic>> addClassesToProfesseur(int professeurId, List<int> classeIds) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/professeurs/$professeurId/classes');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'classe_ids': classeIds}),
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