// lib/services/parent_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ParentService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ParentService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('parent_token');
    print('🔑 [ParentService] Token chargé: ${_token != null ? "Oui" : "Non"}');
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    await _loadToken();
    
    final url = Uri.parse('$baseUrl/parent/$endpoint');
    print('📡 GET: $url');
    print('🔑 Token: ${_token != null ? "Présent" : "Absent"}');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    
    print('📥 Response: ${response.statusCode}');
    print('📄 Body: ${response.body}');
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getChildren() async {
    try {
      final response = await _get('children');
      if (response['success'] == true) {
        print('✅ Enfants récupérés: ${response['data'].length}');
        return response['data'];
      }
      return [];
    } catch (e) {
      print('❌ Erreur getChildren: $e');
      return [];
    }
  }
}