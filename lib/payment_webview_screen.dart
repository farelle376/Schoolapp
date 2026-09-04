// lib/screens/payment_webview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      _openInBrowser();
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => setState(() => _isLoading = false),
          // ⚠️ 'schoolapp://...' n'est pas une vraie URL web : c'est un lien
          // factice utilisé uniquement comme signal. Avant, seul
          // `onUrlChange` (qui se déclenche APRÈS la tentative de
          // navigation) l'interceptait — le WebView avait donc le temps
          // d'essayer de charger ce lien inconnu et d'afficher brièvement
          // "page web non disponible" avant d'être coupé. `onNavigationRequest`
          // se déclenche AVANT la navigation et permet de l'empêcher
          // complètement (NavigationDecision.prevent), donc plus de flash
          // d'erreur.
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('schoolapp://payment/success') && !_paymentCompleted) {
              final uri = Uri.parse(url);
              final transactionId = uri.queryParameters['transaction_id'];
              if (transactionId != null) {
                _paymentCompleted = true;
                _verifierPaiement(transactionId);
              }
              return NavigationDecision.prevent;
            }
            if (url.startsWith('schoolapp://payment/cancel') && !_paymentCompleted) {
              _paymentCompleted = true;
              Navigator.pop(context, {'success': false});
              return NavigationDecision.prevent;
            }
            // ⚠️ Échec signalé PAR LE WIDGET KKiaPay lui-même (numéro
            // invalide, fonds insuffisants...) — voir addFailedListener
            // dans kkiapay.blade.php. On informe le serveur pour qu'il
            // marque le paiement 'refuse' (sinon il resterait bloqué en
            // 'en_attente' indéfiniment), puis on distingue ce cas d'une
            // simple annulation utilisateur via 'failed': true.
            if (url.startsWith('schoolapp://payment/failed') && !_paymentCompleted) {
              final uri = Uri.parse(url);
              final paiementIdParam = uri.queryParameters['paiement_id'];
              _paymentCompleted = true;
              _marquerEchoue(paiementIdParam);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _checkingStatus = false;

  Future<void> _openInBrowser() async {
    final url = Uri.parse(widget.paymentUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      // ⚠️ On ne peut PAS savoir ici si le paiement a réellement réussi :
      // le widget KKiaPay s'ouvre dans un onglet externe, on ne reçoit
      // aucun retour direct. Avant, ce code fabriquait un faux
      // transaction_id ('test_' + timestamp) et l'envoyait tel quel au
      // serveur pour "vérification" — ce qui échouait TOUJOURS côté
      // KKiaPay (normal, ce n'est pas un vrai id), y compris pour un
      // paiement réellement réussi. On interroge maintenant le serveur en
      // boucle : c'est lui qui saura que le paiement est validé, via le
      // webhook KKiaPay (voir KKiaPayController::webhook) — qui doit être
      // joignable publiquement pour fonctionner (pas http://localhost).
      _startPeriodicCheck();
    } else {
      if (mounted) Navigator.pop(context, {'success': false});
    }
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 3), _checkPaymentStatus);
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted || _checkingStatus) return;
    _checkingStatus = true;

    try {
      final response = await _api.get('/parent/check-payment/${widget.paiementId}');

      if (response['success'] == true && response['paid'] == true) {
        if (mounted) {
          Navigator.pop(context, {
            'success': true,
            'paiement_id': widget.paiementId,
          });
        }
        return;
      }
    } catch (e) {
      print('❌ Erreur check-payment: $e');
    }

    _checkingStatus = false;
    if (mounted) _startPeriodicCheck();
  }

  Future<void> _verifierPaiement(String transactionId) async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Vérification paiement: transaction_id=$transactionId, paiement_id=${widget.paiementId}');
      
      final response = await _api.post('/parent/verifier-paiement-kkiapay', {
        'transaction_id': transactionId,
        'paiement_id': widget.paiementId,
      });
      
      print('📥 Réponse vérification: $response');
      
      if (response['success'] == true) {
        Navigator.pop(context, {
          'success': true,
          'transaction_id': transactionId,
          'paiement_id': widget.paiementId,
        });
      } else {
        Navigator.pop(context, {
          'success': false,
          'message': response['message'] ?? 'Paiement non confirmé'
        });
      }
    } catch (e) {
      print('❌ Erreur: $e');
      Navigator.pop(context, {
        'success': false,
        'message': 'Erreur lors de la vérification: $e'
      });
    }
  }

  /// Le widget KKiaPay a lui-même signalé un échec (numéro invalide, fonds
  /// insuffisants...) — on informe le serveur pour qu'il marque le paiement
  /// 'refuse' (sinon il resterait bloqué en 'en_attente' pour toujours).
  /// 'failed': true permet à l'appelant de distinguer ce cas d'une simple
  /// annulation utilisateur, pour afficher le bon message.
  Future<void> _marquerEchoue(String? paiementIdParam) async {
    try {
      final paiementId = paiementIdParam != null ? int.tryParse(paiementIdParam) : widget.paiementId;
      await _api.post('/parent/paiement-echoue', {
        'paiement_id': paiementId ?? widget.paiementId,
      });
    } catch (e) {
      print('❌ Erreur marquerEchoue: $e');
      // On informe quand même l'utilisateur même si l'appel serveur échoue :
      // le paiement n'a de toute façon pas abouti côté KKiaPay.
    } finally {
      if (mounted) {
        Navigator.pop(context, {'success': false, 'failed': true});
      }
    }
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
      body: kIsWeb
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Redirection vers la page de paiement...'),
                ],
              ),
            )
          : Stack(
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