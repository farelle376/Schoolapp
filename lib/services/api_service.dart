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
    // Charger automatiquement le token à l'initialisation
    _loadToken();
  }

  String? _authToken;

  String get baseUrl => Constants.baseUrl;
  
  String? get authToken => _authToken;
  
  set authToken(String? token) {
    _authToken = token;
    if (token != null) {
      _saveToken(token);
    }
  }

  // Charger le token au démarrage
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(Constants.authToken);
    print('🔑 [ApiService] Token chargé: ${_authToken != null ? "Oui (${_authToken!.substring(0, 20)}...)" : "Non"}');
  }

  // Méthode publique pour recharger le token
  Future<void> reloadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(Constants.authToken);
    print('🔑 [ApiService] reloadToken: ${_authToken != null ? "Oui" : "Non"}');
  }

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
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.authToken, token);
    print('🔑 [ApiService] Token sauvegardé: ${token.substring(0, 20)}...');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.authToken, token);
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

  Future<Map<String, dynamic>> get(String endpoint) async {
    // S'assurer que le token est chargé
    if (_authToken == null) {
      await reloadToken();
    }
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 GET: $url');
    print('🔑 Token utilisé: ${_authToken != null ? "Oui" : "NON"}');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
    );

    print('📥 Response: ${response.statusCode}');
    print('📄 Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    if (_authToken == null) {
      await reloadToken();
    }
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 POST: $url');
    print('📦 Data: $data');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
      body: json.encode(data),
    );

    print('📥 Response: ${response.statusCode}');
    print('📄 Body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    if (_authToken == null) {
      await reloadToken();
    }
    
    final url = Uri.parse('$baseUrl$endpoint');
    print('📡 PUT: $url');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      },
      body: json.encode(data),
    );

    print('📥 Response: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Constants.authToken);
    await prefs.remove('parent_data');
    await prefs.remove('parent_initiales');
    await prefs.remove('parent_prenom');
    await prefs.remove('eleve_id');
    await prefs.remove('eleve_nom');
    await prefs.remove('eleve_classe');
    print('👋 Déconnexion effectuée');
  }
}