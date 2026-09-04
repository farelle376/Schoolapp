// lib/services/professeur_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class ProfesseurService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ProfesseurService() {
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
      // Uri.replace n'accepte que des String (ou Iterable<String>) comme
      // valeurs de queryParameters. Si on lui passe un int brut (ex: un id),
      // ça lève un TypeError du style "type 'int' is not a subtype of type
      // 'Iterable<dynamic>'". On convertit donc systématiquement en String.
      final stringQueryParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      url = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: stringQueryParams);
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

    print('📡 [ProfesseurService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES SUR LES PROFESSEURS
  // ============================================================

  /// Récupère tous les professeurs, éventuellement filtrés par matière ou année
  Future<Map<String, dynamic>> getProfesseurs({
    int? matiereId,
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (matiereId != null) queryParams['matiere_id'] = matiereId;
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      return await _request('GET', 'admin/professeurs', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ajoute un professeur
  Future<Map<String, dynamic>> addProfesseur(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'admin/professeurs', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour un professeur
  Future<Map<String, dynamic>> updateProfesseur(int professeurId, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'admin/professeurs/$professeurId', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime un professeur
  Future<Map<String, dynamic>> deleteProfesseur(int professeurId) async {
    try {
      return await _request('DELETE', 'admin/professeurs/$professeurId');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MÉTHODES SUR LES CLASSES ET MATIÈRES (pour filtres)
  // ============================================================

  /// Récupère les classes, éventuellement filtrées par année scolaire
  Future<Map<String, dynamic>> getClasses({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      return await _request('GET', 'admin/classes/list', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les matières, éventuellement filtrées par année scolaire
  Future<Map<String, dynamic>> getMatieres({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      return await _request('GET', 'admin/matieres', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  ASSOCIATION PROFESSEUR ↔ CLASSES (avec année)
  // ============================================================

  /// Ajoute des classes à un professeur pour une année donnée (obligatoire)
  Future<Map<String, dynamic>> addClassesToProfesseur(
    int professeurId,
    List<int> classeIds, {
    required int anneeScolaireId,
  }) async {
    try {
      final data = {
        'classe_ids': classeIds,
        'annee_scolaire_id': anneeScolaireId,
      };
      return await _request('POST', 'admin/professeurs/$professeurId/classes', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les classes enseignées par un professeur pour une année donnée
  Future<Map<String, dynamic>> getClassesByProfesseurAndAnnee(
    int professeurId,
    int anneeScolaireId,
  ) async {
    try {
      return await _request(
        'GET',
        'admin/professeurs/$professeurId/classes/annee/$anneeScolaireId',
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère l'emploi du temps d'un professeur pour une année donnée
  Future<Map<String, dynamic>> getEmploiDuTemps(
    int professeurId,
    int anneeScolaireId,
  ) async {
    try {
      return await _request(
        'GET',
        'admin/professeurs/$professeurId/emploi-du-temps',
        queryParams: {'annee_scolaire_id': anneeScolaireId},
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité avec l'ancien code)
  // ============================================================

  static Future<Map<String, dynamic>> getProfesseursStatic({
    int? matiereId,
    int? anneeScolaireId,
  }) async {
    final service = ProfesseurService();
    return service.getProfesseurs(matiereId: matiereId, anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> addProfesseurStatic(Map<String, dynamic> data) async {
    final service = ProfesseurService();
    return service.addProfesseur(data);
  }

  static Future<Map<String, dynamic>> updateProfesseurStatic(
      int professeurId, Map<String, dynamic> data) async {
    final service = ProfesseurService();
    return service.updateProfesseur(professeurId, data);
  }

  static Future<Map<String, dynamic>> deleteProfesseurStatic(int professeurId) async {
    final service = ProfesseurService();
    return service.deleteProfesseur(professeurId);
  }

  static Future<Map<String, dynamic>> getClassesStatic({int? anneeScolaireId}) async {
    final service = ProfesseurService();
    return service.getClasses(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getMatieresStatic({int? anneeScolaireId}) async {
    final service = ProfesseurService();
    return service.getMatieres(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> addClassesToProfesseurStatic(
    int professeurId,
    List<int> classeIds, {
    required int anneeScolaireId,
  }) async {
    final service = ProfesseurService();
    return service.addClassesToProfesseur(
      professeurId,
      classeIds,
      anneeScolaireId: anneeScolaireId,
    );
  }

  static Future<Map<String, dynamic>> getClassesByProfesseurAndAnneeStatic(
    int professeurId,
    int anneeScolaireId,
  ) async {
    final service = ProfesseurService();
    return service.getClassesByProfesseurAndAnnee(professeurId, anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getEmploiDuTempsStatic(
    int professeurId,
    int anneeScolaireId,
  ) async {
    final service = ProfesseurService();
    return service.getEmploiDuTemps(professeurId, anneeScolaireId);
  }
}