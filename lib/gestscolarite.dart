// lib/screens/gestscolarite.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_scolarite_service.dart';
import '../model/scolarite_model.dart';

class GestScolaritePage extends StatefulWidget {
  @override
  _GestScolaritePageState createState() => _GestScolaritePageState();
}

class _GestScolaritePageState extends State<GestScolaritePage> {
  final AdminScolariteService _service = AdminScolariteService();
  List<ClasseInfo> _classes = [];
  List<ElevePaiementModel> _eleves = [];
  List<ElevePaiementModel> _filteredEleves = [];
  bool _isLoading = true;
  bool _isLoadingList = false;
  String? _error;
  int? _selectedClasseId;
  int _selectedTranche = 1;
  String _selectedFilter = 'tous'; // 'tous', 'paye', 'impaye'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      // 1. Filtrer par statut (payé/impayé)
      List<ElevePaiementModel> tempList;
      if (_selectedFilter == 'tous') {
        tempList = List.from(_eleves);
      } else if (_selectedFilter == 'paye') {
        tempList = _eleves.where((e) => e.estPaye).toList();
      } else {
        tempList = _eleves.where((e) => !e.estPaye).toList();
      }
      
      // 2. Filtrer par recherche
      if (_searchQuery.isEmpty) {
        _filteredEleves = tempList;
      } else {
        _filteredEleves = tempList.where((eleve) {
          return eleve.fullName.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final classes = await _service.getClasses();
      
      if (!mounted) return;
      
      setState(() {
        _classes = classes;
        // Par défaut, sélectionner "TOUS" (null)
        _selectedClasseId = null;
      });
      
      // Charger immédiatement tous les élèves
      await _loadEleves();
      
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

  Future<void> _loadEleves() async {
    setState(() {
      _isLoadingList = true;
      _error = null;
    });

    try {
      List<ElevePaiementModel> eleves = [];
      
      if (_selectedClasseId == null) {
        // Mode "TOUS" : charger les élèves de toutes les classes
        for (var classe in _classes) {
          final classeEleves = await _service.getElevesByClasseAndTranche(
            classe.id, 
            _selectedTranche,
          );
          eleves.addAll(classeEleves);
        }
      } else {
        // Mode classe spécifique
        eleves = await _service.getElevesByClasseAndTranche(
          _selectedClasseId!, 
          _selectedTranche,
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        _eleves = eleves;
        _applyFilters();
      });
      
      print('📊 Élèves chargés: ${eleves.length}');
      
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
      _selectedFilter = 'tous';
      _searchController.clear();
    });
    _loadEleves();
  }

  void _onTrancheChanged(int value) {
    setState(() {
      _selectedTranche = value;
      _selectedFilter = 'tous';
      _searchController.clear();
    });
    _loadEleves();
  }

  Future<void> _exportPDF() async {
    if (_filteredEleves.isEmpty) {
      _showSnackBar('Aucun élève à exporter');
      return;
    }
    
    String titre;
    String sousTitre;
    
    if (_selectedClasseId == null) {
      titre = 'TOUTES LES CLASSES - ${_trancheLabels[_selectedTranche]}';
    } else {
      final classe = _classes.firstWhere((c) => c.id == _selectedClasseId);
      titre = '${classe.nom} - ${_trancheLabels[_selectedTranche]}';
    }
    
    sousTitre = _selectedFilter == 'paye' ? 'Liste des élèves ayant payé' : 
                (_selectedFilter == 'impaye' ? 'Liste des élèves n\'ayant pas payé' : 
                'Liste des élèves');
    
    if (_searchQuery.isNotEmpty) {
      sousTitre += ' (Recherche: "$_searchQuery")';
    }
    
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
                  'GESTION DE LA SCOLARITÉ',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
                ),
                pw.Divider(height: 20, thickness: 2, color: PdfColors.orange700),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Header(
            level: 0,
            child: pw.Text(
              titre,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            sousTitre,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                children: [
                  _buildHeaderCell('N°', textColor: PdfColors.white),
                  _buildHeaderCell('Classe', textColor: PdfColors.white),
                  _buildHeaderCell('Nom', textColor: PdfColors.white),
                  _buildHeaderCell('Prénom', textColor: PdfColors.white),
                  _buildHeaderCell('Montant', textColor: PdfColors.white),
                  _buildHeaderCell('Statut', textColor: PdfColors.white),
                  _buildHeaderCell('Date paiement', textColor: PdfColors.white),
                ],
              ),
              ..._filteredEleves.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final eleve = entry.value;
                final bgColor = index % 2 == 0 ? PdfColors.grey100 : PdfColors.white;
                
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bgColor),
                  children: [
                    _buildCell('$index'),
                    _buildCell(eleve.classe),
                    _buildCell(eleve.nom),
                    _buildCell(eleve.prenom),
                    _buildCell('${eleve.montant.toStringAsFixed(0)} FCFA'),
                    _buildCell(
                      eleve.estPaye ? 'Payé' : 'Impayé',
                      style: pw.TextStyle(
                        color: eleve.estPaye ? PdfColors.green : PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildCell(eleve.datePaiement ?? '-'),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RÉCAPITULATIF',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total élèves :'),
                    pw.Text('${_filteredEleves.length}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Dont payé :'),
                    pw.Text('${_filteredEleves.where((e) => e.estPaye).length}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Dont impayé :'),
                    pw.Text('${_filteredEleves.where((e) => !e.estPaye).length}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 10),
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
          ),
        ],
      ),
    );
    
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'liste_scolarite.pdf');
  }

  pw.Widget _buildHeaderCell(String text, {PdfColor textColor = PdfColors.black}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: textColor),
      ),
    );
  }

  pw.Widget _buildCell(String text, {pw.TextStyle? style}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(text, style: style ?? pw.TextStyle()),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scolarité', style: TextStyle(color: Colors.white)),
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
              _loadClasses();
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
                    _buildFilters(), // TOUJOURS affiché, même en mode TOUS
                    _buildExportButton(),
                    Expanded(
                      child: _isLoadingList
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredEleves.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredEleves.length,
                                  itemBuilder: (context, index) {
                                    final eleve = _filteredEleves[index];
                                    return _buildEleveCard(eleve);
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un élève...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Bouton "TOUS"
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
          // Classes
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

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('Tous', 'tous'),
          const SizedBox(width: 8),
          _buildFilterChip('Payé', 'paye'),
          const SizedBox(width: 8),
          _buildFilterChip('Impayé', 'impaye'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    if (_filteredEleves.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _exportPDF,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('EXPORTER EN PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun élève trouvé' : 'Aucun élève trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (_searchQuery.isEmpty)
            const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Aucun paiement enregistré pour cette tranche',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildEleveCard(ElevePaiementModel eleve) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF47C3C).withOpacity(0.1),
              child: Text(
                eleve.fullName.isNotEmpty ? eleve.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFFF47C3C), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eleve.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(eleve.classe, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    'Montant: ${eleve.montant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (eleve.datePaiement != null)
                    Text(
                      'Payé le: ${eleve.datePaiement}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: eleve.estPaye ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                eleve.estPaye ? 'Payé' : 'Impayé',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: eleve.estPaye ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadClasses,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}