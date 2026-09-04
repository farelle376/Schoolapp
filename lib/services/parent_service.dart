// lib/services/parent_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/parent_model.dart';
import '../model/child_model.dart';
import '../model/note_model.dart';
import '../model/schedule_model.dart';
import '../model/bulletin_model.dart';
import '../model/tranche_paiement_model.dart';
import '../model/payment_model.dart';

class ParentService {
  final String baseUrl = Constants.baseUrl;
  String? _token;
  final String _mode;

  ParentService({String mode = 'admin'}) : _mode = mode {
    _loadToken();
  }

  // ============================================================
  //  Gestion du token
  // ============================================================
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (_mode == 'admin') {
      _token = prefs.getString('admin_token');
    } else {
      _token = prefs.getString('parent_token');
    }
    print('🔑 [ParentService] Token chargé (mode: $_mode): ${_token != null ? "✅" : "❌"}');
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

    // ✅ Construction de l'URL : /{mode}/{endpoint}
    // Attention : endpoint ne doit PAS contenir 'admin/' ou 'parent/'
    final url = Uri.parse('$baseUrl/$_mode/$endpoint');

    print('📡 [ParentService] $method $url');

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
    } else if (response.statusCode == 401) {
      print('⚠️ Token expiré ou invalide');
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES ADMIN (gestion des parents)
  //  Utilisées par le dashboard admin
  // ============================================================

  /// Récupère la liste des parents avec recherche et pagination
  Future<Map<String, dynamic>> getParents({
    String? search,
    String? type,
    int page = 1,
  }) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      final queryParams = {
        'page': page.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null && type.isNotEmpty && type != 'tous') 'type': type,
      };

      // ✅ endpoint = 'parents' (sans 'admin/')
      final response = await _request('GET', 'parents', queryParams: queryParams);

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
      return {'success': false, 'parents': <ParentModel>[], 'message': e.toString()};
    }
  }

  /// Récupère les statistiques
  Future<Map<String, dynamic>> getStats() async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'parents/stats'
      final response = await _request('GET', 'parents/stats');
      return response['data'] ?? {};
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return {};
    }
  }

  /// Crée un parent
  Future<bool> createParent(Map<String, dynamic> parentData) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'parents'
      final response = await _request('POST', 'parents', data: parentData);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur createParent: $e');
      return false;
    }
  }

  /// Met à jour un parent
  Future<bool> updateParent(int id, Map<String, dynamic> parentData) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'parents/$id'
      final response = await _request('PUT', 'parents/$id', data: parentData);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur updateParent: $e');
      return false;
    }
  }

  /// Supprime un parent
  Future<bool> deleteParent(int id) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'parents/$id'
      final response = await _request('DELETE', 'parents/$id');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deleteParent: $e');
      return false;
    }
  }

  /// Récupère les inscriptions d'un enfant (admin)
  Future<Map<String, dynamic>> getChildInscriptions(int childId) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'enfants/$childId/inscriptions'
      return await _request('GET', 'enfants/$childId/inscriptions');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère un parent avec ses enfants (admin)
  Future<Map<String, dynamic>> getParentWithChildren(int parentId, {int? anneeScolaireId}) async {
    if (_mode != 'admin') {
      throw Exception('Mode admin requis pour cette méthode');
    }
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }

      // ✅ endpoint = 'parents/$parentId/with-children'
      return await _request(
        'GET',
        'parents/$parentId/with-children',
        queryParams: queryParams,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MÉTHODES PARENT (données personnelles)
  //  Utilisées par l'app parent
  // ============================================================

  /// Récupère les enfants du parent connecté
  Future<List<ChildModel>> getMyChildren() async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'children'
      final response = await _request('GET', 'children');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ChildModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMyChildren: $e');
      return [];
    }
  }

  /// Récupère les notes d’un enfant pour un trimestre donné
  Future<Map<String, dynamic>> getMyNotes(int inscriptionId, String trimestre) async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'inscriptions/$inscriptionId/notes'
      return await _request(
        'GET',
        'inscriptions/$inscriptionId/notes',
        queryParams: {'trimestre': trimestre},
      );
    } catch (e) {
      print('❌ Erreur getMyNotes: $e');
      return {'success': false, 'data': []};
    }
  }

  /// Récupère l’emploi du temps d’un enfant
  Future<List<ScheduleModel>> getMySchedule(int inscriptionId) async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'inscriptions/$inscriptionId/schedule'
      final response = await _request('GET', 'inscriptions/$inscriptionId/schedule');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ScheduleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMySchedule: $e');
      return [];
    }
  }

  /// Récupère les bulletins d’un enfant
  Future<List<BulletinModel>> getMyReports(int inscriptionId) async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'inscriptions/$inscriptionId/reports'
      final response = await _request('GET', 'inscriptions/$inscriptionId/reports');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => BulletinModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMyReports: $e');
      return [];
    }
  }

  /// Récupère les tranches de paiement
  Future<List<TranchePaiementModel>> getMyTranchesPaiement(int inscriptionId) async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'inscriptions/$inscriptionId/tranches-paiement'
      final response = await _request('GET', 'inscriptions/$inscriptionId/tranches-paiement');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => TranchePaiementModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMyTranchesPaiement: $e');
      return [];
    }
  }

  /// Récupère l’historique des paiements
  Future<List<PaiementModel>> getMyHistoriquePaiements(int inscriptionId) async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'inscriptions/$inscriptionId/historique-paiements'
      final response = await _request('GET', 'inscriptions/$inscriptionId/historique-paiements');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => PaiementModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMyHistoriquePaiements: $e');
      return [];
    }
  }

  /// Récupère le nombre de notifications non lues
  Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    if (_mode != 'parent') {
      throw Exception('Mode parent requis pour cette méthode');
    }
    try {
      // ✅ endpoint = 'notifications/unread-count'
      return await _request('GET', 'notifications/unread-count');
    } catch (e) {
      return {'success': false, 'count': 0};
    }
  }

  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité)
  // ============================================================

  static Future<Map<String, dynamic>> getParentsStatic({
    String? search,
    String? type,
    int page = 1,
  }) async {
    final service = ParentService(mode: 'admin');
    return service.getParents(search: search, type: type, page: page);
  }

  static Future<Map<String, dynamic>> getStatsStatic() async {
    final service = ParentService(mode: 'admin');
    return service.getStats();
  }

  static Future<bool> createParentStatic(Map<String, dynamic> parentData) async {
    final service = ParentService(mode: 'admin');
    return service.createParent(parentData);
  }

  static Future<bool> updateParentStatic(int id, Map<String, dynamic> parentData) async {
    final service = ParentService(mode: 'admin');
    return service.updateParent(id, parentData);
  }

  static Future<bool> deleteParentStatic(int id) async {
    final service = ParentService(mode: 'admin');
    return service.deleteParent(id);
  }

  static Future<List<ChildModel>> getMyChildrenStatic() async {
    final service = ParentService(mode: 'parent');
    return service.getMyChildren();
  }

  static Future<Map<String, dynamic>> getMyNotesStatic(int inscriptionId, String trimestre) async {
    final service = ParentService(mode: 'parent');
    return service.getMyNotes(inscriptionId, trimestre);
  }

  static Future<List<ScheduleModel>> getMyScheduleStatic(int inscriptionId) async {
    final service = ParentService(mode: 'parent');
    return service.getMySchedule(inscriptionId);
  }
}