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
    print('🔑 [AdminEmploiService] Token chargé: ${_token != null ? "✅" : "❌"}');
  }

  // ============================================================
  //  Requête HTTP générique avec préfixe admin (CORRIGÉ)
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
      // ✅ CORRECTION : Utiliser /admin/ pour TOUS les endpoints
      url = Uri.parse('$baseUrl/admin/$endpoint');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    print('📡 [AdminEmploiService] $method $url');

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

    print('📡 [AdminEmploiService] $method $endpoint -> ${response.statusCode}');

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
  //  Récupération des données de référence (formulaires)
  //  TOUS les endpoints utilisent maintenant /admin/
  // ============================================================

  Future<List<Map<String, dynamic>>> getClasses() async {
    try {
      // ✅ Maintenant utilise /admin/classes
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
      print('❌ Erreur getClasses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMatieres() async {
    try {
      // ✅ Maintenant utilise /admin/matieres
      final response = await _request('GET', 'matieres');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      print('❌ Erreur getMatieres: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProfesseurs() async {
    try {
      // ✅ Maintenant utilise /admin/professeurs
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
            'matiere_id': p['matiere_id'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getProfesseurs: $e');
      return [];
    }
  }

  // ============================================================
  //  MÉTHODES PRINCIPALES (CRUD emplois du temps)
  //  TOUS les endpoints utilisent maintenant /admin/
  // ============================================================

  /// Récupère la liste des emplois du temps, avec filtres optionnels
  Future<List<EmploiDuTempsAdminModel>> getEmplois({
    int? classeId,
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classeId != null) queryParams['classe_id'] = classeId;
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;

      print('🟢 Récupération emplois avec filtres: $queryParams');

      // ✅ Maintenant utilise /admin/emplois-du-temps
      final response = await _request('GET', 'emplois-du-temps/emplois-du-temps', queryParams: queryParams);
      print('📥 Réponse emplois: ${response['success']}');

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : (rawData is Map && rawData['data'] is List ? rawData['data'] as List : <dynamic>[]);
        print('📦 Nombre d\'emplois: ${data.length}');
        return data.map((json) => EmploiDuTempsAdminModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getEmplois: $e');
      return [];
    }
  }

  /// Crée un nouvel emploi du temps
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
        'type_cours': data['type_cours'] ?? 'cours',
        'est_active': data['est_active'] ?? true,
        'annee_scolaire_id': data['annee_scolaire_id'],
      };

      if (cleanedData['annee_scolaire_id'] == null) {
        print('❌ Erreur: annee_scolaire_id manquant');
        return false;
      }

      print('📦 Données nettoyées: $cleanedData');

      // ✅ Maintenant utilise /admin/emplois-du-temps
      final response = await _request('POST', 'emplois-du-temps/emplois-du-temps', data: cleanedData);
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

  /// Met à jour un emploi du temps existant
  Future<bool> updateEmploi(int id, Map<String, dynamic> data) async {
    try {
      final cleanedData = {
        if (data.containsKey('classe_id')) 'classe_id': data['classe_id'],
        if (data.containsKey('matiere_id')) 'matiere_id': data['matiere_id'],
        if (data.containsKey('professeur_id')) 'professeur_id': data['professeur_id'],
        if (data.containsKey('jour')) 'jour': data['jour'],
        if (data.containsKey('heure_debut')) 'heure_debut': data['heure_debut'],
        if (data.containsKey('heure_fin')) 'heure_fin': data['heure_fin'],
        if (data.containsKey('type_cours')) 'type_cours': data['type_cours'],
        if (data.containsKey('est_active')) 'est_active': data['est_active'],
        if (data.containsKey('annee_scolaire_id')) 'annee_scolaire_id': data['annee_scolaire_id'],
      };

      print('📦 UPDATE DATA: $cleanedData');

      // ✅ Maintenant utilise /admin/emplois-du-temps/$id
      final response = await _request('PUT', 'emplois-du-temps/emplois-du-temps/$id', data: cleanedData);
      print('📥 UPDATE Response: $response');

      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur updateEmploi: $e');
      return false;
    }
  }

  /// Supprime un emploi du temps
  Future<bool> deleteEmploi(int id) async {
    try {
      // ✅ Maintenant utilise /admin/emplois-du-temps/$id
      final response = await _request('DELETE', 'emplois-du-temps/emplois-du-temps/$id');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur deleteEmploi: $e');
      return false;
    }
  }

  /// Active ou désactive un emploi du temps
  Future<bool> toggleActive(int id) async {
    try {
      // ✅ Maintenant utilise /admin/emplois-du-temps/$id/toggle
      final response = await _request('PATCH', 'emplois-du-temps/emplois-du-temps/$id/toggle');
      return response['success'] == true;
    } catch (e) {
      print('❌ Erreur toggleActive: $e');
      return false;
    }
  }

  // ============================================================
  //  MÉTHODE UTILITAIRE : Récupérer les années scolaires
  // ============================================================

  Future<List<Map<String, dynamic>>> getAnneesScolaires() async {
    try {
      // ✅ Maintenant utilise /admin/annees-scolaires
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

  Future<List<EmploiDuTempsAdminModel>> getEmploisList({
  int? classeId,
  int? anneeScolaireId,
}) async {
  try {
    final queryParams = <String, dynamic>{};
    if (classeId != null) queryParams['classe_id'] = classeId;
    if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;

    print('🟢 Récupération emplois avec filtres: $queryParams');

    final response = await _request('GET', 'emplois-du-temps/emplois-du-temps', queryParams: queryParams);
    print('📥 Réponse emplois: ${response['success']}');
    print('📥 Type de data: ${response['data'].runtimeType}');

    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      // ✅ Vérifier que data est bien une liste
      if (data is List) {
        print('📦 Nombre d\'emplois: ${data.length}');
        return data.map((json) => EmploiDuTempsAdminModel.fromJson(json)).toList();
      } 
      // ✅ Si data est un Map avec une clé 'data' (pagination)
      else if (data is Map && data.containsKey('data')) {
        final dynamic items = data['data'];
        if (items is List) {
          print('📦 Nombre d\'emplois (paginé): ${items.length}');
          return items.map((json) => EmploiDuTempsAdminModel.fromJson(json)).toList();
        }
      }
      // ✅ Si data est un int (pas de données)
      else if (data is int) {
        print('⚠️ Aucune donnée trouvée (data = $data)');
        return [];
      } else {
        print('⚠️ getEmploisList: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getEmplois: $e');
    return [];
  }
}

/// Récupère la liste des classes pour l'emploi du temps
Future<List<Map<String, dynamic>>> getClassesForEmploi() async {
  try {
    final response = await _request('GET', 'classes');
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return data.map((c) {
          String nom = c['nom']?.toString() ?? '';
          return {
            'id': c['id'] ?? 0,
            'nom': nom,
            'nom_complet': nom.isEmpty ? 'Classe ${c['id']}' : nom,
          };
        }).toList();
      } else if (data is int) {
        print('⚠️ Aucune classe trouvée (data = $data)');
        return [];
      } else {
        print('⚠️ getClassesForEmploi: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getClassesForEmploi: $e');
    return [];
  }
}

/// Récupère la liste des matières pour l'emploi du temps
Future<List<Map<String, dynamic>>> getMatieresForEmploi() async {
  try {
    final response = await _request('GET', 'matieres');
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is int) {
        print('⚠️ Aucune matière trouvée (data = $data)');
        return [];
      } else {
        print('⚠️ getMatieresForEmploi: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getMatieresForEmploi: $e');
    return [];
  }
}

/// Récupère la liste des professeurs pour l'emploi du temps
Future<List<Map<String, dynamic>>> getProfesseursForEmploi() async {
  try {
    final response = await _request('GET', 'professeurs');
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
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
            'matiere_id': p['matiere_id'],
          };
        }).toList();
      } else if (data is int) {
        print('⚠️ Aucun professeur trouvé (data = $data)');
        return [];
      } else {
        print('⚠️ getProfesseursForEmploi: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getProfesseursForEmploi: $e');
    return [];
  }
}

/// Récupère la liste des années scolaires pour l'emploi du temps
Future<List<Map<String, dynamic>>> getAnneesScolairesForEmploi() async {
  try {
    final response = await _request('GET', 'annees-scolaires');
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return data.map((a) => {
          'id': a['id'] ?? 0,
          'libelle': a['libelle']?.toString() ?? 'Année ${a['id']}',
          'date_debut': a['date_debut'],
          'date_fin': a['date_fin'],
        }).toList();
      } else {
        print('⚠️ getAnneesScolairesForEmploi: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getAnneesScolairesForEmploi: $e');
    return [];
  }
}
}