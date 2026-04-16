// lib/screens/otpverificationpage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';
import '../services/api_service.dart';  // ← AJOUTER CET IMPORT
import 'childrenlistpage.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final int parentId;

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.parentId,
  }) : super(key: key);

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
   final ApiService _api = ApiService();  // ← AJOUTER CETTE LIGNE
  bool _isLoading = false;
  int _timerSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    print('🔐 [OtpVerificationPage] Initialisé pour email: ${widget.email}, parent_id: ${widget.parentId}');
    _startTimer();
  }

  void _startTimer() {
    _timerSeconds = 60;
    _canResend = false;
    _updateTimer();
  }

  void _updateTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timerSeconds > 0) {
        setState(() {
          _timerSeconds--;
          _updateTimer();
        });
      } else if (mounted && _timerSeconds == 0) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {

    
    String otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      _showSnackBar('Veuillez entrer le code à 6 chiffres');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('🔐 [OtpVerificationPage] Vérification OTP: $otp pour parent_id: ${widget.parentId}');

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.verifyCode}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'parent_id': widget.parentId,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);
      
      print('📥 [OtpVerificationPage] Réponse: $data');

      if (data['success'] == true) {
         print('✅ [OtpVerificationPage] Connexion réussie');
  print('📦 Token reçu: ${data['token']}');
  
  // Sauvegarder le token avec ApiService
 await _api.saveToken(data['token']);
  
  // VÉRIFIER IMMÉDIATEMENT
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString(Constants.authToken);
  print('🔑 Token sauvegardé? ${savedToken != null ? "OUI (${savedToken.substring(0, 20)}...)" : "NON"}');
        
        // Préparer les données parent
        final parentData = {
          'id': data['parent']['id'],
          'nom': data['parent']['nom'],
          'prenom': data['parent']['prenom'],
          'email': data['parent']['email'],
          'initiales': _getInitiales(data['parent']['prenom'] ?? '', data['parent']['nom'] ?? ''),
        };
        
        print('👨‍👩‍👧 [OtpVerificationPage] Parent data: $parentData');
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildrenListPage(parentData: parentData),
          ),
        );
      } else {
        print('❌ [OtpVerificationPage] Erreur: ${data['message']}');
        _showSnackBar(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      print('❌ [OtpVerificationPage] Exception: $e');
      _showSnackBar('Erreur de connexion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitiales(String prenom, String nom) {
    String initiales = '';
    if (prenom.isNotEmpty) initiales += prenom[0].toUpperCase();
    if (nom.isNotEmpty) initiales += nom[0].toUpperCase();
    return initiales.isEmpty ? 'P' : initiales;
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    print('🔄 [OtpVerificationPage] Demande de renvoi de code pour: ${widget.email}');

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.sendCode}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        print('✅ [OtpVerificationPage] Nouveau code envoyé');
        _showSnackBar('Nouveau code envoyé par email', isError: false);
        _startTimer();
        // Vider les champs OTP
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        print('❌ [OtpVerificationPage] Erreur renvoi: ${data['message']}');
        _showSnackBar(data['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      print('❌ [OtpVerificationPage] Exception renvoi: $e');
      _showSnackBar('Erreur de connexion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2B4E),
              Color(0xFF1F4E79),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'School',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'App',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF47C3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Vérification',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Un code a été envoyé à',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 45,
                              height: 55,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.length == 1 && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF47C3C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'VÉRIFIER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canResend ? 'Vous n\'avez pas reçu le code ? ' : 'Renvoyer le code dans ${_timerSeconds}s',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_canResend)
                              TextButton(
                                onPressed: _resendCode,
                                child: const Text(
                                  'Renvoyer',
                                  style: TextStyle(
                                    color: Color(0xFFF47C3C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}