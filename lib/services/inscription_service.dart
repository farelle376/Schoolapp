// lib/services/inscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constant.dart';

class InscriptionService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('admin_token');
  }

  // ============================
  //       RÉCUPÉRER DES DONNÉES
  // ============================

  static Future<Map<String, dynamic>> getInscriptions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${Constants.baseUrl}/inscriptions');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getInscriptionsByEleve(int eleveId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${Constants.baseUrl}/inscriptions/eleve/$eleveId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getElevesByClasseAndAnnee({
    required int classeId,
    required int anneeScolaireId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      // ✅ Construction de l'URL avec les paramètres de requête
      final url = Uri.parse('${Constants.baseUrl}/inscriptions/eleves').replace(
        queryParameters: {
          'classe_id': classeId.toString(),
          'annee_scolaire_id': anneeScolaireId.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================
  //      CRÉER / MODIFIER / SUPPRIMER
  // ============================

  static Future<Map<String, dynamic>> createInscription({
    required int eleveId,
    required int classeId,
    required int anneeScolaireId,
    String statut = 'actif',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${Constants.baseUrl}/inscriptions');
      final data = {
        'eleve_id': eleveId,
        'classe_id': classeId,
        'annee_scolaire_id': anneeScolaireId,
        'date_inscription': DateTime.now().toIso8601String().split('T')[0],
        'statut': statut,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateInscription({
    required int id,
    int? classeId,
    int? anneeScolaireId,
    String? statut,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${Constants.baseUrl}/inscriptions/$id');
      final Map<String, dynamic> data = {};
      if (classeId != null) data['classe_id'] = classeId;
      if (anneeScolaireId != null) data['annee_scolaire_id'] = anneeScolaireId;
      if (statut != null) data['statut'] = statut;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteInscription(int id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final url = Uri.parse('${Constants.baseUrl}/inscriptions/$id');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================
  //      PASSER EN CLASSE SUPÉRIEURE
  // ============================

  static Future<Map<String, dynamic>> passerEnClasseSuperieure({
    required int eleveId,
    required int nouvelleClasseId,
    required int nouvelleAnneeScolaireId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      // 1. Récupérer l'inscription active
      final inscriptions = await getInscriptionsByEleve(eleveId);
      if (inscriptions['success'] != true) {
        return {'success': false, 'message': 'Impossible de récupérer les inscriptions'};
      }

      final List<dynamic> data = inscriptions['data'];
      final activeInscription = data.firstWhere(
        (ins) => ins['statut'] == 'actif',
        orElse: () => null,
      );

      if (activeInscription == null) {
        return {'success': false, 'message': 'Aucune inscription active trouvée'};
      }

      // 2. Désactiver l'ancienne
      final updateResponse = await updateInscription(
        id: activeInscription['id'],
        statut: 'transféré',
      );
      if (updateResponse['success'] != true) {
        return {'success': false, 'message': 'Erreur lors de la désactivation'};
      }

      // 3. Créer la nouvelle inscription
      return await createInscription(
        eleveId: eleveId,
        classeId: nouvelleClasseId,
        anneeScolaireId: nouvelleAnneeScolaireId,
        statut: 'actif',
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}