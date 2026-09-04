// lib/utils/constants.dart

// ✅ 'dart:io' a été retiré : même utilisé uniquement derrière un test
// `!kIsWeb`/`Platform.isAndroid`, l'import est résolu à la compilation et
// fait échouer TOUT build web (flutter run/build -d chrome), quel que soit
// le chemin de code réellement exécuté à l'exécution.

class Constants {
  static String get baseUrl {
    // Les 3 branches renvoyaient de toute façon la même URL : la logique
    // Platform.isAndroid (tunnel adb reverse) était du code mort.
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
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String userTypeKey = 'user_type';
  static const String adminToken = 'admin_token';
  static const String adminData = 'admin_data';

}