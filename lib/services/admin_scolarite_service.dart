// lib/services/admin_scolarite_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/scolarite_model.dart';

class AdminScolariteService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminScolariteService() {
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
    } else {
      response = await http.post(url, headers: headers, body: json.encode(data));
    }

    return json.decode(response.body);
  }

  Future<List<ClasseInfo>> getClasses() async {
    try {
      final response = await _request('GET', 'scolarite/classes');
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ClasseInfo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur getClasses: $e');
      return [];
    }
  }

  Future<List<ElevePaiementModel>> getElevesByClasseAndTranche(int classeId, int tranche, {bool? paye}) async {
    try {
      String url = 'scolarite/classe/$classeId/tranche/$tranche';
      if (paye != null) url += '?paye=${paye ? '1' : '0'}';
      
      final response = await _request('GET', url);
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ElevePaiementModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur getElevesByClasseAndTranche: $e');
      return [];
    }
  }
}