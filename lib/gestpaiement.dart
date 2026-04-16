// lib/screens/gestpaiement.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_paiement_service.dart';
import '../model/paiement_admin_model.dart';

class GestPaiementPage extends StatefulWidget {
  @override
  _GestPaiementPageState createState() => _GestPaiementPageState();
}

class _GestPaiementPageState extends State<GestPaiementPage> {
  final AdminPaiementService _paiementService = AdminPaiementService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PaiementAdminModel> _paiements = [];
  List<PaiementAdminModel> _filteredPaiements = [];
  List<ClasseInfo> _classes = [];
  
  bool _isLoading = true;
  bool _isLoadingList = false;
  bool _isDownloading = false;
  String? _error;
  
  int? _selectedClasseId;
  int _selectedTranche = 1;
  String _searchQuery = '';
  
  Timer? _debounceTimer;

  final List<int> _tranches = [1, 2, 3, 4];
  final Map<int, String> _trancheLabels = {
    1: 'Tranche 1 - Inscription',
    2: 'Tranche 2 - 1er Trimestre',
    3: 'Tranche 3 - 2ème Trimestre',
    4: 'Tranche 4 - 3ème Trimestre',
  };

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyLocalFilter();
      });
    });
  }

  void _applyLocalFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredPaiements = List.from(_paiements);
      });
    } else {
      setState(() {
        _filteredPaiements = _paiements.where((p) {
          return p.eleveNom.toLowerCase().contains(_searchQuery) ||
                 p.elevePrenom.toLowerCase().contains(_searchQuery) ||
                 p.reference.toLowerCase().contains(_searchQuery);
        }).toList();
      });
    }
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _paiementService.getClasses();
      
      if (!mounted) return;
      
      setState(() {
        _classes = classes;
      });
      
      await _loadPaiements();
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPaiements() async {
    setState(() {
      _isLoadingList = true;
      _error = null;
    });

    try {
      List<PaiementAdminModel> paiements = [];
      
      if (_selectedClasseId == null) {
        for (var classe in _classes) {
          final classePaiements = await _paiementService.getPaiementsByClasseAndTranche(
            classe.id, 
            _selectedTranche,
          );
          paiements.addAll(classePaiements);
        }
      } else {
        paiements = await _paiementService.getPaiementsByClasseAndTranche(
          _selectedClasseId!, 
          _selectedTranche,
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        _paiements = paiements;
        _applyLocalFilter();
      });
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  void _onClassChanged(int? classeId) {
    setState(() {
      _selectedClasseId = classeId;
      _searchController.clear();
      _searchQuery = '';
    });
    _loadPaiements();
  }

  void _onTrancheChanged(int value) {
    setState(() {
      _selectedTranche = value;
      _searchController.clear();
      _searchQuery = '';
    });
    _loadPaiements();
  }

  // Téléchargement du reçu - comme dans gestscolarite
  Future<void> _telechargerRecu(PaiementAdminModel paiement) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Formater la date
      String dateFormatee = paiement.formattedDate;
      if (dateFormatee == 'Date non spécifiée' || dateFormatee.isEmpty) {
        dateFormatee = DateTime.now().toString().split(' ')[0];
      }
      
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
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'REÇU DE PAIEMENT',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
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
                  _buildInfoRow('Référence', paiement.reference),
                  _buildInfoRow('Date', dateFormatee),
                  _buildInfoRow('Élève', '${paiement.elevePrenom} ${paiement.eleveNom}'),
                  _buildInfoRow('Classe', paiement.classe),
                  _buildInfoRow('Libellé', paiement.libelle),
                  _buildInfoRow('Mode de paiement', _getModePaiementLabel(paiement.modePaiement ?? 'kkiapay')),
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
                    paiement.montantFormatted,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
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
            
            // Pied de page
            pw.Text(
              'Document généré automatiquement par SchoolApp',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
      );
      
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'recu_${paiement.reference}.pdf');
      
      _showSnackBar('✅ Reçu téléchargé avec succès');
    } catch (e) {
      print('❌ Erreur: $e');
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('✅') ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'orange_money': return 'Orange Money';
      case 'wave': return 'Wave';
      case 'free_money': return 'Free Money';
      case 'fedapay': return 'FedaPay';
      case 'kkiapay': return 'KKiaPay';
      default: return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des paiements', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _searchQuery = '';
              _loadPaiements();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildClassSelector(),
                    _buildTrancheSelector(),
                    _buildSearchBar(),
                    _buildStatsWidget(),
                    Expanded(
                      child: _isLoadingList
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredPaiements.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _filteredPaiements.length,
                                  itemBuilder: (context, index) {
                                    final paiement = _filteredPaiements[index];
                                    return _buildPaiementCard(paiement);
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('TOUS'),
              selected: _selectedClasseId == null,
              onSelected: (_) => _onClassChanged(null),
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedClasseId == null ? Colors.blue : Colors.grey[700],
                fontWeight: _selectedClasseId == null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          ..._classes.map((classe) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(classe.nom),
              selected: _selectedClasseId == classe.id,
              onSelected: (_) => _onClassChanged(classe.id),
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedClasseId == classe.id ? const Color(0xFFF47C3C) : Colors.grey[700],
                fontWeight: _selectedClasseId == classe.id ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrancheSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedTranche,
          isExpanded: true,
          items: _tranches.map((tranche) {
            return DropdownMenuItem(
              value: tranche,
              child: Text(_trancheLabels[tranche]!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _onTrancheChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par élève ou référence...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyLocalFilter();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsWidget() {
    final total = _filteredPaiements.length;
    final totalMontant = _filteredPaiements.fold<double>(0, (sum, p) => sum + p.montant);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.payment, 'Total', total.toString(), Colors.white),
          _buildStatItem(Icons.attach_money, 'Montant', '${(totalMontant / 1000).toStringAsFixed(0)}K FCFA', const Color(0xFFF47C3C)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaiementCard(PaiementAdminModel paiement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF47C3C), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${paiement.elevePrenom} ${paiement.eleveNom}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(paiement.classe, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: const Text('Validé', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tranche ${paiement.numeroTranche}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(paiement.libelle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(paiement.montantFormatted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C))),
                    Text('Ref: ${paiement.reference.substring(0, 8)}...', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            if (paiement.datePaiement != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Payé le: ${paiement.datePaiement}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : () => _telechargerRecu(paiement),
                icon: _isDownloading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.receipt, size: 16),
                label: Text(_isDownloading ? 'Génération...' : 'Télécharger le reçu', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF47C3C)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun paiement trouvé' : 'Aucun paiement enregistré',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Essayez avec d\'autres mots-clés' : 'Sélectionnez une classe et une tranche',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () { _searchController.clear(); _loadPaiements(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}