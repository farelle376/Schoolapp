// lib/services/admin_scolarite_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/scolarite_model.dart';

class AdminScolariteService {
  final String baseUrl = Constants.baseUrl;
  String? _token;

  AdminScolariteService() {
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
      // Uri.replace exige des valeurs String (ou Iterable<String>) : un int
      // brut (ex. annee_scolaire_id) provoque
      // "type 'int' is not a subtype of type 'Iterable<dynamic>'".
      final stringParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
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
      case 'PATCH':
        response = await http.patch(url, headers: headers, body: json.encode(data));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    print('📡 [AdminScolariteService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  Récupération des données de base
  // ============================================================

  /// Récupère la liste des classes. Si anneeScolaireId est fourni, ne
  /// retourne que les classes réellement enregistrées (classe_annees) pour
  /// cette année scolaire.
  Future<List<ClasseInfo>> getClasses({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;

      final response = await _request(
        'GET',
        'emplois-du-temps/scolarite/classes',
        queryParams: queryParams,
      );
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

  /// Récupère la liste des années scolaires (pour les listes déroulantes)
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
  //  MÉTHODES PRINCIPALES (avec année scolaire)
  // ============================================================

  /// Récupère les élèves d'une classe pour une tranche donnée, avec filtre par année (optionnel)
  Future<List<ElevePaiementModel>> getElevesByClasseAndTranche(
    int classeId,
    int tranche, {
    bool? paye,
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (paye != null) queryParams['paye'] = paye ? '1' : '0';
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;

      final response = await _request(
        'GET',
        'emplois-du-temps/scolarite/classe/$classeId/tranche/$tranche',
        queryParams: queryParams,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ElevePaiementModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getElevesByClasseAndTranche: $e');
      return [];
    }
  }

  /// Récupère les tranches d'une classe pour une année donnée (optionnelle)
  Future<Map<String, dynamic>> getTranchesByClasse(
    int classeId, {
    int? anneeScolaireId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;

      final response = await _request(
        'GET',
        'emplois-du-temps/tranches/classe/$classeId',
        queryParams: queryParams,
      );
      return response;
    } catch (e) {
      print('❌ Erreur getTranchesByClasse: $e');
      return {'success': false, 'data': []};
    }
  }

  /// Sauvegarde les tranches d'une classe pour une année donnée (optionnelle)
  Future<Map<String, dynamic>> saveTranchesByClasse(
    int classeId,
    List<Map<String, dynamic>> tranches, {
    int? anneeScolaireId,
  }) async {
    try {
      print('📤 saveTranchesByClasse - Classe ID: $classeId');
      print('📤 Tranches à sauvegarder: $tranches');

      final data = {
        'tranches': tranches,
        if (anneeScolaireId != null) 'annee_scolaire_id': anneeScolaireId,
      };

      final response = await _request('POST', 'emplois-du-temps/tranches/classe/$classeId', data: data);
      print('📥 Réponse saveTranchesByClasse: $response');
      return response;
    } catch (e) {
      print('❌ Erreur saveTranchesByClasse: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère tous les élèves d'une classe avec toutes leurs tranches, pour une année donnée (optionnelle)
  Future<List<EleveAvecTranches>> getElevesWithAllTranches(
    int classeId, {
    int? anneeScolaireId,
  }) async {
    try {
      await _loadToken();

      // Construction de l'URL avec paramètres
      String endpoint = 'emplois-du-temps/scolarite/eleves/$classeId/toutes-tranches';
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) {
        queryParams['annee_scolaire_id'] = anneeScolaireId;
      }
      // Uri.replace exige des valeurs String (ou Iterable<String>) : un int
      // brut (ex. annee_scolaire_id) provoque
      // "type 'int' is not a subtype of type 'Iterable<dynamic>'".
      final stringQueryParams = queryParams.map((key, value) => MapEntry(key, value.toString()));

      final url = Uri.parse('$baseUrl/admin/$endpoint').replace(queryParameters: stringQueryParams);

      print('📡 URL: $url');
      print('🔑 Token présent: ${_token != null}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> data = [];
        String classeNom = '';

        if (decoded['data'] != null && decoded['data'] is List) {
          data = decoded['data'];
        } else if (decoded is List) {
          data = decoded;
        }

        // Récupérer le nom de la classe
        if (decoded['classe_nom'] != null) {
          classeNom = decoded['classe_nom'];
        } else {
          final classes = await getClasses();
          final classe = classes.firstWhere(
            (c) => c.id == classeId,
            orElse: () => ClasseInfo(id: classeId, nom: 'Classe $classeId'),
          );
          classeNom = classe.nom;
        }

        print('📊 Nombre d\'élèves: ${data.length}');
        print('📚 Nom de la classe: $classeNom');

        return data.map((json) => EleveAvecTranches.fromJson(
          json as Map<String, dynamic>,
          classeNom,
          classeId,
        )).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getElevesWithAllTranches: $e');
      return [];
    }
  }
}