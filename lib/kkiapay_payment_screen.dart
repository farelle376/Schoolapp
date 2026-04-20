// lib/screens/kkiapay_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KkiapayWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int paiementId;

  const KkiapayWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.paiementId,
  }) : super(key: key);

  @override
  _KkiapayWebViewScreenState createState() => _KkiapayWebViewScreenState();
}

class _KkiapayWebViewScreenState extends State<KkiapayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => setState(() => _isLoading = false),
          onUrlChange: (change) {
            if (change.url?.contains('schoolapp://payment/success') == true) {
              Navigator.pop(context, {'success': true, 'paiement_id': widget.paiementId});
            } else if (change.url?.contains('schoolapp://payment/cancel') == true) {
              Navigator.pop(context, {'success': false});
            } else if (change.url?.contains('schoolapp://payment/error') == true) {
              Navigator.pop(context, {'success': false});
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: const Color(0xFF0D2B4E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de la page de paiement...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}