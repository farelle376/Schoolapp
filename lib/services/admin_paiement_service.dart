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

  // ============================================================
  //  Gestion du token (AMÉLIORÉ)
  // ============================================================
  Future<String?> _getToken() async {
    // ✅ Si _token est déjà chargé, le retourner
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
    print('🔑 [AdminPaiementService] Token chargé: ${_token != null ? "✅" : "❌"}');
  }

  // ============================================================
  //  Requête HTTP générique avec support des paramètres de requête
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

    print('📡 [AdminPaiementService] $method $url');

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
      case 'PATCH':
        response = await http.patch(url, headers: headers, body: json.encode(data));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    print('📡 [AdminPaiementService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // ✅ Gestion du token expiré
      print('⚠️ Token expiré ou invalide');
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  Récupération des données de base
  // ============================================================

  /// Récupère la liste des classes
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

  /// Récupère la liste des années scolaires (pour les filtres)
  Future<List<Map<String, dynamic>>> getAnneesScolaires() async {
    try {
      final response = await _request('GET', 'annees-scolaires');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((a) => {
          'id': a['id'] ?? 0,
          'libelle': a['libelle']?.toString() ?? 'Année ${a['id']}',
          'date_debut': a['date_debut'],
          'date_fin': a['date_fin'],
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getAnneesScolaires: $e');
      return [];
    }
  }

  // ============================================================
  //  MÉTHODES PRINCIPALES (avec année scolaire et inscription)
  // ============================================================

Future<List<PaiementAdminModel>> getPaiementsByClasseAndTranche(
  int classeId,
  int tranche, {
  int? anneeScolaireId,
}) async {
  try {
    final queryParams = <String, dynamic>{};
    if (anneeScolaireId != null) {
      queryParams['annee_scolaire_id'] = anneeScolaireId;
    }

    final response = await _request(
      'GET',
      'paiements/classe/$classeId/tranche/$tranche',
      queryParams: queryParams,
    );

    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      // ✅ Vérifier que data est une liste
      if (data is List) {
        return data.map((json) => PaiementAdminModel.fromJson(json)).toList();
      } else if (data is int) {
        print('⚠️ Aucun paiement trouvé (data = $data)');
        return [];
      } else {
        print('⚠️ getPaiementsByClasseAndTranche: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getPaiementsByClasseAndTranche: $e');
    return [];
  }
}
  /// Récupère tous les paiements avec filtres (classe, année, statut, etc.)
  Future<List<PaiementAdminModel>> getPaiements({
    int? classeId,
    int? anneeScolaireId,
    String? statut,
    int? tranche,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classeId != null) queryParams['classe_id'] = classeId;
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      if (statut != null) queryParams['statut'] = statut;
      if (tranche != null) queryParams['tranche'] = tranche;

      final response = await _request('GET', 'paiements', queryParams: queryParams);
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => PaiementAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getPaiements: $e');
      return [];
    }
  }

  // lib/services/admin_paiement_service.dart

/// Récupère la liste des classes (retourne directement une List)
Future<List<ClasseInfo>> getClassesList() async {
  try {
    final response = await _request('GET', 'paiements/classes');
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return data.map((json) => ClasseInfo.fromJson(json)).toList();
      } else if (data is int) {
        print('⚠️ Aucune classe trouvée (data = $data)');
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

  /// Récupère les paiements d'une inscription spécifique
  Future<List<PaiementAdminModel>> getPaiementsByInscription(int inscriptionId) async {
    try {
      final response = await _request('GET', 'paiements/inscription/$inscriptionId');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => PaiementAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getPaiementsByInscription: $e');
      return [];
    }
  }

  /// Récupère les paiements par année scolaire (pour un suivi global)
  Future<List<PaiementAdminModel>> getPaiementsByAnnee(int anneeScolaireId) async {
    try {
      final response = await _request(
        'GET',
        'paiements/annee/$anneeScolaireId',
      );
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => PaiementAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getPaiementsByAnnee: $e');
      return [];
    }
  }

  // ============================================================
  //  MÉTHODES DE GESTION (CRUD)
  // ============================================================

  /// Marquer un paiement comme validé
  Future<bool> validerPaiement(int paiementId) async {
    try {
      final response = await _request(
        'PATCH',
        'paiements/$paiementId/valider',
      );
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur validerPaiement: $e');
      return false;
    }
  }

  /// Supprimer un paiement
  Future<bool> deletePaiement(int paiementId) async {
    try {
      final response = await _request('DELETE', 'paiements/$paiementId');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deletePaiement: $e');
      return false;
    }
  }

  // ============================================================
  //  MÉTHODES DÉPRÉCIÉES (compatibilité temporaire)
  // ============================================================

  /// @Deprecated Utilisez getPaiementsByClasseAndTranche avec anneeScolaireId
  @Deprecated('Utilisez getPaiementsByClasseAndTranche avec le paramètre anneeScolaireId')
  Future<List<PaiementAdminModel>> getPaiementsByClasseAndTrancheOld(
    int classeId,
    int tranche,
  ) async {
    return getPaiementsByClasseAndTranche(classeId, tranche, anneeScolaireId: null);
  }
}