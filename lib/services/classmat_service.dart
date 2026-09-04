// lib/services/classmat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class ClassmatService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  ClassmatService() {
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
    print('🔑 [ClassmatService] Token chargé: ${_token != null ? "✅" : "❌"}');
  }

  // ============================================================
  //  Requête HTTP générique (CORRIGÉ)
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
      url = Uri.parse('$baseUrl/admin/$endpoint')
          .replace(queryParameters: stringParams);
    } else {
      // ✅ CORRECTION : Utilise /admin/ au lieu de /Classmat/
      url = Uri.parse('$baseUrl/admin/$endpoint');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    print('📡 [ClassmatService] $method $url');

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

    print('📡 [ClassmatService] $method $endpoint -> ${response.statusCode}');

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
  //  CLASSES PERMANENTES
  // ============================================================

  Future<Map<String, dynamic>> getClasses({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'classes', queryParams: queryParams);
    } catch (e) {
      print('❌ Erreur getClasses: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addClasse(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'classes', data: data);
    } catch (e) {
      print('❌ Erreur addClasse: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateClasse(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'classes/$id', data: data);
    } catch (e) {
      print('❌ Erreur updateClasse: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteClasse(int id) async {
    try {
      return await _request('DELETE', 'classes/$id');
    } catch (e) {
      print('❌ Erreur deleteClasse: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MATIÈRES PERMANENTES
  // ============================================================

  Future<Map<String, dynamic>> getMatieres({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'matieres', queryParams: queryParams);
    } catch (e) {
      print('❌ Erreur getMatieres: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addMatiere(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'matieres', data: data);
    } catch (e) {
      print('❌ Erreur addMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addMultipleMatieres(List<Map<String, dynamic>> matieres) async {
    try {
      return await _request('POST', 'matieres/multiple', data: {'matieres': matieres});
    } catch (e) {
      print('❌ Erreur addMultipleMatieres: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMatiere(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'matieres/$id', data: data);
    } catch (e) {
      print('❌ Erreur updateMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMatiere(int id) async {
    try {
      return await _request('DELETE', 'matieres/$id');
    } catch (e) {
      print('❌ Erreur deleteMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  CLASSES ANNUELLES (ClasseAnnee)
  // ============================================================

  /// Récupère les classes annuelles, éventuellement filtrées par année
  Future<Map<String, dynamic>> getClasseAnnees({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'classe-annees', queryParams: queryParams);
    } catch (e) {
      print('❌ Erreur getClasseAnnees: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Crée une classe annuelle
  Future<Map<String, dynamic>> addClasseAnnee(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'classe-annees', data: data);
    } catch (e) {
      print('❌ Erreur addClasseAnnee: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une classe annuelle
  Future<Map<String, dynamic>> updateClasseAnnee(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'classe-annees/$id', data: data);
    } catch (e) {
      print('❌ Erreur updateClasseAnnee: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime une classe annuelle
  Future<Map<String, dynamic>> deleteClasseAnnee(int id) async {
    try {
      return await _request('DELETE', 'classe-annees/$id');
    } catch (e) {
      print('❌ Erreur deleteClasseAnnee: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  MATIÈRES ANNUELLES (ClasseAnneeMatiere)
  // ============================================================

  /// Récupère les matières annuelles, avec filtres optionnels
  Future<Map<String, dynamic>> getClasseAnneeMatieres({
    int? classeAnneeId,
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classeAnneeId != null) {
        queryParams['classe_annee_id'] = classeAnneeId;
      }
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      return await _request('GET', 'classe-annee-matieres', queryParams: queryParams);
    } catch (e) {
      print('❌ Erreur getClasseAnneeMatieres: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Crée une matière annuelle (ClasseAnneeMatiere)
  Future<Map<String, dynamic>> addClasseAnneeMatiere(Map<String, dynamic> data) async {
    try {
      return await _request('POST', 'classe-annee-matieres', data: data);
    } catch (e) {
      print('❌ Erreur addClasseAnneeMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une matière annuelle
  Future<Map<String, dynamic>> updateClasseAnneeMatiere(int id, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'classe-annee-matieres/$id', data: data);
    } catch (e) {
      print('❌ Erreur updateClasseAnneeMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime une matière annuelle
  Future<Map<String, dynamic>> deleteClasseAnneeMatiere(int id) async {
    try {
      return await _request('DELETE', 'classe-annee-matieres/$id');
    } catch (e) {
      print('❌ Erreur deleteClasseAnneeMatiere: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  PROFESSEURS (pour les dropdowns)
  // ============================================================

  /// Récupère la liste des professeurs
  Future<Map<String, dynamic>> getProfesseurs() async {
    try {
      return await _request('GET', 'professeurs');
    } catch (e) {
      print('❌ Erreur getProfesseurs: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

Future<List<Map<String, dynamic>>> getClassesList({int? anneeScolaireId}) async {
  try {
    final response = await getClasses(anneeScolaireId: anneeScolaireId);
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      // ✅ Vérifier que data est bien une liste
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


/// Récupère la liste des matières (retourne directement une List)
Future<List<Map<String, dynamic>>> getMatieresList({int? anneeScolaireId}) async {
  try {
    final response = await getMatieres(anneeScolaireId: anneeScolaireId);
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
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

/// Récupère la liste des classes annuelles (retourne directement une List)
Future<List<Map<String, dynamic>>> getClasseAnneesList({int? anneeScolaireId}) async {
  try {
    final response = await getClasseAnnees(anneeScolaireId: anneeScolaireId);
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('⚠️ getClasseAnneesList: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getClasseAnneesList: $e');
    return [];
  }
}

/// Récupère la liste des professeurs (retourne directement une List)
Future<List<Map<String, dynamic>>> getProfesseursList() async {
  try {
    final response = await getProfesseurs();
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        // ✅ L'API renvoie 'nom' et 'prenom' séparément, pas 'nom_complet'.
        // Les dropdowns (add_classe_panel / edit_classe_panel) attendent
        // p['nom_complet'] — on le construit ici pour éviter un
        // "TypeError: null: type 'Null' is not a subtype of type 'String'".
        return List<Map<String, dynamic>>.from(data).map((p) {
          final nom = (p['nom'] ?? '').toString();
          final prenom = (p['prenom'] ?? '').toString();
          final nomComplet = ('$prenom $nom').trim();
          return {
            ...p,
            'nom_complet': nomComplet.isEmpty ? 'Professeur ${p['id']}' : nomComplet,
          };
        }).toList();
      } else if (data is int) {
        print('⚠️ getProfesseursList: Aucun professeur trouvé (data = $data)');
        return [];
      } else {
        print('⚠️ getProfesseursList: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getProfesseursList: $e');
    return [];
  }
}

/// Récupère la liste des matières annuelles (retourne directement une List)
Future<List<Map<String, dynamic>>> getClasseAnneeMatieresList({
  int? classeAnneeId,
  int? anneeScolaireId,
}) async {
  try {
    final response = await getClasseAnneeMatieres(
      classeAnneeId: classeAnneeId,
      anneeScolaireId: anneeScolaireId,
    );
    
    if (response['success'] == true) {
      final dynamic data = response['data'];
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('⚠️ getClasseAnneeMatieresList: data n\'est pas une liste (${data.runtimeType})');
        return [];
      }
    }
    return [];
  } catch (e) {
    print('❌ Erreur getClasseAnneeMatieresList: $e');
    return [];
  }
}
}