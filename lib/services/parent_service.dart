// lib/services/parent_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/parent_model.dart';

class ParentService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ParentService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    await _loadToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  /// Récupérer la liste des parents avec recherche et pagination
  Future<Map<String, dynamic>> getParents({
    String? search,
    String? type,
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      
      String url = '$baseUrl/admin/parents?page=$page';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      if (type != null && type.isNotEmpty && type != 'tous') {
        url += '&type=$type';
      }
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📡 GET Parents: $url');
      print('📥 Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'parents': (data['data'] as List)
              .map((json) => ParentModel.fromJson(json))
              .toList(),
          'currentPage': data['current_page'] ?? 1,
          'lastPage': data['last_page'] ?? 1,
          'total': data['total'] ?? 0,
        };
      } else {
        return {'success': false, 'parents': [], 'message': 'Erreur ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Erreur getParents: $e');
      return {'success': false, 'parents': [], 'message': e.toString()};
    }
  }

  /// Récupérer les statistiques
  Future<Map<String, dynamic>> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/parents/stats'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return {};
    }
  }

  /// Créer un parent
  Future<bool> createParent(Map<String, dynamic> parentData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/parents'),
        headers: headers,
        body: json.encode(parentData),
      );
      
      print('📡 POST Parent: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Erreur createParent: $e');
      return false;
    }
  }

  /// Modifier un parent
  Future<bool> updateParent(int id, Map<String, dynamic> parentData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/parents/$id'),
        headers: headers,
        body: json.encode(parentData),
      );
      
      print('📡 PUT Parent: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur updateParent: $e');
      return false;
    }
  }

  /// Supprimer un parent
  Future<bool> deleteParent(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/parents/$id'),
        headers: headers,
      );
      
      print('📡 DELETE Parent: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur deleteParent: $e');
      return false;
    }
  }
}