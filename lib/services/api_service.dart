// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _loadToken();
  }

  String? _authToken;
  String? _tokenType; // 'admin', 'parent', 'professeur'

  String get baseUrl => Constants.baseUrl;
  String? get authToken => _authToken;
  String? get tokenType => _tokenType;

  set authToken(String? token) {
    if (token != null) {
      _authToken = token;
      // Détection automatique du type
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) {
        // Vérifier si c'est un token admin
        if (p.getString(Constants.adminToken) == token) {
          _tokenType = 'admin';
        } else if (p.getString(Constants.professeurToken) == token) {
          _tokenType = 'professeur';
        } else {
          _tokenType = 'parent';
        }
      });
      print('🔑 [ApiService] authToken set (compatibilité): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    } else {
      _authToken = null;
      _tokenType = null;
    }
  }

  // ============================================================
  //  Gestion du token (RECHERCHE SUR TOUTES LES CLÉS)
  // ============================================================
  
  /// Charge le token depuis SharedPreferences.
  ///
  /// ⚠️ Avant, ce code donnait TOUJOURS la priorité au token admin s'il
  /// existait en storage, peu importe quelle session s'est connectée en
  /// dernier — un token admin sauvegardé une fois (test précédent, jamais
  /// nettoyé) écrasait silencieusement n'importe quelle connexion parent ou
  /// professeur faite ensuite (ex: parent se connecte, mais l'app continue
  /// d'utiliser l'ancien token admin -> erreurs 500 style "Call to
  /// undefined method Utilisateur::eleves()"). On tracke maintenant
  /// explicitement le type de la DERNIÈRE session active (clé
  /// 'active_token_type', mise à jour à chaque saveToken()) au lieu de
  /// deviner par un ordre de priorité fixe.
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    final activeType = prefs.getString('active_token_type');
    if (activeType != null) {
      final key = switch (activeType) {
        'admin' => Constants.adminToken,
        'parent' => Constants.authToken,
        'professeur' => Constants.professeurToken,
        _ => null,
      };
      final token = key != null ? prefs.getString(key) : null;
      if (token != null) {
        _authToken = token;
        _tokenType = activeType;
      } else {
        // La session active référencée n'a plus de token en storage
        // (déconnexion partielle) : on ne devine pas, session absente.
        _authToken = null;
        _tokenType = null;
      }
    } else {
      // Compatibilité : aucune session active trackée (ancienne install de
      // l'app, avant ce fix) — on retombe sur l'ancien comportement de
      // recherche, en dernier recours seulement.
      _authToken = prefs.getString(Constants.adminToken) ??
                   prefs.getString(Constants.authToken) ??
                   prefs.getString(Constants.professeurToken);

      if (prefs.containsKey(Constants.adminToken)) {
        _tokenType = 'admin';
      } else if (prefs.containsKey(Constants.authToken)) {
        _tokenType = 'parent';
      } else if (prefs.containsKey(Constants.professeurToken)) {
        _tokenType = 'professeur';
      } else {
        _tokenType = null;
      }
    }

    if (_authToken != null) {
      final preview = _authToken!.length > 20 
          ? '${_authToken!.substring(0, 20)}...' 
          : _authToken!;
      print('🔑 [ApiService] Token chargé: ✅ Oui (type: $_tokenType)');
      print('🔑 [ApiService] Token (début): $preview');
    } else {
      print('🔑 [ApiService] Token chargé: ❌ Non');
    }
  }

  /// Recharge le token depuis SharedPreferences
  Future<void> reloadToken() async {
    await _loadToken();
  }

  // ============================================================
  //  Sauvegarde du token (avec type)
  // ============================================================
  
  /// Sauvegarde un token avec son type
  Future<void> saveToken(String token, {String type = 'parent'}) async {
    _authToken = token;
    _tokenType = type;
    final prefs = await SharedPreferences.getInstance();
    
    switch (type) {
      case 'admin':
        await prefs.setString(Constants.adminToken, token);
        break;
      case 'parent':
        await prefs.setString(Constants.authToken, token);
        break;
      case 'professeur':
        await prefs.setString(Constants.professeurToken, token);
        break;
      default:
        await prefs.setString(Constants.authToken, token);
    }

    // ⚠️ Indispensable pour que _loadToken() sache quelle session est la
    // plus récente/active — sans cette ligne, 'active_token_type' ne serait
    // jamais écrit et _loadToken() retomberait toujours sur l'ancien
    // comportement de devinette par priorité fixe.
    await prefs.setString('active_token_type', type);

    final preview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
    print('🔑 [ApiService] Token sauvegardé (type: $type): $preview');
  }

  /// Sauvegarde spécifiquement un token admin
  Future<void> saveAdminToken(String token) async {
    await saveToken(token, type: 'admin');
  }

  /// Sauvegarde un token parent (compatibilité)
  Future<void> saveParentToken(String token) async {
    await saveToken(token, type: 'parent');
  }

  /// Sauvegarde un token professeur
  Future<void> saveProfesseurToken(String token) async {
    await saveToken(token, type: 'professeur');
  }

  // ============================================================
  //  Récupération du token par type
  // ============================================================
  
  /// Récupère le token admin
  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.adminToken);
  }

  /// Récupère le token parent
  Future<String?> getParentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.authToken);
  }

  /// Récupère le token professeur
  Future<String?> getProfesseurToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(Constants.professeurToken);
  }

  // ============================================================
  //  Vérification du token
  // ============================================================
  
  /// Vérifie si un token est présent
  bool hasToken() => _authToken != null;

  /// Vérifie si le token est de type admin
  bool isAdminToken() => _tokenType == 'admin';

  /// Vérifie si le token est de type parent
  bool isParentToken() => _tokenType == 'parent';

  /// Vérifie si le token est de type professeur
  bool isProfesseurToken() => _tokenType == 'professeur';

  // ============================================================
  //  Méthodes HTTP avec token
  // ============================================================
  
  /// Headers avec token
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// S'assure que le token est chargé
  Future<void> _ensureToken() async {
    if (_authToken == null) {
      await reloadToken();
    }
    if (_authToken == null) {
      throw Exception('Aucun token trouvé. Veuillez vous connecter.');
    }
  }

  // ============================================================
  //  REQUÊTES HTTP
  // ============================================================

  /// Requête GET
  Future<Map<String, dynamic>> get(String endpoint) async {
    await _ensureToken();
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 GET: $url');
    print('🔑 Token: ${_authToken != null ? "✅ ($_tokenType)" : "❌"}');

    final response = await http.get(url, headers: _headers);
    print('📥 Status: ${response.statusCode}');

    return _handleResponse(response);
  }

  /// Requête POST
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    await _ensureToken();
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 POST: $url');
    print('🔑 Token: ${_authToken != null ? "✅ ($_tokenType)" : "❌"}');
    print('📦 Data: $data');

    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode(data),
    );
    print('📥 Status: ${response.statusCode}');

    return _handleResponse(response);
  }

  /// Requête PUT
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    await _ensureToken();
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 PUT: $url');
    print('🔑 Token: ${_authToken != null ? "✅ ($_tokenType)" : "❌"}');

    final response = await http.put(
      url,
      headers: _headers,
      body: json.encode(data),
    );
    print('📥 Status: ${response.statusCode}');

    return _handleResponse(response);
  }

  /// Requête PATCH
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    await _ensureToken();
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 PATCH: $url');
    print('🔑 Token: ${_authToken != null ? "✅ ($_tokenType)" : "❌"}');

    final response = await http.patch(
      url,
      headers: _headers,
      body: json.encode(data),
    );
    print('📥 Status: ${response.statusCode}');

    return _handleResponse(response);
  }

  /// Requête DELETE
  Future<Map<String, dynamic>> delete(String endpoint) async {
    await _ensureToken();
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 DELETE: $url');
    print('🔑 Token: ${_authToken != null ? "✅ ($_tokenType)" : "❌"}');

    final response = await http.delete(url, headers: _headers);
    print('📥 Status: ${response.statusCode}');

    return _handleResponse(response);
  }

  // ============================================================
  //  Gestion des réponses
  // ============================================================

  /// Extrait le message d'erreur renvoyé par le backend (`{'message': ...}`),
  /// pour éviter d'afficher un message générique qui masque la vraie raison
  /// (ex: "Code secret incorrect" vs "Vous n'êtes pas autorisé à noter cette
  /// classe" sont tous les deux des 403, mais ne se corrigent pas pareil).
  String? _extractBackendMessage(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Corps non-JSON : on ignore, le message générique prendra le relais.
    }
    return null;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}...'
        : response.body;
    print('📄 Body: $bodyPreview');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      print('⚠️ Token expiré ou invalide');
      await logout();
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (response.statusCode == 403) {
      print('⛔ Accès interdit');
      final backendMessage = _extractBackendMessage(response);
      throw Exception(backendMessage ?? 'Vous n\'avez pas les droits nécessaires.');
    } else {
      final backendMessage = _extractBackendMessage(response);
      throw Exception(backendMessage ?? 'Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // ============================================================
  //  Déconnexion
  // ============================================================
  
  /// Déconnexion complète (supprime tous les tokens)
  Future<void> logout() async {
    _authToken = null;
    _tokenType = null;
    final prefs = await SharedPreferences.getInstance();
    
    // Supprimer tous les tokens
    await prefs.remove(Constants.adminToken);
    await prefs.remove(Constants.authToken);
    await prefs.remove(Constants.professeurToken);
    await prefs.remove('active_token_type');

    // Supprimer les données parents
    await prefs.remove('parent_data');
    await prefs.remove('parent_initiales');
    await prefs.remove('parent_prenom');
    await prefs.remove('parent_nom');
    await prefs.remove('enfants');
    await prefs.remove('eleve_id');
    await prefs.remove('eleve_nom');
    await prefs.remove('eleve_classe');
    
    print('👋 Déconnexion effectuée (tous les tokens supprimés)');
  }

  /// Déconnexion d'un type spécifique
  Future<void> logoutType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (type) {
      case 'admin':
        await prefs.remove(Constants.adminToken);
        break;
      case 'parent':
        await prefs.remove(Constants.authToken);
        break;
      case 'professeur':
        await prefs.remove(Constants.professeurToken);
        break;
    }
    
    if (_tokenType == type) {
      _authToken = null;
      _tokenType = null;
      // On ne veut pas qu'une future _loadToken() retrouve cette session
      // qu'on vient explicitement de fermer.
      await prefs.remove('active_token_type');
    }

    print('👋 Déconnexion type: $type');
  }

  // ============================================================
  //  MÉTHODES SPÉCIFIQUES PARENT (compatibilité)
  // ============================================================

  Future<Map<String, dynamic>> getTranchesPaiement(int eleveId) async {
    return await get('/parent/children/$eleveId/tranches-paiement');
  }

  Future<Map<String, dynamic>> getHistoriquePaiements(int eleveId) async {
    return await get('/parent/children/$eleveId/historique-paiements');
  }

  Future<Map<String, dynamic>> initierPaiement({
    required int trancheId,
    required String modePaiement,
    required String telephone,
  }) async {
    return await post('/parent/paiements/initier', {
      'tranche_id': trancheId,
      'mode_paiement': modePaiement,
      'telephone': telephone,
    });
  }

  Future<Uint8List?> telechargerRecu(int paiementId) async {
    final url = Uri.parse('$baseUrl/parent/paiements/$paiementId/telecharger-recu');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  Future<void> saveParentData(Map<String, dynamic> parentData) async {
    final prefs = await SharedPreferences.getInstance();
    
    print('📦 Sauvegarde parentData: $parentData');
    
    await prefs.setString('parent_data', json.encode(parentData));
    await prefs.setString('parent_initiales', parentData['initiales'] ?? '');
    await prefs.setString('parent_prenom', parentData['prenom'] ?? '');
    await prefs.setString('parent_nom', parentData['nom'] ?? '');
    
    final enfants = parentData['enfants'] ?? [];
    await prefs.setString('enfants', json.encode(enfants));
    
    if (enfants.isNotEmpty) {
      final premierEnfant = enfants[0];
      await prefs.setInt('eleve_id', premierEnfant['id'] ?? 0);
      await prefs.setString('eleve_nom', premierEnfant['nom_complet'] ?? '');
      await prefs.setString('eleve_classe', premierEnfant['classe'] ?? '');
    }
  }

  Future<Map<String, dynamic>?> getParentData() async {
    final prefs = await SharedPreferences.getInstance();
    final parentDataStr = prefs.getString('parent_data');
    if (parentDataStr != null) {
      return json.decode(parentDataStr);
    }
    return null;
  }
}