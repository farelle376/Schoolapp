// lib/screens/bulletin_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_bulletin_service.dart';

class BulletinDetailScreen extends StatefulWidget {
  final int eleveId;
  final String eleveNom;
  final String classe;
  final String trimestre;

  const BulletinDetailScreen({
    Key? key,
    required this.eleveId,
    required this.eleveNom,
    required this.classe,
    required this.trimestre,
  }) : super(key: key);

  @override
  _BulletinDetailScreenState createState() => _BulletinDetailScreenState();
}

class _BulletinDetailScreenState extends State<BulletinDetailScreen> {
  final AdminBulletinService _service = AdminBulletinService();
  
  Map<String, dynamic> _bulletinData = {};
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isExporting = false;
  String? _error;
  String? _generationMessage;

  @override
  void initState() {
    super.initState();
    _checkAndGenerateBulletin();
  }

  Future<void> _checkAndGenerateBulletin() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _generationMessage = null;
    });

    try {
      final checkResult = await _service.checkNotesDisponibles(
        widget.eleveId, 
        widget.trimestre
      );
      
      if (!checkResult['toutes_disponibles']) {
        String message = '⚠️ Impossible de générer le bulletin\n\n';
        message += 'Toutes les notes ne sont pas encore disponibles.\n\n';
        message += 'Pour chaque matière, il faut :\n';
        message += '• 3 notes d\'interrogation\n';
        message += '• 2 notes de devoir\n\n';
        message += 'Détails des matières :\n';
        
        for (var detail in checkResult['details']) {
          String status = detail['est_disponible'] ? '✅' : '❌';
          message += '\n$status ${detail['matiere_nom']}\n';
          message += '   Interrogations: ${detail['nb_interrogations']}/3\n';
          message += '   Devoirs: ${detail['nb_devoirs']}/2\n';
        }
        
        setState(() {
          _error = message;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _generationMessage = '✅ Toutes les notes sont disponibles !\nGénération du bulletin en cours...';
      });
      
      final result = await _service.generateBulletin(
        widget.eleveId, 
        widget.trimestre
      );
      
      if (result['success']) {
        setState(() {
          _bulletinData = result['data'];
          _generationMessage = '✅ Bulletin généré avec succès !';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPDF() async {
    if (_bulletinData.isEmpty) return;
    
    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    'ÉCOLE SCHOOLAPP',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'BULLETIN DE NOTES',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
                  ),
                  pw.Divider(height: 20, thickness: 2, color: PdfColors.orange700),
                ],
              ),
            ),
            
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  _buildInfoRow('Élève', '${_bulletinData['eleve_prenom']} ${_bulletinData['eleve_nom']}'),
                  _buildInfoRow('Classe', _bulletinData['classe']),
                  _buildInfoRow('Trimestre', 'Trimestre ${_bulletinData['trimestre']}'),
                  _buildInfoRow('Rang', '${_bulletinData['rang']}/${_bulletinData['total_eleves']}'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildHeaderCell('Matière', textColor: PdfColors.white),
                    _buildHeaderCell('Interrogations', textColor: PdfColors.white),
                    _buildHeaderCell('Devoirs', textColor: PdfColors.white),
                    _buildHeaderCell('Moyenne', textColor: PdfColors.white),
                    _buildHeaderCell('Moy. Classe', textColor: PdfColors.white),
                    _buildHeaderCell('Coef', textColor: PdfColors.white),
                    _buildHeaderCell('Appréciation', textColor: PdfColors.white),
                  ],
                ),
                
                ...(_bulletinData['matieres'] as List).map((matiere) {
                  final noteValue = matiere['moyenne_eleve'] ?? 0;
                  final noteColor = noteValue >= 10 ? PdfColors.green : PdfColors.red;
                  
                  String interrogations = '';
                  for (var interro in matiere['interrogations']) {
                    interrogations += '${interro['note']} ';
                  }
                  if (interrogations.isEmpty) interrogations = '-';
                  
                  String devoirs = '';
                  for (var devoir in matiere['devoirs']) {
                    devoirs += '${devoir['note']} ';
                  }
                  if (devoirs.isEmpty) devoirs = '-';
                  
                  return pw.TableRow(
                    children: [
                      _buildCell(matiere['matiere_nom']),
                      _buildCell(interrogations.trim()),
                      _buildCell(devoirs.trim()),
                      _buildCell(matiere['moyenne_eleve'].toString(), style: pw.TextStyle(color: noteColor, fontWeight: pw.FontWeight.bold)),
                      _buildCell(matiere['moyenne_classe'].toString()),
                      _buildCell(matiere['coefficient'].toString()),
                      _buildCell(matiere['appreciation']),
                    ],
                  );
                }),
                
                pw.TableRow(
                  children: [
                    _buildCell('MOYENNE GÉNÉRALE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), colSpan: 6),
                    _buildCell(
                      _bulletinData['moyenne_generale'].toString(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                    ),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Mention :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_bulletinData['mention'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange700)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Appréciation :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(_bulletinData['appreciation']),
                ],
              ),
            ),
            
            pw.SizedBox(height: 30),
            
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
      
      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes, 
        filename: 'bulletin_${_bulletinData['eleve_prenom']}_${_bulletinData['eleve_nom']}_T${_bulletinData['trimestre']}.pdf'
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF généré avec succès'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderCell(String text, {PdfColor textColor = PdfColors.black}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: textColor)),
    );
  }

  pw.Widget _buildCell(String text, {pw.TextStyle? style, int colSpan = 1}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(text, style: style ?? pw.TextStyle()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bulletin - ${widget.eleveNom}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        actions: [
          if (_bulletinData.isNotEmpty)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _isExporting ? null : _exportPDF,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (_generationMessage != null)
                    Text(
                      _generationMessage!,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorWidget()
              : _bulletinData.isEmpty
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : _buildBulletinContent(),
    );
  }

  Widget _buildBulletinContent() {
    final matieres = _bulletinData['matieres'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('BULLETIN DE NOTES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('${_bulletinData['eleve_prenom']} ${_bulletinData['eleve_nom']}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                Text(_bulletinData['classe'], style: const TextStyle(fontSize: 12, color: Colors.white60)),
                Text('Trimestre ${_bulletinData['trimestre']}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rang: ${_bulletinData['rang']}/${_bulletinData['total_eleves']}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tableau des notes - CORRECTION ICI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text('Matière', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Interros', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Devoirs', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Moyenne', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Moy. Classe', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Coef', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Appréciation', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: matieres.map((matiere) {
                final noteValue = matiere['moyenne_eleve'] ?? 0;
                final noteColor = noteValue >= 10 ? Colors.green : Colors.red;
                
                String interrogations = '';
                for (var interro in matiere['interrogations']) {
                  interrogations += '${interro['note']} ';
                }
                if (interrogations.isEmpty) interrogations = '-';
                
                String devoirs = '';
                for (var devoir in matiere['devoirs']) {
                  devoirs += '${devoir['note']} ';
                }
                if (devoirs.isEmpty) devoirs = '-';
                
                return DataRow(cells: [
                  DataCell(Text(matiere['matiere_nom'])),
                  DataCell(Text(interrogations.trim())),
                  DataCell(Text(devoirs.trim())),
                  DataCell(
                    Text(
                      matiere['moyenne_eleve'].toString(),
                      style: TextStyle(color: noteColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(matiere['moyenne_classe'].toString())),
                  DataCell(Text(matiere['coefficient'].toString())),
                  DataCell(Text(matiere['appreciation'])),
                ]);
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Moyenne générale
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Moyenne générale :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _bulletinData['moyenne_generale'].toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mention et Appréciation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mention :', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_bulletinData['mention'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Appréciation :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_bulletinData['appreciation']),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton export PDF
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPDF,
              icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isExporting ? 'Génération du PDF...' : 'EXPORTER LE BULLETIN EN PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange[700]),
          const SizedBox(height: 20),
          Text(
            'Notes insuffisantes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange[700]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}