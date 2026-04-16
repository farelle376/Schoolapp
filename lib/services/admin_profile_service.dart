// lib/services/admin_profile_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AdminProfileService {
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }
  
  // Récupérer le profil de l'admin connecté
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/profile');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Get Profile Response: ${response.statusCode}');
      print('Body: ${response.body}');
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Erreur getProfile: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Mettre à jour le profil
  static Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/profile');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Changer le mot de passe
  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/change-password');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Récupérer l'historique des connexions
  static Future<Map<String, dynamic>> getLoginHistory() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Constants.baseUrl}/admin/login-history');
      
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
}