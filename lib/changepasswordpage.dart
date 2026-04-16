// lib/changepasswordpage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/constants.dart';
import 'services/auth_service.dart';
import 'teacherdashbordpage.dart';

class ChangePasswordPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const ChangePasswordPage({
    Key? key,
    required this.user,
    required this.token,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  final TextEditingController _confirmCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _obscureCode = true;
  bool _obscureConfirmCode = true;

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Veuillez entrer votre mot de passe actuel', Colors.orange);
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un nouveau mot de passe', Colors.orange);
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showSnackBar('Le mot de passe doit contenir au moins 8 caractères', Colors.orange);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe correspondent pas', Colors.red);
      return;
    }

    // Validation code secret
    if (_newCodeController.text.isEmpty) {
      _showSnackBar('Veuillez entrer un nouveau code secret', Colors.orange);
      return;
    }

    if (_newCodeController.text.length < 4) {
      _showSnackBar('Le code secret doit contenir au moins 4 caractères', Colors.orange);
      return;
    }

    if (_newCodeController.text != _confirmCodeController.text) {
      _showSnackBar('Les codes secrets ne correspondent pas', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${Constants.baseUrl}/professeur/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'new_password_confirmation': _confirmPasswordController.text,
          'new_code': _newCodeController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Mot de passe modifié avec succès !', Colors.green);
        
        // Naviguer vers le dashboard après 1 seconde
        Future.delayed(Duration(seconds: 5), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboardPage(
                user: {...widget.user, 'first_login': false},
              ),
            ),
          );
        });
      } else {
        _showSnackBar(data['message'] ?? 'Erreur', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF47C3C).withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 35,
                          color: Color(0xFFF47C3C),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Changer votre mot de passe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2B4E),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pour des raisons de sécurité, veuillez changer votre mot de passe et votre code secret.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 25),
                      
                      // ========== SECTION MOT DE PASSE ==========
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock, size: 18, color: Color(0xFFF47C3C)),
                                SizedBox(width: 8),
                                Text(
                                  'Changement du mot de passe',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            
                            // Mot de passe actuel
                            TextField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe actuel',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // Nouveau mot de passe
                            TextField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              decoration: InputDecoration(
                                labelText: 'Nouveau mot de passe',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                helperText: 'Minimum 6 caractères',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // Confirmation
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // ========== SECTION CODE SECRET ==========
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pin, size: 18, color: Color(0xFFF47C3C)),
                                SizedBox(width: 8),
                                Text(
                                  'Changement du code secret',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            
                            // Nouveau code secret
                            TextField(
                              controller: _newCodeController,
                              obscureText: _obscureCode,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Nouveau code secret',
                                prefixIcon: Icon(Icons.pin),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCode ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureCode = !_obscureCode),
                                ),
                                helperText: 'Minimum 4 chiffres',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // Confirmation du code secret
                            TextField(
                              controller: _confirmCodeController,
                              obscureText: _obscureConfirmCode,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le code secret',
                                prefixIcon: Icon(Icons.pin),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmCode ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirmCode = !_obscureConfirmCode),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 25),
                      
                      // Bouton
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF47C3C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'ENREGISTRER LES MODIFICATIONS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
