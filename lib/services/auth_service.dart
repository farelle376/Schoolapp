// lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  
  // Demander un code de vérification
  Future<bool> requestCode(String phoneNumber) async {
    try {
      final response = await _api.post('/parent/request-code', {
        'phone_number': phoneNumber,
      });
      
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }
  
  // Vérifier le code OTP
  Future<Map<String, dynamic>> verifyCode(String phoneNumber, String code) async {
  try {
    print('📞 Vérification du code pour: $phoneNumber');
    print('🔑 Code: $code');
    
    final response = await _api.post('/parent/verify-code', {
      'phone_number': phoneNumber,
      'code': code,
    });
    
    print('✅ Réponse reçue: ${response.toString()}');
    
    if (response['success'] == true) {
      _api.authToken = response['token'];
      
      return {
        'success': true,
        'token': response['token'],
        'user': response['user'],
      };
    }
    
    return {
      'success': false,
      'message': response['message'] ?? 'Erreur inconnue',
    };
  } catch (e) {
    print('❌ Erreur: $e');
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}
  // Renvoyer le code
  Future<bool> resendCode(String phoneNumber) async {
    try {
      final response = await _api.post('/parent/resend-code', {
        'phone_number': phoneNumber,
      });
      
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // Déconnexion
  Future<void> logout() async {
    await _api.logout();
  }
  
  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    await _api.reloadToken();
    return _api.authToken != null;
  }
}
// lib/services/auth_service.dart

