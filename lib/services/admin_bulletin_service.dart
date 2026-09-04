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

  // ============================================================
  //  Gestion du token
  // ============================================================
  Future<String?> _getToken() async {
   // Si _token est déjà chargé, le retourner
    if (_token != null) {
      return _token;
    }
    // Sinon, le charger depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
    return _token;
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
    print('🔑 [AdminBulletinService] Token chargé: ${_token != null ? "✅" : "❌"}');
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
      final stringParams = queryParams.map(
      (key, value) => MapEntry(key, value.toString()),
    );
      url = Uri.parse('$baseUrl/admin/$endpoint').replace(queryParameters: stringParams);
    } else {
      url = Uri.parse('$baseUrl/admin/$endpoint');
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

    print('📡 [AdminBulletinService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES PRINCIPALES (avec inscription_id et année scolaire)
  // ============================================================

  /// Récupère toutes les classes (inchangé)
  Future<List<ClasseInfo>> getClasses() async {
    try {
      final response = await _request('GET', 'emplois-du-temps/bulletins/classes');
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

  /// Récupère les notes d'une inscription pour un trimestre donné
  Future<Map<String, dynamic>> getNotesByInscriptionAndTrimestre(
    int inscriptionId,
    String trimestre,
  ) async {
    try {
      await _loadToken();
      final response = await _request(
        'GET',
        'inscriptions/$inscriptionId/notes',
        queryParams: {'trimestre': trimestre},
      );
      return response;
    } catch (e) {
      print('❌ Erreur getNotesByInscriptionAndTrimestre: $e');
      return {'success': false, 'matieres': []};
    }
  }

  /// Récupère les bulletins par classe, trimestre et année (optionnelle)
  Future<List<BulletinAdminModel>> getBulletinsByClasse(
    int classeId,
    String trimestre, {
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }

      final response = await _request(
        'GET',
        'emplois-du-temps/bulletins/classe/$classeId/trimestre/$trimestre',
        queryParams: queryParams,
      );

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

  /// Récupère les élèves d'une classe pour une année donnée (optionnelle)
  Future<List<Map<String, dynamic>>> getElevesByClasse(
    int classeId, {
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }

      final response = await _request(
        'GET',
        'emplois-du-temps/bulletins/classe/$classeId/eleves',
        queryParams: queryParams,
      );

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

  /// Vérifie si toutes les notes sont disponibles pour une inscription
  Future<Map<String, dynamic>> checkNotesDisponibles(
    int inscriptionId,
    String trimestre,
  ) async {
    try {
      final response = await _request(
        'GET',
        'emplois-du-temps/bulletins/check-notes/$inscriptionId/$trimestre',
      );
      return response;
    } catch (e) {
      print('❌ Erreur checkNotesDisponibles: $e');
      return {'success': false, 'toutes_disponibles': false, 'details': []};
    }
  }

  /// Génère un bulletin pour une inscription
  Future<Map<String, dynamic>> generateBulletin(
    int inscriptionId,
    String trimestre,
  ) async {
    try {
      final response = await _request(
        'POST',
        'emplois-du-temps/bulletins/generate',
        data: {
          'inscription_id': inscriptionId,
          'trimestre': trimestre,
        },
      );
      return response;
    } catch (e) {
      print('❌ Erreur generateBulletin: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les détails d’un bulletin (inchangé)
  Future<BulletinAdminModel?> getBulletinDetail(int bulletinId) async {
    try {
      final response = await _request('GET', 'emplois-du-temps/bulletins/$bulletinId');
      if (response['success'] == true) {
        return BulletinAdminModel.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getBulletinDetail: $e');
      return null;
    }
  }

  /// Met à jour un bulletin (inchangé)
  Future<bool> updateBulletin(int bulletinId, Map<String, dynamic> data) async {
    try {
      final response = await _request('PUT', 'emplois-du-temps/bulletins/$bulletinId', data: data);
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur updateBulletin: $e');
      return false;
    }
  }

  /// Supprime un bulletin (inchangé)
  Future<bool> deleteBulletin(int bulletinId) async {
    try {
      final response = await _request('DELETE', 'emplois-du-temps/bulletins/$bulletinId');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deleteBulletin: $e');
      return false;
    }
  }

  // ============================================================
  //  MÉTHODES DÉPRÉCIÉES (compatibilité temporaire)
  // ============================================================

  /// @Deprecated Utilisez getNotesByInscriptionAndTrimestre à la place
  @Deprecated('Utilisez getNotesByInscriptionAndTrimestre')
  Future<Map<String, dynamic>> getNotesByEleveAndTrimestre(
    int eleveId,
    String trimestre,
  ) async {
    // Redirige vers la nouvelle méthode si vous pouvez récupérer l'inscription active
    // Sinon, retourne une erreur explicite
    return {
      'success': false,
      'message': 'Cette méthode est dépréciée. Utilisez getNotesByInscriptionAndTrimestre avec inscription_id.',
    };
  }
}