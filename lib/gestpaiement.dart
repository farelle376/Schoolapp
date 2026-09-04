// lib/screens/gestpaiement.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_paiement_service.dart';
import '../services/annee_scolaire_service.dart';
import '../model/paiement_admin_model.dart';
import '../model/annee_scolaire_model.dart';

class GestPaiementPage extends StatefulWidget {
  @override
  _GestPaiementPageState createState() => _GestPaiementPageState();
}

class _GestPaiementPageState extends State<GestPaiementPage> {
  final AdminPaiementService _paiementService = AdminPaiementService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();
  final TextEditingController _searchController = TextEditingController();

  List<PaiementAdminModel> _paiements = [];
  List<PaiementAdminModel> _filteredPaiements = [];
  List<ClasseInfo> _classes = [];
  List<AnneeScolaire> _anneesScolaires = [];
  int? _selectedAnneeId;

  bool _isLoading = true;
  bool _isLoadingList = false;
  bool _isDownloading = false;
  String? _error;

  int? _selectedClasseId;
  int? _selectedTranche;
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
    _loadData();
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

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les années
      final annees = await _anneeService.getAnneesScolaires();
      _anneesScolaires = annees;
      if (_selectedAnneeId == null && annees.isNotEmpty) {
        final anneeEnCours = await _anneeService.getAnneeEnCours();
        if (anneeEnCours != null && annees.any((a) => a.id == anneeEnCours.id)) {
          _selectedAnneeId = anneeEnCours.id;
        } else {
          _selectedAnneeId = annees.first.id;
        }
      }

      // Charger les classes
      final classes = await _paiementService.getClasses();
      _classes = classes;

      // Charger les paiements (avec année par défaut)
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
    if (_selectedAnneeId == null) {
      // Si aucune année n'est sélectionnée, ne pas charger
      setState(() {
        _paiements = [];
        _filteredPaiements = [];
      });
      return;
    }

    setState(() {
      _isLoadingList = true;
      _error = null;
    });

    try {
      // "Toutes les classes" (null) -> parcourir _classes ; sinon une seule.
      final classesACharger = _selectedClasseId == null
          ? _classes
          : _classes.where((c) => c.id == _selectedClasseId).toList();

      // "Toutes les tranches" (null) -> parcourir _tranches ; sinon une seule.
      final tranchesACharger = _selectedTranche == null ? _tranches : [_selectedTranche!];

      // ⚠️ Avant : un appel HTTP séquentiel par combinaison classe×tranche
      // (ex. 10 classes × 4 tranches = 40 aller-retours l'un après l'autre).
      // On les lance maintenant tous en parallèle avec Future.wait.
      final requetes = <Future<List<PaiementAdminModel>>>[];
      for (var classe in classesACharger) {
        for (var tranche in tranchesACharger) {
          requetes.add(_paiementService.getPaiementsByClasseAndTranche(
            classe.id,
            tranche,
            anneeScolaireId: _selectedAnneeId,
          ));
        }
      }
      final resultats = await Future.wait(requetes);
      final List<PaiementAdminModel> paiements = resultats.expand((r) => r).toList();

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

  void _onTrancheChanged(int? value) {
    setState(() {
      _selectedTranche = value;
      _searchController.clear();
      _searchQuery = '';
    });
    _loadPaiements();
  }

  void _onAnneeChanged(int? anneeId) async {
    setState(() {
      _selectedAnneeId = anneeId;
      _selectedClasseId = null; // Réinitialiser la sélection de classe
      _searchController.clear();
      _searchQuery = '';
    });
    await _loadPaiements();
  }

  Future<void> _telechargerRecu(PaiementAdminModel paiement) async {
    setState(() {
      _isDownloading = true;
    });

    try {
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
                  // Afficher l'année si présente
                  if (paiement.anneeScolaireLibelle != null)
                    _buildInfoRow('Année', paiement.anneeScolaireLibelle!),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

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
      case 'orange_money':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'free_money':
        return 'Free Money';
      case 'fedapay':
        return 'FedaPay';
      case 'kkiapay':
        return 'KKiaPay';
      default:
        return mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    // Sélecteur d'année
                    _buildAnneeSelector(),
                    _buildClassAndTrancheRow(),
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

  // ==================== WIDGETS DE FILTRES ====================

  Widget _buildAnneeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_anneesScolaires.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAnneeId,
          isExpanded: true,
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Toutes les années'),
            ),
            ..._anneesScolaires.map((annee) {
              return DropdownMenuItem(
                value: annee.id,
                child: Text(annee.libelle ?? 'Année ${annee.id}'),
              );
            }),
          ],
          onChanged: (value) {
            _onAnneeChanged(value);
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedClasseId,
          isExpanded: true,
          isDense: true,
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
          hint: const Text('Toutes les classes', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Toutes les classes', overflow: TextOverflow.ellipsis),
            ),
            ..._classes.map((classe) {
              return DropdownMenuItem<int?>(
                value: classe.id,
                child: Text(classe.nom, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ],
          onChanged: _onClassChanged,
        ),
      ),
    );
  }

  Widget _buildTrancheSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedTranche,
          isExpanded: true,
          isDense: true,
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
          hint: const Text('Toutes les tranches', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Toutes les tranches', overflow: TextOverflow.ellipsis),
            ),
            ..._tranches.map((tranche) {
              return DropdownMenuItem<int?>(
                value: tranche,
                child: Text(_trancheLabels[tranche]!, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
          ],
          onChanged: _onTrancheChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher par élève ou référence...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey[400],
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDarkMode ? Colors.grey.shade400 : Colors.grey, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyLocalFilter();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF47C3C), width: 1),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
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
        gradient: const LinearGradient(
            colors: [Color(0xFF0D2B4E), Color(0xFF1F4E79)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.payment, 'Total', total.toString(), Colors.white),
          _buildStatItem(Icons.attach_money, 'Montant', '${(totalMontant / 1000).toStringAsFixed(0)}K FCFA',
              const Color(0xFFF47C3C)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
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
                      Text(
                        '${paiement.elevePrenom} ${paiement.eleveNom}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        paiement.classe,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  // ⚠️ Le serveur exclut déjà les paiements 'refuse' de
                  // cette liste (voir AdminPaiementController), donc ce cas
                  // ne devrait normalement jamais s'afficher ici — mais le
                  // badge était avant codé en dur sur "Validé" quel que
                  // soit le statut réel, ce qui aurait été trompeur pour un
                  // paiement encore 'en_attente'. On l'aligne sur le vrai
                  // statut.
                  final estValide = paiement.statut == 'valide';
                  final label = estValide ? 'Validé' : 'En attente';
                  final color = estValide ? Colors.green : Colors.orange;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  );
                }),
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
                      Text(
                        'Tranche ${paiement.numeroTranche}',
                        style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
                      ),
                      Text(
                        paiement.libelle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      paiement.montantFormatted,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C)),
                    ),
                    Text(
                      'Ref: ${paiement.reference.substring(0, paiement.reference.length > 8 ? 8 : paiement.reference.length)}...',
                      style: TextStyle(fontSize: 9, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            if (paiement.datePaiement != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Payé le: ${paiement.datePaiement}',
                      style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
                    ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 60,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun paiement trouvé' : 'Aucun paiement enregistré',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Essayez avec d\'autres mots-clés' : 'Sélectionnez une classe et une tranche',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 50,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _loadPaiements();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}