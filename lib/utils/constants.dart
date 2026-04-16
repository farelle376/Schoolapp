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
  
  
  
  
}