// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'Français';
  bool _notifications = true;
  bool _autoBackup = true;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  Locale get locale => _getLocale(_language);
  bool get notifications => _notifications;
  bool get autoBackup => _autoBackup;

  SettingsProvider() {
    _loadSettings();
  }

  Locale _getLocale(String lang) {
    switch (lang) {
      case 'en': return const Locale('en');
      case 'es': return const Locale('es');
      default: return const Locale('fr');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _language = prefs.getString('language') ?? 'Français';
    _notifications = prefs.getBool('notifications') ?? true;
    _autoBackup = prefs.getBool('autoBackup') ?? true;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    notifyListeners();
  }

  Future<void> toggleAutoBackup(bool value) async {
    _autoBackup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoBackup', value);
    notifyListeners();
  }
}