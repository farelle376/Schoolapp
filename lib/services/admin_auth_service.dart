// lib/services/admin_auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../model/admin_model.dart';

class AdminAuthService {
  static const String _tokenKey = 'admin_token';
  static const String _adminKey = 'admin_data';
  
  String? _authToken;
  AdminModel? _currentAdmin;

  String? get authToken => _authToken;
  AdminModel? get currentAdmin => _currentAdmin;

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Admin Login Response: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _authToken = data['token'];
          _currentAdmin = AdminModel.fromJson(data['user']);
          
          await _saveToken(_authToken!);
          await _saveAdminData(_currentAdmin!);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Admin Login error: $e');
      return false;
    }
  }

  // ✅ Mot de passe oublié
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse('${Constants.baseUrl}/admin/forgot-password');
      print('Forgot Password URL: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      print('Forgot Password Response: ${response.statusCode}');
      print('Body: ${response.body}');
      
      return json.decode(response.body);
    } catch (e) {
      print('Forgot Password error: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

// Vérifier le code
static Future<Map<String, dynamic>> verifyCode(String email, String code) async {
  try {
    final url = Uri.parse('${Constants.baseUrl}/admin/verify-code');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );
    
    return json.decode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Réinitialiser le mot de passe
static Future<Map<String, dynamic>> resetPassword(String email, String code, String password) async {
  try {
    final url = Uri.parse('${Constants.baseUrl}/admin/reset-password');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      }),
    );
    
    return json.decode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
  Future<void> logout() async {
    if (_authToken != null) {
      try {
        await http.post(
          Uri.parse('${Constants.baseUrl}/admin/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        );
      } catch (e) {
        print('Logout error: $e');
      }
    }
    
    _authToken = null;
    _currentAdmin = null;
    await _clearStorage();
  }

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    
    if (_authToken != null) {
      final adminData = prefs.getString(_adminKey);
      if (adminData != null) {
        _currentAdmin = AdminModel.fromJson(json.decode(adminData));
        return true;
      }
    }
    return false;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveAdminData(AdminModel admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminKey, json.encode(admin.toJson()));
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_adminKey);
  }
}