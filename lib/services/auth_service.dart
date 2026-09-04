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
   Future<Map<String, dynamic>> sendProfessorResetCode(String email) async {
    try {
      final response = await _api.post('/teacher/forgot-password', {
        'email': email,
      });
      
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Code envoyé avec succès',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // 2. Vérifier le code reçu par email
  Future<Map<String, dynamic>> verifyProfessorResetCode(String email, String code) async {
    try {
      final response = await _api.post('/teacher/verify-code', {
        'email': email,
        'code': code,
      });
      
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Code valide',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de vérification: $e',
      };
    }
  }

  // 3. Réinitialiser le mot de passe avec le code
  Future<Map<String, dynamic>> resetProfessorPassword(String email, String code, String password) async {
    try {
      final response = await _api.post('/teacher/reset-password', {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password, // Laravel attend la confirmation
      });
      
      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Mot de passe réinitialisé',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la réinitialisation: $e',
      };
    }
  }
}


