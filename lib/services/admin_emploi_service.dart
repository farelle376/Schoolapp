// lib/services/admin_emploi_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/emploi_du_temps_admin_model.dart';

class AdminEmploiService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminEmploiService() {
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

    return json.decode(response.body);
  }


 Future<List<Map<String, dynamic>>> getClasses() async {
  try {
    final response = await _request('GET', 'classes');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((c) {
        String nom = c['nom']?.toString() ?? '';
        return {
          'id': c['id'] ?? 0,
          'nom': nom,
          'nom_complet': nom.isEmpty ? 'Classe ${c['id']}' : nom,
        };
      }).toList();
    }
    return [];
  } catch (e) {
    print('Erreur getClasses: $e');
    return [];
  }
}
  Future<List<Map<String, dynamic>>> getMatieres() async {
    try {
      final response = await _request('GET', 'matieres');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('Erreur getMatieres: $e');
      return [];
    }
  }

 Future<List<Map<String, dynamic>>> getProfesseurs() async {
  try {
    final response = await _request('GET', 'professeurs');
    print('📦 Professeurs response: $response');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      print('📦 Nombre de professeurs: ${data.length}');
      
      return data.map((p) {
        String nom = p['nom']?.toString() ?? '';
        String prenom = p['prenom']?.toString() ?? '';
        String nomComplet = '$prenom $nom'.trim();
        if (nomComplet.isEmpty) nomComplet = 'Professeur ${p['id']}';
        
        return {
          'id': p['id'] ?? 0,
          'nom': nom,
          'prenom': prenom,
          'nom_complet': nomComplet,
        };
      }).toList();
    }
    return [];
  } catch (e) {
    print('❌ Erreur getProfesseurs: $e');
    return [];
  }
}
 
Future<bool> createEmploi(Map<String, dynamic> data) async {
  try {
    print('🟢 Création emploi avec données: $data');
    
    final cleanedData = {
      'classe_id': data['classe_id'],
      'matiere_id': data['matiere_id'],
      'professeur_id': data['professeur_id'],
      'jour': data['jour'],
      'heure_debut': data['heure_debut'],
      'heure_fin': data['heure_fin'],
      'type_cours': data['type_cours'],
      'est_active': data['est_active'] ?? true,
    };
    
    print('📦 Données nettoyées: $cleanedData');
    
    final response = await _request('POST', 'emplois-du-temps', data: cleanedData);
    
    print('📥 Réponse création: $response');
    
    if (response['success'] == true) {
      print('✅ Emploi créé avec succès');
      return true;
    } else {
      print('❌ Erreur création: ${response['message']}');
      return false;
    }
  } catch (e) {
    print('❌ Exception createEmploi: $e');
    return false;
  }
}

Future<List<EmploiDuTempsAdminModel>> getEmplois({int? classeId}) async {
  try {
    String url = 'emplois-du-temps';
    if (classeId != null) url += '?classe_id=$classeId';
    
    print('🟢 Récupération emplois: $url');
    
    final response = await _request('GET', url);
    
    print('📥 Réponse emplois: ${response['success']}');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      print('📦 Nombre d\'emplois: ${data.length}');
      
      if (data.isNotEmpty) {
        print('📦 Premier emploi exemple: ${data[0]}');
      }
      
      return data.map((json) => EmploiDuTempsAdminModel.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    print('❌ Erreur getEmplois: $e');
    return [];
  }
}
  Future<bool> updateEmploi(int id, Map<String, dynamic> data) async {
    try {
      final response = await _request('PUT', 'emplois-du-temps/$id', data: data);
      return response['success'] == true;
    } catch (e) {
      print('Erreur updateEmploi: $e');
      return false;
    }
  }

  Future<bool> deleteEmploi(int id) async {
    try {
      final response = await _request('DELETE', 'emplois-du-temps/$id');
      return response['success'] == true;
    } catch (e) {
      print('Erreur deleteEmploi: $e');
      return false;
    }
  }

  Future<bool> toggleActive(int id) async {
    try {
      final response = await _request('PATCH', 'emplois-du-temps/$id/toggle');
      return response['success'] == true;
    } catch (e) {
      print('Erreur toggleActive: $e');
      return false;
    }
  }
}