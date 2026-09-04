// lib/services/note_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class NoteAdminService {
  final String baseUrl = Constants.baseUrl;
  String? _token;
  static Map<String, dynamic>? _cachedData;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 10);

  NoteAdminService() {
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
      // Uri.replace exige des valeurs String (ou Iterable<String>) : un int
      // brut (ex. classe_id) provoque
      // "type 'int' is not a subtype of type 'Iterable<dynamic>'".
      final stringQueryParams = queryParams.map((key, value) => MapEntry(key, value.toString()));
      url = Uri.parse('$baseUrl/admin/$endpoint').replace(queryParameters: stringQueryParams);
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

    print('📡 [NoteAdminService] $method $endpoint -> ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  MÉTHODES D'INSTANCE
  // ============================================================

  /// Récupère les notes avec filtres (classe, matière, trimestre, année, inscription)
  Future<Map<String, dynamic>> getNotes({
    int? classeId,
    int? matiereId,
    int? trimestre,
    int? anneeScolaireId,
    int? inscriptionId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (classeId != null) queryParams['classe_id'] = classeId;
      if (matiereId != null) queryParams['matiere_id'] = matiereId;
      if (trimestre != null) queryParams['trimestre'] = trimestre;
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      if (inscriptionId != null) queryParams['inscription_id'] = inscriptionId;

      return await _request('GET', 'notes', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les notes d'une inscription spécifique (version instance)
  Future<Map<String, dynamic>> getNotesByInscription(int inscriptionId) async {
    try {
      return await _request('GET', 'inscriptions/$inscriptionId/notes');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les notes par classe et année (avec filtres optionnels)
  Future<Map<String, dynamic>> getNotesByClasseAndAnnee({
    required int classeId,
    required int anneeScolaireId,
    int? matiereId,
    int? trimestre,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'classe_id': classeId,
        'annee_scolaire_id': anneeScolaireId,
      };
      if (matiereId != null) queryParams['matiere_id'] = matiereId;
      if (trimestre != null) queryParams['trimestre'] = trimestre;

      return await _request(
        'GET',
        'notes/by-classe-annee',
        queryParams: queryParams,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les statistiques des notes (éventuellement par année)
  Future<Map<String, dynamic>> getNotesStats({int? anneeScolaireId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (anneeScolaireId != null) queryParams['annee_scolaire_id'] = anneeScolaireId;
      return await _request('GET', 'notes/stats', queryParams: queryParams);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère toutes les données du tableau de bord (avec cache)
  Future<Map<String, dynamic>> getAllData({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedData != null && _cacheTime != null) {
        if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
          print('📦 Utilisation du cache');
          return _cachedData!;
        }
      }

      print('🌐 Chargement depuis API...');
      final response = await _request('GET', 'admin/dashboard-data');
      if (response['success'] == true) {
        _cachedData = response;
        _cacheTime = DateTime.now();
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Rafraîchit le cache
  Future<void> refresh() async {
    _cachedData = null;
    _cacheTime = null;
    await getAllData(forceRefresh: true);
  }

  // ============================================================
  //  CRUD NOTES
  // ============================================================

  /// Ajoute une note
  Future<Map<String, dynamic>> saveNote({
    required int inscriptionId,
    required int matiereId,
    required double note,
    required String typeNote,
    required int trimestre,
  }) async {
    try {
      final data = {
        'inscription_id': inscriptionId,
        'matiere_id': matiereId,
        'note': note,
        'type_note': typeNote,
        'trimestre': trimestre,
      };
      return await _request('POST', 'notes', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Met à jour une note existante
  Future<Map<String, dynamic>> updateNote(int noteId, Map<String, dynamic> data) async {
    try {
      return await _request('PUT', 'notes/$noteId', data: data);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Supprime une note
  Future<Map<String, dynamic>> deleteNote(int noteId) async {
    try {
      return await _request('DELETE', 'notes/$noteId');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  DONNÉES DE RÉFÉRENCE (classes, matières)
  // ============================================================

  /// Récupère les classes (pour les filtres)
  Future<Map<String, dynamic>> getClasses() async {
    try {
      // ✅ Utiliser la bonne route
      return await _request('GET', 'classes');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  /// Récupère les matières (pour les filtres)
  Future<Map<String, dynamic>> getMatieres() async {
    try {
      // ✅ Utiliser la bonne route
      return await _request('GET', 'matieres');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  //  FILTRAGE LOCAL (pour le cache) – méthode statique utilitaire
  // ============================================================

  static List<dynamic> filterNotes({
    required List<dynamic> notes,
    int? inscriptionId,
    int? classeId,
    int? matiereId,
    int? trimestre,
    int? anneeScolaireId,
  }) {
    return notes.where((note) {
      if (inscriptionId != null && note['inscription_id'] != inscriptionId) return false;
      if (classeId != null) {
        if (note['inscription'] != null && note['inscription']['classe_id'] != classeId) {
          return false;
        }
        if (note['classe_id'] != null && note['classe_id'] != classeId) {
          return false;
        }
      }
      if (anneeScolaireId != null) {
        if (note['inscription'] != null &&
            note['inscription']['annee_scolaire_id'] != anneeScolaireId) {
          return false;
        }
        if (note['annee_scolaire_id'] != null &&
            note['annee_scolaire_id'] != anneeScolaireId) {
          return false;
        }
      }
      if (matiereId != null && note['matiere_id'] != matiereId) return false;
      if (trimestre != null && note['trimestre'] != trimestre) return false;
      return true;
    }).toList();
  }

  // ============================================================
  //  MÉTHODES STATIQUES (compatibilité avec l'ancien code)
  //  Chaque méthode statique crée une instance et appelle la méthode d'instance.
  // ============================================================

  static Future<Map<String, dynamic>> getNotesStatic({
    int? classeId,
    int? matiereId,
    int? trimestre,
    int? anneeScolaireId,
    int? inscriptionId,
  }) async {
    final service = NoteAdminService();
    return service.getNotes(
      classeId: classeId,
      matiereId: matiereId,
      trimestre: trimestre,
      anneeScolaireId: anneeScolaireId,
      inscriptionId: inscriptionId,
    );
  }

  /// ✅ Méthode statique pour récupérer les notes d'une inscription
  static Future<Map<String, dynamic>> getNotesByInscriptionStatic(int inscriptionId) async {
    final service = NoteAdminService();
    return service.getNotesByInscription(inscriptionId);
  }

  static Future<Map<String, dynamic>> getNotesByClasseAndAnneeStatic({
    required int classeId,
    required int anneeScolaireId,
    int? matiereId,
    int? trimestre,
  }) async {
    final service = NoteAdminService();
    return service.getNotesByClasseAndAnnee(
      classeId: classeId,
      anneeScolaireId: anneeScolaireId,
      matiereId: matiereId,
      trimestre: trimestre,
    );
  }

  static Future<Map<String, dynamic>> getNotesStatsStatic({int? anneeScolaireId}) async {
    final service = NoteAdminService();
    return service.getNotesStats(anneeScolaireId: anneeScolaireId);
  }

  static Future<Map<String, dynamic>> getAllDataStatic({bool forceRefresh = false}) async {
    final service = NoteAdminService();
    return service.getAllData(forceRefresh: forceRefresh);
  }

  static Future<void> refreshStatic() async {
    final service = NoteAdminService();
    await service.refresh();
  }

  static Future<Map<String, dynamic>> saveNoteStatic({
    required int inscriptionId,
    required int matiereId,
    required double note,
    required String typeNote,
    required int trimestre,
  }) async {
    final service = NoteAdminService();
    return service.saveNote(
      inscriptionId: inscriptionId,
      matiereId: matiereId,
      note: note,
      typeNote: typeNote,
      trimestre: trimestre,
    );
  }

  static Future<Map<String, dynamic>> updateNoteStatic(
      int noteId, Map<String, dynamic> data) async {
    final service = NoteAdminService();
    return service.updateNote(noteId, data);
  }

  static Future<Map<String, dynamic>> deleteNoteStatic(int noteId) async {
    final service = NoteAdminService();
    return service.deleteNote(noteId);
  }

  static Future<Map<String, dynamic>> getClassesStatic() async {
    final service = NoteAdminService();
    return service.getClasses();
  }

  static Future<Map<String, dynamic>> getMatieresStatic() async {
    final service = NoteAdminService();
    return service.getMatieres();
  }
}