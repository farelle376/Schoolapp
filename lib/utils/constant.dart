// lib/utils/constants.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class Constants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  // Endpoints parents
  static const String requestCode = '/parent/request-code';
  static const String verifyCode = '/parent/verify-code';
  static const String resendCode = '/parent/resend-code';
  
  // Endpoints professeurs
  static const String loginProfesseur = '/login-professeur';
  static const String logout = '/professeur/logout';
  static const String profile = '/professeur/profile';
  static const String forgotPasswordProfesseur = '/professeur/forgot-password';
  static const String verifyCodeProfesseur = '/professeur/verify-code';
  static const String resetPasswordProfesseur = '/professeur/reset-password';
  static const String classes = '/professeur/classes';
  static const String notes = '/professeur/notes';
  static const String emploiDuTemps = '/professeur/emploi-du-temps';
  
  // Endpoints Admin
  static const String adminLogin = '/admin/login';
  static const String adminLogout = '/admin/logout';
  static const String adminMe = '/admin/me';
  static const String adminCheck = '/admin/check';
  


  // Shared Preferences Keys
  static const String authTokenKey = 'auth_token';      // ← AJOUTEZ CETTE LIGNE
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String userTypeKey = 'user_type';
  static const String adminToken = 'admin_token';
  static const String adminData = 'admin_data';

}