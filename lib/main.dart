// lib/main.dart

import 'package:flutter/material.dart';
import 'simulationpage.dart';
import 'acceuil.dart';
import 'parentloginpage.dart';
import 'childrenlistpage.dart';
import 'services/api_service.dart';
import 'services/admin_auth_service.dart';
import 'utils/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'provider/settings_provider.dart';
import 'teacherloginpage.dart';
import 'teacherdashbordpage.dart';
import 'adminloginpage.dart';
import 'admindashbordpage.dart';
import 'utils/app_theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MyApp(),
    ),
    );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      title: 'SchoolApp Benin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: SimulationPage(),
      routes: {
        '/accueil': (context) => AccueilPage(),
        '/professeur/login': (context) => TeacherLoginPage(),
        '/professeur/dashboard': (context) => TeacherDashboardPage(),
        '/admin/login': (context) => AdminLoginPage(),
        '/admin/dashboard': (context) => AdminDashboardPage(),
      },
    );
  }

  //theme clair

 final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF0D2B4E),
  scaffoldBackgroundColor: const Color(0xFFF5F7FB),
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D2B4E),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF47C3C),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Color(0xFFF47C3C),
    unselectedItemColor: Colors.grey,
  ),
);

/// Thème sombre
final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.grey.shade900,
  scaffoldBackgroundColor: Colors.grey.shade900,
  cardColor: Colors.grey.shade800,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey.shade800,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF47C3C),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.grey.shade900,
    selectedItemColor: const Color(0xFFF47C3C),
    unselectedItemColor: Colors.grey.shade500,
  ),
);
}

// Fonction pour vérifier la connexion (à utiliser dans les pages)
Future<Map<String, dynamic>?> checkLoginStatus() async {
  final apiService = ApiService();
  await apiService.reloadToken();
  
  if (apiService.authToken != null) {
    final parentData = await apiService.getParentData();
    return parentData;
  }
  return null;
}