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

  // Endpoints
   static const String sendCode = '/parent/send-code';
  static const String verifyCode = '/parent/verify-code';
  static const String requestCode = '/parent/request-code';
  static const String resendCode = '/parent/resend-code';
  static const String logout = '/parent/logout';
  static const String children = '/parent/children';
  static const String notifications = '/parent/notifications';
  static const String conversations = '/parent/conversations';
  static const String adminLogin = '/admin/login';
  static const String adminLogout = '/admin/logout';
  static const String adminMe = '/admin/me';
  static const String adminCheck = '/admin/check';

  // Shared Preferences keys
   static const String authToken = 'parent_token';
  static const String userPhone = 'user_phone';
  static const String adminToken = 'admin_token';
  static const String adminData = 'admin_data';
  static const String professeurToken = 'professeur_token';
  
  
  
  
}