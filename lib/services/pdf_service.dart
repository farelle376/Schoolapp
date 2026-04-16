// lib/services/pdf_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static pw.Font? _openSansFont;
  static pw.Font? _openSansBoldFont;

  static Future<void> _loadFonts() async {
    if (_openSansFont == null) {
      try {
        final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
        final fontDataBold = await rootBundle.load('assets/fonts/OpenSans-Bold.ttf');
        _openSansFont = pw.Font.ttf(fontData);
        _openSansBoldFont = pw.Font.ttf(fontDataBold);
      } catch (e) {
        print('❌ Police non chargée, utilisation de la police par défaut');
      }
    }
  }

  static Future<Uint8List> generateReceiptBytes({
    required String reference,
    required String date,
    required String eleveNom,
    required String elevePrenom,
    required String classe,
    required String libelle,
    required String description,
    required double montant,
    required String modePaiement,
  }) async {
    await _loadFonts();
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          // En-tête
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Text(
                  'ÉCOLE SCHOOLAPP',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'REÇU DE PAIEMENT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700,
                  ),
                ),
                pw.Divider(height: 20, thickness: 2, color: PdfColors.orange700),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Informations
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow('Référence', reference),
                _buildInfoRow('Date', date),
                _buildInfoRow('Élève', '$elevePrenom $eleveNom'),
                _buildInfoRow('Classe', classe),
                _buildInfoRow('Libellé', libelle),
                _buildInfoRow('Mode de paiement', modePaiement),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Montant
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Montant payé :',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${montant.toStringAsFixed(0)} FCFA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          
          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('Le Chef d\'établissement'),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Le Parent'),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  // Version corrigée - Utilise Printing.sharePdf au lieu de path_provider
  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    try {
      // Utiliser Printing.sharePdf qui fonctionne sur toutes les plateformes
      await Printing.sharePdf(bytes: bytes, filename: filename);
      print('✅ PDF partagé avec succès');
    } catch (e) {
      print('❌ Erreur downloadPdf: $e');
      rethrow;
    }
  }
}