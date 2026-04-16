// lib/services/admin_bulletin_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/bulletin_admin_model.dart';

class AdminBulletinService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminBulletinService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  Future<Map<String, dynamic>> _request(String method, String endpoint, {Map<String, dynamic>? data}) async {
    await _loadToken();
    
    final url = Uri.parse('$baseUrl/admin/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    http.Response response;
    if (method == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(url, headers: headers, body: json.encode(data));
    } else if (method == 'PUT') {
      response = await http.put(url, headers: headers, body: json.encode(data));
    } else {
      response = await http.delete(url, headers: headers);
    }

    print('📡 [AdminBulletinService] $method $endpoint -> ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // Récupérer toutes les classes
  Future<List<ClasseInfo>> getClasses() async {
    try {
      final response = await _request('GET', 'bulletins/classes');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ClasseInfo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getClasses: $e');
      return [];
    }
  }

  // Récupérer les bulletins par classe et trimestre
  Future<List<BulletinAdminModel>> getBulletinsByClasse(int classeId, String trimestre) async {
    try {
      final response = await _request('GET', 'bulletins/classe/$classeId/trimestre/$trimestre');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => BulletinAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getBulletinsByClasse: $e');
      return [];
    }
  }

  // Récupérer les élèves d'une classe (NOUVEAU)
  Future<List<Map<String, dynamic>>> getElevesByClasse(int classeId) async {
    try {
      final response = await _request('GET', 'bulletins/classe/$classeId/eleves');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('❌ Erreur getElevesByClasse: $e');
      return [];
    }
  }

  // Vérifier si les notes sont disponibles pour un élève
  Future<Map<String, dynamic>> checkNotesDisponibles(int eleveId, String trimestre) async {
    try {
      final response = await _request('GET', 'bulletins/check-notes/$eleveId/$trimestre');
      return response;
    } catch (e) {
      print('❌ Erreur checkNotesDisponibles: $e');
      return {'success': false, 'toutes_disponibles': false, 'details': []};
    }
  }

  // Générer un bulletin pour un élève
  Future<Map<String, dynamic>> generateBulletin(int eleveId, String trimestre) async {
    try {
      final response = await _request('POST', 'bulletins/generate', data: {
        'eleve_id': eleveId,
        'trimestre': trimestre,
      });
      return response;
    } catch (e) {
      print('❌ Erreur generateBulletin: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Récupérer les détails d'un bulletin
  Future<BulletinAdminModel?> getBulletinDetail(int bulletinId) async {
    try {
      final response = await _request('GET', 'bulletins/$bulletinId');
      if (response['success'] == true) {
        return BulletinAdminModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getBulletinDetail: $e');
      return null;
    }
  }

  // Mettre à jour un bulletin
  Future<bool> updateBulletin(int bulletinId, Map<String, dynamic> data) async {
    try {
      final response = await _request('PUT', 'bulletins/$bulletinId', data: data);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur updateBulletin: $e');
      return false;
    }
  }

  // Supprimer un bulletin
  Future<bool> deleteBulletin(int bulletinId) async {
    try {
      final response = await _request('DELETE', 'bulletins/$bulletinId');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deleteBulletin: $e');
      return false;
    }
  }
}