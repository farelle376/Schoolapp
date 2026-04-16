// lib/services/admin_paiement_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/paiement_admin_model.dart';

class AdminPaiementService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminPaiementService() {
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
    } else {
      response = await http.delete(url, headers: headers);
    }

    print('📡 [AdminPaiementService] $method $endpoint -> ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<ClasseInfo>> getClasses() async {
    try {
      final response = await _request('GET', 'paiements/classes');
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

  Future<List<PaiementAdminModel>> getPaiementsByClasseAndTranche(int classeId, int tranche) async {
    try {
      final response = await _request('GET', 'paiements/classe/$classeId/tranche/$tranche');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => PaiementAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getPaiementsByClasseAndTranche: $e');
      return [];
    }
  }

  // Supprimez la méthode telechargerRecu() d'ici - elle n'est plus utilisée
  // Le téléchargement est maintenant géré par PdfService
}