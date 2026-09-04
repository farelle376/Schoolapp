// lib/services/annee_scolaire_service.dart

import 'api_service.dart';
import '../model/annee_scolaire_model.dart';

class AnneeScolaireService {
  final ApiService _api = ApiService();

  // ============================================================
  //  Helpers de conversion de date
  // ============================================================

  /// Convertit une date (String ou DateTime) en DateTime
  DateTime _toDateTime(dynamic date) {
    if (date == null) return DateTime(1970);
    if (date is DateTime) return date;
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      return parsed ?? DateTime(1970);
    }
    return DateTime(1970);
  }

  /// Vérifie si une année est valide (et existe)
  bool _isValidDate(DateTime date) => date.year > 2000;

  // ============================================================
  //  Récupération des années scolaires
  // ============================================================

  Future<List<AnneeScolaire>> getAnneesScolaires() async {
    final response = await _api.get('/annees-scolaires');
    if (response['success'] == true) {
      final data = response['data'] as List;
      return data.map((json) => AnneeScolaire.fromJson(json)).toList();
    }
    return [];
  }

  Future<AnneeScolaire?> getAnneeEnCours() async {
    // ⚠️ ApiService._handleResponse lève une Exception pour tout code HTTP
    // hors 2xx/401/403 — un 404 "Aucune année en cours" (cas normal en
    // dehors d'une année scolaire configurée) fait donc planter cet appel
    // au lieu de retourner {success:false}. Plusieurs écrans (gestbulletin,
    // gestion_notes_admin_page) appellent cette méthode sans try/catch et
    // comptent sur un simple null en cas d'échec : on l'intercepte donc ici,
    // une bonne fois pour toutes, pour que la méthode tienne sa signature
    // Future<AnneeScolaire?> même quand le serveur répond 404.
    try {
      final response = await _api.get('/annees-scolaires/en-cours');
      if (response['success'] == true && response['data'] != null) {
        return AnneeScolaire.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> getAnneeEnCoursId() async {
    final annee = await getAnneeEnCours();
    return annee?.id;
  }

  Future<AnneeScolaire?> getAnneeScolaireById(int id) async {
    final response = await _api.get('/annees-scolaires/$id');
    if (response['success'] == true && response['data'] != null) {
      return AnneeScolaire.fromJson(response['data']);
    }
    return null;
  }

  /// ✅ Vérifie si une année scolaire est active
  Future<bool> isAnneeEnCours(int id) async {
    final annee = await getAnneeScolaireById(id);
    if (annee == null) return false;

    final now = DateTime.now();
    final dateDebut = _toDateTime(annee.dateDebut);
    final dateFin = _toDateTime(annee.dateFin);

    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  // ============================================================
  //  Gestion CRUD
  // ============================================================

  Future<Map<String, dynamic>> createAnneeScolaire({
    required String libelle,
    required String dateDebut,
    required String dateFin,
  }) async {
    return await _api.post('/annees-scolaires', {
      'libelle': libelle,
      'date_debut': dateDebut,
      'date_fin': dateFin,
    });
  }

  Future<Map<String, dynamic>> updateAnneeScolaire({
    required int id,
    required String libelle,
    required String dateDebut,
    required String dateFin,
  }) async {
    return await _api.put('/annees-scolaires/$id', {
      'libelle': libelle,
      'date_debut': dateDebut,
      'date_fin': dateFin,
    });
  }

  Future<Map<String, dynamic>> deleteAnneeScolaire(int id) async {
    return await _api.delete('/annees-scolaires/$id');
  }

  // ============================================================
  //  Méthodes utilitaires
  // ============================================================

  Future<int> getDefaultAnneeId() async {
    final anneeEnCours = await getAnneeEnCours();
    if (anneeEnCours != null) return anneeEnCours.id;

    final annees = await getAnneesScolaires();
    if (annees.isNotEmpty) {
      annees.sort((a, b) {
        final dateA = _toDateTime(a.dateDebut);
        final dateB = _toDateTime(b.dateDebut);
        return dateB.compareTo(dateA);
      });
      return annees.first.id;
    }
    return 0;
  }

  Future<List<AnneeScolaire>> getAnneesTriees() async {
    final annees = await getAnneesScolaires();
    annees.sort((a, b) {
      final dateA = _toDateTime(a.dateDebut);
      final dateB = _toDateTime(b.dateDebut);
      return dateB.compareTo(dateA);
    });
    return annees;
  }
}