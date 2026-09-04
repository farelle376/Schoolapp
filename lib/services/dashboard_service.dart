// lib/services/dashboard_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/constant.dart';

class DashboardService {
  final ApiService _api = ApiService();
  int? _professeurId;
  int? _matiereId;

  void setProfesseurId(int? id) {
    print('DashboardService.setProfesseurId: $id');
    _professeurId = id;
  }

  void setMatiereId(int? id) {
    print('DashboardService.setMatiereId: $id');
    _matiereId = id;
  }

  Future<Map<String, dynamic>> getClasses({int? anneeScolaireId}) async {
    print('DashboardService.getClasses - professeurId: $_professeurId');
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      String url = '${Constants.classes}?professeur_id=$_professeurId';
      if (anneeScolaireId != null) {
        url += '&annee_scolaire_id=$anneeScolaireId';
      }
      print('URL appelée: $url');
      final response = await _api.get(url);
      print('Réponse API: $response');

      if (response['success'] == true && response['data'] != null) {
        final transformedData = (response['data'] as List).map((classe) {
          return {
            'id': classe['id'],
            'name': classe['nom'],
            'students_count': classe['students_count'],
          };
        }).toList();
        
        return {
          'success': true,
          'data': transformedData,
        };
      }

      return response;
    } catch (e) {
      print('Exception getClasses: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getElevesByClasse(int classeId, {int? anneeScolaireId}) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      String url = '${Constants.classes}/$classeId/eleves?professeur_id=$_professeurId';
      if (anneeScolaireId != null) {
        url += '&annee_scolaire_id=$anneeScolaireId';
      }
      final response = await _api.get(url);
      if (response['success'] == true && response['data'] != null) {
        final transformedData = {
          'classe': {
            'id': response['data']['classe']['id'],
            'name': response['data']['classe']['nom'],
            'students_count': response['data']['classe']['students_count'],
          },
          'eleves': (response['data']['eleves'] as List).map((eleve) {
            return {
              'id': eleve['id'],
              'full_name': eleve['full_name'],
              'nom': eleve['nom'],
              'prenom': eleve['prenom'],
              'inscription_id': eleve['inscription_id'],
            };
          }).toList(),
        };
        
        return {
          'success': true,
          'data': transformedData,
        };
      }
      
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Récupère les notes d’un élève via son inscription (pour le professeur)
  Future<Map<String, dynamic>> getEleveNotes(int inscriptionId) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      // ✅ Correction : une seule URL, utilisée par _api.get
      return await _api.get(
        '/professeur/inscriptions/$inscriptionId/notes?professeur_id=$_professeurId&matiere_id=$_matiereId'
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveNotes(Map<String, dynamic> data) async {
    try {
      print('=== SAUVEGARDE DES NOTES ===');
      final fullData = {
        ...data,
        'professeur_id': _professeurId,
        'matiere_id': _matiereId,
      };
      print('Données envoyées: $fullData');
      final response = await _api.post(Constants.notes, fullData);
      print('Réponse sauvegarde: $response');
      return response;
    } catch (e) {
      print('Erreur saveNotes: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getEmploiDuTemps({int? professeurId, int? anneeScolaireId}) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      String url = '${Constants.emploiDuTemps}?professeur_id=$_professeurId';
      if (anneeScolaireId != null) {
        url += '&annee_scolaire_id=$anneeScolaireId';
      }
      return await _api.get(url);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Méthodes de suppression (privées)
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      print('DELETE URL: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('DELETE Response status: ${response.statusCode}');
      print('DELETE Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true, 'message': 'Supprimé avec succès'};
      } else {
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('DELETE Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Version avec token (si nécessaire)
  Future<Map<String, dynamic>> _deleteWithAuth(String endpoint, String token) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      print('DELETE (Auth) URL: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('DELETE (Auth) Response status: ${response.statusCode}');
      print('DELETE (Auth) Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true, 'message': 'Supprimé avec succès'};
      } else {
        return {
          'success': false,
          'message': 'Erreur ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('DELETE (Auth) Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateNote({
    required int noteId,
    required double valeur,
  }) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      
      print('=== MODIFICATION NOTE ===');
      print('Note ID: $noteId');
      print('Nouvelle valeur: $valeur');
      print('Professeur ID: $_professeurId');
      
      final response = await _api.put('/professeur/notes/$noteId', {
        // ✅ Le backend (ProfesseurDashboardController::updateNote) attend la
        // clé "note", pas "valeur" — l'ancienne clé faisait toujours échouer
        // la validation (422) et empêchait toute modification de note.
        'note': valeur,
        'professeur_id': _professeurId,
        'matiere_id': _matiereId,
      });
      
      print('Réponse updateNote: $response');
      return response;
    } catch (e) {
      print('Exception updateNote: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteNote(int noteId) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      
      final response = await _delete('/professeur/notes/$noteId?professeur_id=$_professeurId');
      return response;
    } catch (e) {
      print('Exception deleteNote: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfesseurInfo() async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      
      final response = await _api.get('/professeurs/$_professeurId');
      return response;
    } catch (e) {
      print('Exception getProfesseurInfo: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}