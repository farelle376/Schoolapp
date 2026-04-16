// lib/services/export_pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class ExportPdfService {
  
  static Future<void> exportElevesToPdf(List<Map<String, dynamic>> eleves, String className) async {
    try {
      // Créer un document PDF
      final pdf = pw.Document();
      
      // Ajouter une page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.landscape,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            // En-tête
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SchoolApp Benin',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Liste des élèves - Classe: $className',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),
            // Tableau des élèves
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FixedColumnWidth(40),   // N°
                1: pw.FixedColumnWidth(100),  // Matricule
                2: pw.FixedColumnWidth(100),  // Nom
                3: pw.FixedColumnWidth(100),  // Prénom
                4: pw.FixedColumnWidth(50),   // Sexe
                5: pw.FlexColumnWidth(),       // Autres
              },
              children: [
                // En-tête du tableau
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                  ),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('N°', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Matricule', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Nom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Prénom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Sexe', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Infos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Lignes des élèves
                ...eleves.asMap().entries.map((entry) {
                  final index = entry.key;
                  final eleve = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${index + 1}'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(eleve['matricule'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(eleve['nom'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(eleve['prenom'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(eleve['sexe'] == 'M' ? 'M' : 'F'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            // Pied de page
            pw.Center(
              child: pw.Text(
                'Document généré par SchoolApp - ${DateTime.now().year}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      );
      
      // Sauvegarder le PDF
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/liste_eleves_$className.pdf");
      await file.writeAsBytes(await pdf.save());
      
      // Partager/imprimer le PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'liste_eleves_$className.pdf',
      );
      
    } catch (e) {
      print('Erreur PDF: $e');
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }
}