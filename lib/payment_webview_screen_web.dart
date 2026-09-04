// lib/screens/payment_webview_screen_web.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int paiementId;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.paiementId,
  }) : super(key: key);

  @override
  _PaymentWebViewScreenState createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final ApiService _api = ApiService(); 
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _openPaymentPage();
  }

  Future<void> _openPaymentPage() async {
    final url = Uri.parse(widget.paymentUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
    
    // Démarrer la vérification périodique
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Vérifier toutes les 3 secondes si le paiement est fait
    Future.delayed(const Duration(seconds: 3), _checkPaymentStatus);
  }

  Future<void> _checkPaymentStatus() async {
    if (_checking) return;
    _checking = true;
    
    try {
      final response = await _api.get('/parent/check-payment/${widget.paiementId}');
      
      if (response['success'] == true && response['paid'] == true) {
        Navigator.pop(context, {'success': true, 'paiement_id': widget.paiementId});
      } else {
        // Continuer à vérifier
        _checking = false;
        _startPeriodicCheck();
      }
    } catch (e) {
      _checking = false;
      _startPeriodicCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: const Color(0xFF0D2B4E),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Paiement en cours...'),
            Text('Vérification automatique'),
          ],
        ),
      ),
    );
  }
}