// lib/services/classe_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class ClasseService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ClasseService() {
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
  //  Requêtes HTTP
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

    print('📡 [ClasseService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  Méthodes publiques
  // ============================================================

  /// Récupère toutes les classes, éventuellement filtrées par année scolaire
  Future<Map<String, dynamic>> getClasses({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'classes', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ajoute une nouvelle classe
  Future<Map<String, dynamic>> addClasse(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'classes', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une classe existante
  Future<Map<String, dynamic>> updateClasse(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'classes/$id', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getClassesList({int? anneeScolaireId}) async {
    try {
      final response = await getClasses(anneeScolaireId: anneeScolaireId);
      
      if (response['success'] == true) {
        final dynamic data = response['data'];
        
        if (data is List) {
          return data.map((c) {
            String nom = c['nom']?.toString() ?? '';
            return {
              'id': c['id'] ?? 0,
              'nom': nom,
              'nom_complet': nom.isEmpty ? 'Classe ${c['id']}' : nom,
              'effectif': c['effectif'] ?? 0,
            };
          }).toList();
        } else if (data is int) {
          print('⚠️ getClassesList: Aucune classe trouvée (data = $data)');
          return [];
        } else {
          print('⚠️ getClassesList: data n\'est pas une liste (${data.runtimeType})');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur getClassesList: $e');
      return [];
    }
  }

  /// Supprime une classe
  Future<Map<String, dynamic>> deleteClasse(int id) async {
    try {
      return await _request('DELETE', 'classes/$id');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  Méthodes statiques (pour compatibilité avec l'existant)
  // ============================================================

  static Future<Map<String, dynamic>> getClassesStatic({int? anneeScolaireId}) async {
    final service = ClasseService();
    return service.getClasses(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> addClasseStatic(Map<String, dynamic> data) async {
    final service = ClasseService();
    return service.addClasse(data);
  }

  static Future<Map<String, dynamic>> updateClasseStatic(int id, Map<String, dynamic> data) async {
    final service = ClasseService();
    return service.updateClasse(id, data);
  }

  static Future<Map<String, dynamic>> deleteClasseStatic(int id) async {
    final service = ClasseService();
    return service.deleteClasse(id);
  }
}