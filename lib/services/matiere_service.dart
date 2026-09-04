// lib/services/matiere_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class MatiereService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  MatiereService() {
    _loadToken();
  }

  // ============================================================
  //  Gestion du token
  // ============================================================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  // ============================================================
  //  Requête HTTP générique
  // ============================================================
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  }) async {
    await _loadToken();

    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      // Uri.replace exige des valeurs String (ou Iterable<String>) : un int
      // brut provoque "type 'int' is not a subtype of type 'Iterable<dynamic>'".
      final stringParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
      url = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: stringParams);
    } else {
      url = Uri.parse('$baseUrl/$endpoint');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(url, headers: headers, body: json.encode(data));
        break;
      case 'PUT':
        response = await http.put(url, headers: headers, body: json.encode(data));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    print('📡 [MatiereService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES PRINCIPALES
  // ============================================================

  /// Récupère toutes les matières, éventuellement filtrées par année scolaire
  Future<Map<String, dynamic>> getMatieres({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'matieres', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ajoute une nouvelle matière
  Future<Map<String, dynamic>> addMatiere(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'matieres', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une matière existante
  Future<Map<String, dynamic>> updateMatiere(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'matieres/$id', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime une matière
  Future<Map<String, dynamic>> deleteMatiere(int id) async {
    try {
      return await _request('DELETE', 'matieres/$id');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getMatieresList({int? anneeScolaireId}) async {
    try {
      final response = await getMatieres(anneeScolaireId: anneeScolaireId);
      
      if (response['success'] == true) {
        final dynamic data = response['data'];
        
        if (data is List) {
          return data.map((m) {
            return {
              'id': m['id'] ?? 0,
              'nom': m['nom']?.toString() ?? '',
              'coefficient': m['coefficient'] ?? 1,
            };
          }).toList();
        } else if (data is int) {
          print('⚠️ getMatieresList: Aucune matière trouvée (data = $data)');
          return [];
        } else {
          print('⚠️ getMatieresList: data n\'est pas une liste (${data.runtimeType})');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMatieresList: $e');
      return [];
    }
  }

  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité avec l'ancien code)
  // ============================================================

  static Future<Map<String, dynamic>> getMatieresStatic({int? anneeScolaireId}) async {
    final service = MatiereService();
    return service.getMatieres(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> addMatiereStatic(Map<String, dynamic> data) async {
    final service = MatiereService();
    return service.addMatiere(data);
  }

  static Future<Map<String, dynamic>> updateMatiereStatic(int id, Map<String, dynamic> data) async {
    final service = MatiereService();
    return service.updateMatiere(id, data);
  }

  static Future<Map<String, dynamic>> deleteMatiereStatic(int id) async {
    final service = MatiereService();
    return service.deleteMatiere(id);
  }
}