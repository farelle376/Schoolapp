// lib/services/parent_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/parent_model.dart';
import '../model/child_model.dart';

class ParentService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ParentService() {
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

  Future<Map<String, String>> _getHeaders() async {
    await _loadToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
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
      url = Uri.parse('$baseUrl/admin/$endpoint').replace(queryParameters: stringParams);
    } else {
      url = Uri.parse('$baseUrl/admin/$endpoint');
    }

    final headers = await _getHeaders();

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

    print('📡 [ParentService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES PRINCIPALES
  // ============================================================

  /// Récupère la liste des parents avec recherche et pagination
  Future<Map<String, dynamic>> getParents({
    String? search,
    String? type,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null && type.isNotEmpty && type != 'tous') 'type': type,
      };

      final response = await _request('GET', 'admin/parents', queryParams: queryParams);

      final data = response;
      return {
        'success': true,
        'parents': (data['data'] as List)
            .map((json) => ParentModel.fromJson(json))
            .toList(),
        'currentPage': data['current_page'] ?? 1,
        'lastPage': data['last_page'] ?? 1,
        'total': data['total'] ?? 0,
      };
    } catch (e) {
      print('❌ Erreur getParents: $e');
      return {'success': false, 'parents': [], 'message': e.toString()};
    }
  }

  /// Récupère les statistiques
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _request('GET', 'admin/parents/stats');
      return response['data'] ?? {};
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return {};
    }
  }

  /// Crée un parent
  Future<bool> createParent(Map<String, dynamic> parentData) async {
    try {
      final response = await _request('POST', 'admin/parents', data: parentData);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur createParent: $e');
      return false;
    }
  }

  /// Met à jour un parent
  Future<bool> updateParent(int id, Map<String, dynamic> parentData) async {
    try {
      final response = await _request('PUT', 'admin/parents/$id', data: parentData);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur updateParent: $e');
      return false;
    }
  }

  /// Supprime un parent
  Future<bool> deleteParent(int id) async {
    try {
      final response = await _request('DELETE', 'admin/parents/$id');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deleteParent: $e');
      return false;
    }
  }

  // ============================================================
  //  MÉTHODES POUR LES ENFANTS (avec inscriptions)
  // ============================================================

  /// Récupère les enfants d'un parent avec leurs inscriptions actives
  Future<List<ChildModel>> getChildren({
    required int parentId,
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }

      final response = await _request(
        'GET',
        'admin/parents/$parentId/enfants',
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ChildModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getChildren: $e');
      return [];
    }
  }

  /// Récupère les inscriptions d'un enfant spécifique (admin)
  Future<Map<String, dynamic>> getChildInscriptions(int childId) async {
    try {
      return await _request('GET', 'admin/enfants/$childId/inscriptions');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère un parent avec ses enfants (pour l'affichage détaillé)
  Future<Map<String, dynamic>> getParentWithChildren(int parentId, {int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }

      return await _request(
        'GET',
        'admin/parents/$parentId/with-children',
        queryParams: queryParams,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité avec l'existant)
  // ============================================================

  static Future<Map<String, dynamic>> getParentsStatic({
    String? search,
    String? type,
    int page = 1,
  }) async {
    final service = ParentService();
    return service.getParents(search: search, type: type, page: page);
  }

  static Future<Map<String, dynamic>> getStatsStatic() async {
    final service = ParentService();
    return service.getStats();
  }

  static Future<bool> createParentStatic(Map<String, dynamic> parentData) async {
    final service = ParentService();
    return service.createParent(parentData);
  }

  static Future<bool> updateParentStatic(int id, Map<String, dynamic> parentData) async {
    final service = ParentService();
    return service.updateParent(id, parentData);
  }

  static Future<bool> deleteParentStatic(int id) async {
    final service = ParentService();
    return service.deleteParent(id);
  }

  static Future<List<ChildModel>> getChildrenStatic({
    required int parentId,
    int? anneeScolaireId,
  }) async {
    final service = ParentService();
    return service.getChildren(parentId: parentId, anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getChildInscriptionsStatic(int childId) async {
    final service = ParentService();
    return service.getChildInscriptions(childId);
  }

  static Future<Map<String, dynamic>> getParentWithChildrenStatic(int parentId,
      {int? anneeScolaireId}) async {
    final service = ParentService();
    return service.getParentWithChildren(parentId, anneeScolaireId: anneeScolaireId);
  }
}