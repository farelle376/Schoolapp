// lib/services/eleve_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class EleveService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  EleveService() {
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
  //  Requête HTTP générique avec préfixe optionnel
  // ============================================================
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    bool useAdminPrefix = true, // ✅ Ajout du paramètre
  }) async {
    await _loadToken();

    final String urlPrefix = useAdminPrefix ? '$baseUrl/admin/' : '$baseUrl/';
    Uri url;
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
      url = Uri.parse('$urlPrefix$endpoint').replace(queryParameters: stringParams);
    } else {
      url = Uri.parse('$urlPrefix$endpoint');
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

    print('📡 [EleveService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES D'INSTANCE
  // ============================================================

  // -------------------- ADMIN (avec préfixe) --------------------

  /// Récupère toutes les classes (permanentes) – admin
  Future<Map<String, dynamic>> getClasses() async {
    try {
      return await _request('GET', 'classes');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère tous les élèves avec leurs inscriptions actives – admin
  Future<Map<String, dynamic>> getAllEleves({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'eleves', queryParams: queryParams, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les élèves d'une classe annuelle (classe + année) – admin
  Future<Map<String, dynamic>> getElevesByClasse(int classeId, {required int anneeScolaireId}) async {
    try {
      final queryParams = {'annee_scolaire_id': anneeScolaireId};
      return await _request('GET', 'classes/$classeId/eleves', queryParams: queryParams, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère tous les élèves avec leurs classes (export) – admin
  Future<Map<String, dynamic>> getAllElevesWithClasses({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'eleves/complet', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Ajoute un élève (et son inscription) – admin
  Future<Map<String, dynamic>> addEleve(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'eleves', data: data, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour un élève (et éventuellement son inscription) – admin
  Future<Map<String, dynamic>> updateEleve(int eleveId, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'eleves/$eleveId', data: data, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime un élève – admin
  Future<Map<String, dynamic>> deleteEleve(int eleveId) async {
    try {
      return await _request('DELETE', 'eleves/$eleveId', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère la classe actuelle d'un élève – admin
  Future<Map<String, dynamic>> getClasseActuelle(int eleveId) async {
    try {
      return await _request('GET', 'eleves/$eleveId/classe-actuelle');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Passe un élève en classe supérieure – admin
  Future<Map<String, dynamic>> passerEnClasseSuperieure({
    required int eleveId,
    required int nouvelleClasseId,
    required int nouvelleAnneeScolaireId,
  }) async {
    try {
      final data = {
        'nouvelle_classe_id': nouvelleClasseId,
        'nouvelle_annee_scolaire_id': nouvelleAnneeScolaireId,
      };
      return await _request('POST', 'eleves/$eleveId/passer-classe', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------- PUBLIC (sans préfixe) --------------------

  /// Récupère toutes les années scolaires – public
  Future<Map<String, dynamic>> getAnneesScolaires() async {
    try {
      return await _request('GET', 'annees-scolaires', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère l'année scolaire en cours – public
  Future<Map<String, dynamic>> getAnneeScolaireEnCours() async {
    try {
      return await _request('GET', 'annees-scolaires/en-cours', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère toutes les inscriptions (avec filtres) – public
  Future<Map<String, dynamic>> getInscriptions({
    int? eleveId,
    int? classeId,
    int? anneeScolaireId,
    String? statut,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (eleveId != null) queryParams['eleve_id'] = eleveId;
      if (classeId != null) queryParams['classe_id'] = classeId;
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      if (statut != null) queryParams['statut'] = statut;
      return await _request('GET', 'inscriptions', queryParams: queryParams, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère une inscription par son ID – public
  Future<Map<String, dynamic>> getInscription(int id) async {
    try {
      return await _request('GET', 'inscriptions/$id', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les inscriptions d'un élève – public
  Future<Map<String, dynamic>> getInscriptionsByEleve(int eleveId) async {
    try {
      return await _request('GET', 'inscriptions/eleve/$eleveId', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les élèves d'une classe pour une année donnée (via inscriptions) – public
  /// ⚠️ Dépréciée : utiliser getElevesByClasse avec anneeScolaireId
  @Deprecated('Utilisez getElevesByClasse avec le paramètre anneeScolaireId')
  Future<Map<String, dynamic>> getElevesByClasseAndAnnee({
    required int classeId,
    required int anneeScolaireId,
  }) async {
    try {
      final queryParams = {
        'classe_id': classeId.toString(),
        'annee_scolaire_id': anneeScolaireId.toString(),
      };
      return await _request('GET', 'eleves/by-classe-and-annee', queryParams: queryParams, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Crée une nouvelle inscription – public
  Future<Map<String, dynamic>> createInscription(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'inscriptions', data: data, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une inscription – public
  Future<Map<String, dynamic>> updateInscription(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'inscriptions/$id', data: data, useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime une inscription – public
  Future<Map<String, dynamic>> deleteInscription(int id) async {
    try {
      return await _request('DELETE', 'inscriptions/$id', useAdminPrefix: false);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Crée une année scolaire – public (sans préfixe admin)
Future<Map<String, dynamic>> createAnneeScolaire(Map<String, dynamic> data) async {
  try {
    return await _request('POST', 'annees-scolaires', data: data, useAdminPrefix: false);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

/// Met à jour une année scolaire – public (sans préfixe admin)
Future<Map<String, dynamic>> updateAnneeScolaire(int id, Map<String, dynamic> data) async {
  try {
    return await _request('PUT', 'annees-scolaires/$id', data: data, useAdminPrefix: false);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

/// Supprime une année scolaire – public (sans préfixe admin)
Future<Map<String, dynamic>> deleteAnneeScolaire(int id) async {
  try {
    return await _request('DELETE', 'annees-scolaires/$id', useAdminPrefix: false);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}


  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité)
  // ============================================================

  static Future<Map<String, dynamic>> getClassesStatic() async {
    final service = EleveService();
    return service.getClasses();
  }

  static Future<Map<String, dynamic>> getAllElevesStatic({int? anneeScolaireId}) async {
    final service = EleveService();
    return service.getAllEleves(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getElevesByClasseStatic(
    int classeId, {
    required int anneeScolaireId,
  }) async {
    final service = EleveService();
    return service.getElevesByClasse(classeId, anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getAllElevesWithClassesStatic({int? anneeScolaireId}) async {
    final service = EleveService();
    return service.getAllElevesWithClasses(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> addEleveStatic(Map<String, dynamic> data) async {
    final service = EleveService();
    return service.addEleve(data);
  }

  static Future<Map<String, dynamic>> updateEleveStatic(int eleveId, Map<String, dynamic> data) async {
    final service = EleveService();
    return service.updateEleve(eleveId, data);
  }

  static Future<Map<String, dynamic>> deleteEleveStatic(int eleveId) async {
    final service = EleveService();
    return service.deleteEleve(eleveId);
  }

  static Future<Map<String, dynamic>> getAnneesScolairesStatic() async {
    final service = EleveService();
    return service.getAnneesScolaires();
  }

  static Future<Map<String, dynamic>> getAnneeScolaireEnCoursStatic() async {
    final service = EleveService();
    return service.getAnneeScolaireEnCours();
  }

  static Future<Map<String, dynamic>> createAnneeScolaireStatic(Map<String, dynamic> data) async {
    final service = EleveService();
    return service.createAnneeScolaire(data);
  }

  static Future<Map<String, dynamic>> updateAnneeScolaireStatic(int id, Map<String, dynamic> data) async {
    final service = EleveService();
    return service.updateAnneeScolaire(id, data);
  }

  static Future<Map<String, dynamic>> deleteAnneeScolaireStatic(int id) async {
    final service = EleveService();
    return service.deleteAnneeScolaire(id);
  }

  static Future<Map<String, dynamic>> getInscriptionsStatic({
    int? eleveId,
    int? classeId,
    int? anneeScolaireId,
    String? statut,
  }) async {
    final service = EleveService();
    return service.getInscriptions(
      eleveId: eleveId,
      classeId: classeId,
      anneeScolaireId: anneeScolaireId,
      statut: statut,
    );
  }

  static Future<Map<String, dynamic>> getInscriptionStatic(int id) async {
    final service = EleveService();
    return service.getInscription(id);
  }

  static Future<Map<String, dynamic>> getInscriptionsByEleveStatic(int eleveId) async {
    final service = EleveService();
    return service.getInscriptionsByEleve(eleveId);
  }

  @Deprecated('Utilisez getElevesByClasseStatic avec le paramètre anneeScolaireId')
  static Future<Map<String, dynamic>> getElevesByClasseAndAnneeStatic({
    required int classeId,
    required int anneeScolaireId,
  }) async {
    final service = EleveService();
    return service.getElevesByClasseAndAnnee(
      classeId: classeId,
      anneeScolaireId: anneeScolaireId,
    );
  }

  static Future<Map<String, dynamic>> createInscriptionStatic(Map<String, dynamic> data) async {
    final service = EleveService();
    return service.createInscription(data);
  }

  static Future<Map<String, dynamic>> updateInscriptionStatic(int id, Map<String, dynamic> data) async {
    final service = EleveService();
    return service.updateInscription(id, data);
  }

  static Future<Map<String, dynamic>> deleteInscriptionStatic(int id) async {
    final service = EleveService();
    return service.deleteInscription(id);
  }

  static Future<Map<String, dynamic>> getClasseActuelleStatic(int eleveId) async {
    final service = EleveService();
    return service.getClasseActuelle(eleveId);
  }

  static Future<Map<String, dynamic>> passerEnClasseSuperieureStatic({
    required int eleveId,
    required int nouvelleClasseId,
    required int nouvelleAnneeScolaireId,
  }) async {
    final service = EleveService();
    return service.passerEnClasseSuperieure(
      eleveId: eleveId,
      nouvelleClasseId: nouvelleClasseId,
      nouvelleAnneeScolaireId: nouvelleAnneeScolaireId,
    );
  }
}