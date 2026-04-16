// lib/services/dashboard_service.dart

import 'api_service.dart';
import '../utils/constant.dart';

class DashboardService {
  final ApiService _api = ApiService();
  int? _professeurId;

  void setProfesseurId(int? id) {
    print('DashboardService.setProfesseurId: $id');
    _professeurId = id;
  }

  Future<Map<String, dynamic>> getClasses() async {
    print('DashboardService.getClasses - professeurId: $_professeurId');
    try {
      if (_professeurId == null) {
        print('ERREUR: ID professeur non défini');
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      final url = '${Constants.classes}?professeur_id=$_professeurId';
      print('URL appelée: $url');
      final response = await _api.get(url);
      print('Réponse API: $response');

         if (response['success'] == true && response['data'] != null) {
      final transformedData = (response['data'] as List).map((classe) {
        return {
          'id': classe['id'],
          'name': classe['nom'],  // ← Transformation ici
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

  Future<Map<String, dynamic>> getElevesByClasse(int classeId) async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      final response = await _api.get('${Constants.classes}/$classeId/eleves?professeur_id=$_professeurId');
      if (response['success'] == true && response['data'] != null) {
      final transformedData = {
        'classe': {
          'id': response['data']['classe']['id'],
          'name': response['data']['classe']['nom'],  // ← Transformation
          'students_count': response['data']['classe']['students_count'],
        },
        'eleves': (response['data']['eleves'] as List).map((eleve) {
          return {
            'id': eleve['id'],
            'full_name': eleve['full_name'],
            'nom': eleve['nom'],
            'prenom': eleve['prenom'],
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

Future<Map<String, dynamic>> getEleveNotes(int eleveId) async {
  try {
    if (_professeurId == null) {
      return {'success': false, 'message': 'ID professeur non défini'};
    }
    return await _api.get('/eleves/$eleveId/notes?professeur_id=$_professeurId');
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

  Future<Map<String, dynamic>> getEmploiDuTemps() async {
    try {
      if (_professeurId == null) {
        return {'success': false, 'message': 'ID professeur non défini'};
      }
      return await _api.get('${Constants.emploiDuTemps}?professeur_id=$_professeurId');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}