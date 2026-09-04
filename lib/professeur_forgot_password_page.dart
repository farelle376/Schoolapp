// lib/screens/professeur_forgot_password_page.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfesseurForgotPasswordPage extends StatefulWidget {
  @override
  _ProfesseurForgotPasswordPageState createState() => _ProfesseurForgotPasswordPageState();
}

class _ProfesseurForgotPasswordPageState extends State<ProfesseurForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  // Remplacer le _codeController unique par 6 contrôleurs
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  int _step = 1; // 1: email, 2: code, 3: new password
  final AuthService _authService = AuthService();

  // 👁️ Pour afficher/masquer les mots de passe
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ========== MÉTHODES DE SNACKBAR (déplacées en haut) ==========
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ========== MÉTHODES MÉTIER ==========
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty) {
      _showError('Veuillez entrer votre email');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.sendProfessorResetCode(_emailController.text);
    
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 2);
      _showSuccess(result['message']);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _verifyCode() async {
    // Récupération du code depuis les 6 cases
    final String fullCode = _codeControllers.map((c) => c.text).join();
    if (fullCode.length != 6) {
      _showError('Le code doit contenir 6 chiffres');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyProfessorResetCode(
      _emailController.text,
      fullCode,
    );
    
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 3);
      _showSuccess(result['message']);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _resetPassword() async {
    final String fullCode = _codeControllers.map((c) => c.text).join();

    if (_passwordController.text.isEmpty) {
      _showError('Veuillez entrer un nouveau mot de passe');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    // Appel API réel (vous aviez un TODO, je le remplace par l'appel)
    final result = await _authService.resetProfessorPassword(
      _emailController.text,
      fullCode,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccess(result['message']);
      Future.delayed(Duration(seconds: 2), () => Navigator.pop(context));
    } else {
      _showError(result['message']);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: const Color(0xFF0D2B4E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Icon(
                Icons.lock_reset,
                size: 80,
                color: Color(0xFFF47C3C),
              ),
            ),
            const SizedBox(height: 20),
            
            // Étape 1: Email (inchangé)
            if (_step == 1) ...[
              const Text(
                'Réinitialisation du mot de passe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Entrez votre email pour recevoir un code de réinitialisation.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ENVOYER LE CODE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
            
            // ==================== ÉTAPE 2 : CODE OTP AVEC 6 CASES ====================
            if (_step == 2) ...[
              const Text(
                'Vérification du code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Un code à 6 chiffres a été envoyé à ${_emailController.text}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // ⬇️ 6 cases (cards)
         // ⬇️ 6 cases avec fond transparent et bordure uniquement
              Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(6, (index) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(
              color: _codeControllers[index].text.isNotEmpty
                  ? const Color(0xFFF47C3C) // bordure orange si rempli
                  : Colors.grey[400]!,      // bordure grise
              width: 2,
            ),
          ),
          child: TextField(
            controller: _codeControllers[index],
            focusNode: _codeFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Chiffre bien noir
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent, // ✅ Fond transparent
            ),
            onChanged: (value) {
              if (value.length == 1 && index < 5) {
                FocusScope.of(context).requestFocus(_codeFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_codeFocusNodes[index - 1]);
              }
            },
          ),
        ),
        if (index < 5) const SizedBox(width: 10),
      ],
    );
  }),
),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'VÉRIFIER LE CODE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: _sendCode,
                child: const Text('Renvoyer le code'),
              ),
            ],
            
            // ==================== ÉTAPE 3 : MOT DE PASSE AVEC ŒIL ====================
            if (_step == 3) ...[
              const Text(
                'Nouveau mot de passe',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choisissez un nouveau mot de passe sécurisé.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Champ mot de passe avec œil
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Champ confirmation avec œil
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'RÉINITIALISER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(color: Color(0xFFF47C3C)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}