// lib/screens/kkiapay_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';

class KkiapayPaymentScreen extends StatelessWidget {
  final String amount;
  final String phone;
  final String name;
  final String email;
  final int trancheId;

  const KkiapayPaymentScreen({
    Key? key,
    required this.amount,
    required this.phone,
    required this.name,
    required this.email,
    required this.trancheId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int amountInt = int.tryParse(amount) ?? 0;
    final String publicKey = 'pk_sandbox_960371602f3b11f1b660e30066998a0e';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement KKiaPay'),
        backgroundColor: const Color(0xFF0D2B4E),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Montant à payer',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$amountInt FCFA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF47C3C),
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Nom', name),
                    const SizedBox(height: 8),
                    _buildInfoRow('Email', email),
                    const SizedBox(height: 8),
                    _buildInfoRow('Téléphone', phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KKiaPay(
                      amount: amountInt,
                      apikey: publicKey,
                      sandbox: true,
                      name: name,
                      phone: phone,
                      email: email,
                      // Callback avec 2 paramètres (response, context)
                      callback: (response, ctx) {
                        print('Callback: $response');
                        // Fermer la page KKiaPay
                        Navigator.pop(ctx);
                        // Retourner le résultat à la page précédente
                        Navigator.pop(context, {
                          'success': response['status'] == 'SUCCESS',
                          'transactionId': response['transactionId'],
                          'trancheId': trancheId,
                        });
                      },
                      theme: "#0D2B4E",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'PAYER ${amountInt.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}