// lib/screens/gestscolarite.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_scolarite_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/scolarite_model.dart';
import '../model/annee_scolaire_model.dart';

class GestScolaritePage extends StatefulWidget {
  @override
  _GestScolaritePageState createState() => _GestScolaritePageState();
}

class _GestScolaritePageState extends State<GestScolaritePage> {
  final AdminScolariteService _service = AdminScolariteService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();
  List<ClasseInfo> _classes = [];
  List<AnneeScolaire> _anneesScolaires = [];
  List<EleveAvecTranches> _allEleves = [];
  List<EleveAvecTranches> _filteredEleves = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedClasseId;
  int? _selectedAnneeId;
  int? _selectedTranche;
  String _selectedFilter = 'tous';
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
    _loadAllData();
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
      List<EleveAvecTranches> tempList = _selectedClasseId == null
          ? List.from(_allEleves)
          : _allEleves.where((e) => e.classeId == _selectedClasseId).toList();
      
      if (_searchQuery.isNotEmpty) {
        tempList = tempList.where((eleve) {
          return eleve.fullName.toLowerCase().contains(_searchQuery);
        }).toList();
      }
      
      // Filtrer par statut (payé/impayé) pour la tranche sélectionnée
      if (_selectedTranche != null && _selectedFilter != 'tous') {
        tempList = tempList.where((eleve) {
          final estPaye = eleve.getTrancheStatus(_selectedTranche!);
          return _selectedFilter == 'paye' ? estPaye : !estPaye;
        }).toList();
      }
      
      _filteredEleves = tempList;
    });
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les années scolaires et déterminer l'année par défaut
      // (en cours, sinon la première) : le backend exige désormais
      // annee_scolaire_id pour cet endpoint.
      final annees = await _anneeService.getAnneesScolaires();
      if (!mounted) return;
      _anneesScolaires = annees;

      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }

      final classes = await _service.getClasses(anneeScolaireId: _selectedAnneeId);

      if (!mounted) return;

      setState(() {
        _classes = classes;
      });

      // ⚠️ Avant : un appel HTTP séquentiel par classe (une classe après
      // l'autre). On les lance maintenant tous en parallèle.
      final resultatsParClasse = await Future.wait(classes.map(
        (classe) => _service.getElevesWithAllTranches(
          classe.id,
          anneeScolaireId: _selectedAnneeId,
        ),
      ));
      final List<EleveAvecTranches> allEleves =
          resultatsParClasse.expand((eleves) => eleves).toList();

      if (!mounted) return;
      
      setState(() {
        _allEleves = allEleves;
        _applyFilters();
      });
      
      print('📊 Total élèves chargés: ${allEleves.length}');
      
    } catch (e) {
      print('❌ Erreur: $e');
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

  Future<void> _exportPDF() async {
    if (_filteredEleves.isEmpty) {
      _showSnackBar('Aucune donnée à exporter');
      return;
    }
    
    String titre;
    String sousTitre = '';
    
    if (_selectedClasseId == null) {
      titre = 'TOUTES LES CLASSES';
    } else {
      final classe = _classes.firstWhere((c) => c.id == _selectedClasseId);
      titre = classe.nom;
    }
    
    if (_selectedTranche != null) {
      titre += ' - ${_trancheLabels[_selectedTranche]}';
    } else {
      titre += ' - TOUTES LES TRANCHES';
    }
    
    if (_selectedFilter == 'paye' && _selectedTranche != null) {
      sousTitre = 'Liste des élèves ayant payé cette tranche';
    } else if (_selectedFilter == 'impaye' && _selectedTranche != null) {
      sousTitre = 'Liste des élèves n\'ayant pas payé cette tranche';
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
          if (sousTitre.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              sousTitre,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 20),
          
          // Tableau selon le mode
          if (_selectedTranche != null)
            _buildSingleTrancheTable()
          else
            _buildAllTranchesTable(),
          
          pw.SizedBox(height: 20),
          _buildRecap(),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
    
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'liste_scolarite.pdf');
  }

  pw.Widget _buildSingleTrancheTable() {
    return pw.Table(
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
          final estPaye = eleve.getTrancheStatus(_selectedTranche!);
          final datePaiement = eleve.getTrancheDate(_selectedTranche!);
          final montant = eleve.getTrancheMontant(_selectedTranche!);
          
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              _buildCell('$index'),
              _buildCell(eleve.classeNom),
              _buildCell(eleve.nom),
              _buildCell(eleve.prenom),
              _buildCell('${montant.toStringAsFixed(0)} FCFA'),
              _buildCell(
                estPaye ? 'Payé' : 'Impayé',
                style: pw.TextStyle(
                  color: estPaye ? PdfColors.green : PdfColors.red,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              _buildCell(datePaiement ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildAllTranchesTable() {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            _buildHeaderCell('N°', textColor: PdfColors.white),
            _buildHeaderCell('Classe', textColor: PdfColors.white),
            _buildHeaderCell('Nom', textColor: PdfColors.white),
            _buildHeaderCell('Prénom', textColor: PdfColors.white),
            _buildHeaderCell('T1', textColor: PdfColors.white),
            _buildHeaderCell('T2', textColor: PdfColors.white),
            _buildHeaderCell('T3', textColor: PdfColors.white),
            _buildHeaderCell('T4', textColor: PdfColors.white),
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
              _buildCell(eleve.classeNom),
              _buildCell(eleve.nom),
              _buildCell(eleve.prenom),
              _buildStatusCell(eleve.getTrancheStatus(1)),
              _buildStatusCell(eleve.getTrancheStatus(2)),
              _buildStatusCell(eleve.getTrancheStatus(3)),
              _buildStatusCell(eleve.getTrancheStatus(4)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildStatusCell(bool estPaye) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        estPaye ? '✓' : '✗',
        style: pw.TextStyle(
          color: estPaye ? PdfColors.green : PdfColors.red,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  pw.Widget _buildRecap() {
    final totalEleves = _filteredEleves.length;
    int totalPaye = 0;
    int totalImpaye = 0;
    double montantTotal = 0;
    
    if (_selectedTranche != null) {
      for (var eleve in _filteredEleves) {
        if (eleve.getTrancheStatus(_selectedTranche!)) {
          totalPaye++;
        } else {
          totalImpaye++;
        }
        montantTotal += eleve.getTrancheMontant(_selectedTranche!);
      }
    } else {
      for (var eleve in _filteredEleves) {
        for (var tranche in eleve.tranches) {
          if (tranche.estPaye) {
            totalPaye++;
          } else {
            totalImpaye++;
          }
          montantTotal += tranche.montant;
        }
      }
    }
    
    return pw.Container(
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
              pw.Text('Total inscriptions :'),
              pw.Text('$totalEleves'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dont payé :'),
              pw.Text('$totalPaye'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Dont impayé :'),
              pw.Text('$totalImpaye'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Montant total :'),
              pw.Text('${montantTotal.toStringAsFixed(0)} FCFA'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
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
    );
  }

  pw.Widget _buildHeaderCell(String text, {PdfColor textColor = PdfColors.black}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: textColor),
        textAlign: pw.TextAlign.center,
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
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Exporter en PDF',
            onPressed: _exportPDF,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    _buildAnneeSelector(),
                    _buildClassAndTrancheRow(),
                    _buildSearchBar(),
                    _buildFilterChips(),
                    Expanded(
                      child: _filteredEleves.isEmpty
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

  Widget _buildAnneeSelector() {
    if (_anneesScolaires.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAnneeId,
          isExpanded: true,
          items: _anneesScolaires.map((annee) {
            return DropdownMenuItem(
              value: annee.id,
              child: Text(annee.libelle ?? 'Année ${annee.id}'),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedAnneeId = value;
            });
            await _loadAllData();
          },
        ),
      ),
    );
  }

  Widget _buildClassAndTrancheRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(child: _buildClassSelector()),
          const SizedBox(width: 8),
          Expanded(child: _buildTrancheSelector()),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedClasseId,
          isExpanded: true,
          isDense: true,
          hint: const Text('Toutes les classes', style: TextStyle(fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Toutes les classes'),
            ),
            ..._classes.map((classe) {
              return DropdownMenuItem<int?>(
                value: classe.id,
                child: Text(classe.nom, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedClasseId = value;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildTrancheSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedTranche,
          isExpanded: true,
          isDense: true,
          hint: const Text('📊 Toutes les tranches', style: TextStyle(fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('📊 Toutes les tranches'),
            ),
            ..._tranches.map((tranche) {
              return DropdownMenuItem<int?>(
                value: tranche,
                child: Text(
                  _trancheLabels[tranche]!,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTranche = value;
              _selectedFilter = 'tous';
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_selectedTranche == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('Tous'),
              selected: _selectedFilter == 'tous',
              onSelected: (_) {
                setState(() {
                  _selectedFilter = 'tous';
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('Payé'),
              selected: _selectedFilter == 'paye',
              onSelected: (_) {
                setState(() {
                  _selectedFilter = 'paye';
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('Impayé'),
              selected: _selectedFilter == 'impaye',
              onSelected: (_) {
                setState(() {
                  _selectedFilter = 'impaye';
                  _applyFilters();
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.red.withOpacity(0.2),
              checkmarkColor: Colors.red,
            ),
          ),
        ],
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
            _searchQuery.isNotEmpty ? 'Aucun élève trouvé' : 'Aucune donnée disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez une classe ou une tranche pour voir les résultats',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEleveCard(EleveAvecTranches eleve) {
    // Si une tranche spécifique est sélectionnée, afficher les détails de cette tranche
    if (_selectedTranche != null) {
      final estPaye = eleve.getTrancheStatus(_selectedTranche!);
      final montant = eleve.getTrancheMontant(_selectedTranche!);
      final datePaiement = eleve.getTrancheDate(_selectedTranche!);
      
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
                    Text(eleve.classeNom, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      'Montant: ${montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (datePaiement != null)
                      Text(
                        'Payé le: $datePaiement',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estPaye ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estPaye ? 'Payé' : 'Impayé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: estPaye ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Sinon, afficher toutes les tranches dans le card
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      Text(eleve.classeNom, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: eleve.tranches.map((tranche) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tranche.estPaye ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: tranche.estPaye ? Colors.green : Colors.red,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${tranche.libelle}: ${tranche.estPaye ? "Payé" : "Impayé"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tranche.estPaye ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }).toList(),
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
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}