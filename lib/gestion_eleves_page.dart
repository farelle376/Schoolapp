// lib/screens/gestion_eleves_page.dart

import 'package:flutter/material.dart';
import '../services/eleve_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/add_eleve_panel.dart';

class GestionElevesPage extends StatefulWidget {
  @override
  _GestionElevesPageState createState() => _GestionElevesPageState();
}

class _GestionElevesPageState extends State<GestionElevesPage> {
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _allEleves = [];
  List<Map<String, dynamic>> _filteredEleves = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  int? _selectedClasseId;
  String? _selectedClasseNom;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  // 1. D'abord, charger les classes (rapide)
  final classesResponse = await EleveService.getClasses();
  
  if (classesResponse['success'] != true) {
    setState(() => _isLoading = false);
    _showSnackBar(classesResponse['message'] ?? 'Erreur', Colors.red);
    return;
  }
  
  // Afficher immédiatement les classes
  setState(() {
    _classes = List<Map<String, dynamic>>.from(classesResponse['data']);
    _isLoading = false; // L'écran s'affiche avec les classes mais sans élèves
  });
  
  // 2. Ensuite, charger les élèves en arrière-plan (sans bloquer l'UI)
  await _loadAllElevesInBackground();
}

Future<void> _loadAllElevesInBackground() async {
  print('📚 Chargement des élèves en arrière-plan...');
  
  List<Map<String, dynamic>> tousLesEleves = [];
  
  // Charger les élèves pour chaque classe
  for (var classe in _classes) {
    final elevesResponse = await EleveService.getElevesByClasse(classe['id']);
    
    if (elevesResponse['success'] == true) {
      final eleves = List<Map<String, dynamic>>.from(elevesResponse['data']);
      for (var eleve in eleves) {
        eleve['classe_nom'] = classe['nom'];
        eleve['classe_id'] = classe['id'];
      }
      tousLesEleves.addAll(eleves);
    }
  }
  
  // Tri alphabétique
  tousLesEleves.sort((a, b) {
    int nomCompare = (a['nom'] ?? '').compareTo(b['nom'] ?? '');
    if (nomCompare != 0) return nomCompare;
    return (a['prenom'] ?? '').compareTo(b['prenom'] ?? '');
  });
  
  // Mettre à jour l'affichage avec les élèves
  setState(() {
    _allEleves = tousLesEleves;
    _filteredEleves = tousLesEleves;
  });
  
  print('✅ ${tousLesEleves.length} élèves chargés en arrière-plan');
} 

  void _filterEleves() {
    setState(() {
      _filteredEleves = _allEleves.where((eleve) {
        final matchesClasse = _selectedClasseId == null || 
            eleve['classe_id'] == _selectedClasseId;
        
        final fullName = eleve['full_name'] ?? '';
        final matchesSearch = _searchQuery.isEmpty ||
            fullName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final sexe = eleve['sexe'] ?? '';
        final matchesFilter = _selectedFilter == 'Tous' ||
            (_selectedFilter == 'Garçons' && (sexe == 'M' || sexe == 'Masculin')) ||
            (_selectedFilter == 'Filles' && (sexe == 'F' || sexe == 'Feminin'));
        
        return matchesClasse && matchesSearch && matchesFilter;
      }).toList();
    });
  }

Future<void> _generatePdf() async {
  if (_selectedClasseId == null) {
    _showSnackBar('Veuillez sélectionner une classe', Colors.orange);
    return;
  }
  
  if (_filteredEleves.isEmpty) {
    _showSnackBar('Aucun élève à exporter', Colors.orange);
    return;
  }
  
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            pw.Center(
              child: pw.Text(
                'SchoolApp Benin',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Liste des élèves',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Classe: ${_selectedClasseNom ?? ''}',
                style: pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            
            // Tableau avec toutes les colonnes
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FixedColumnWidth(30),   // N°
                1: pw.FixedColumnWidth(80),   // Nom
                2: pw.FixedColumnWidth(80),   // Prénom
                3: pw.FixedColumnWidth(50),   // Sexe
                4: pw.FixedColumnWidth(90),   // Tél Papa
                5: pw.FixedColumnWidth(90),   // Tél Maman
                6: pw.FixedColumnWidth(120),  // Email Papa
                7: pw.FixedColumnWidth(120),  // Email Maman
              },
              children: [
                // En-tête du tableau
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('N°', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                      child: pw.Text('Tél Papa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Tél Maman', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Email Papa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Email Maman', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Lignes du tableau
                ..._filteredEleves.asMap().entries.map((entry) {
                  final index = entry.key;
                  final eleve = entry.value;
                  final sexe = eleve['sexe'] ?? '';
                  
                  // Convertir le sexe en texte complet
                  String sexeTexte = '';
                  if (sexe == 'M' || sexe == 'Masculin') {
                    sexeTexte = 'Masculin';
                  } else if (sexe == 'F' || sexe == 'Feminin') {
                    sexeTexte = 'Féminin';
                  } else {
                    sexeTexte = sexe;
                  }
                  
                  // Récupérer les emails des parents
                  String emailPapa = '';
                  String emailMaman = '';
                  
                  if (eleve['parents'] != null && eleve['parents'] is List) {
                    for (var parent in eleve['parents']) {
                      if (parent['type'] == 'pere') {
                        emailPapa = parent['email'] ?? '';
                      } else if (parent['type'] == 'mere') {
                        emailMaman = parent['email'] ?? '';
                      }
                    }
                  }
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text('${index + 1}', textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(eleve['nom'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(eleve['prenom'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(sexeTexte, textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(eleve['num_papa'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(eleve['num_maman'] ?? '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(emailPapa.isNotEmpty ? emailPapa : '-'),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(6),
                        child: pw.Text(emailMaman.isNotEmpty ? emailMaman : '-'),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Total: ${_filteredEleves.length} élève(s)',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ],
        );
      },
    ),
  );
  
  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'liste_eleves_${_selectedClasseNom ?? 'classe'}.pdf',
  );
} 

Future<void> _ajouterEleve() async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AddElevePanel(
        classes: _classes,
        onAdd: () {
          _loadData(); 
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

  Future<void> _modifierEleve(Map<String, dynamic> eleve) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AjouterModifierEleveDialog(
        classes: _classes,
        eleve: eleve,
      ),
    );
    
    if (result != null) {
      final response = await EleveService.updateEleve(eleve['id'], result);
      
      if (response['success'] == true) {
        _showSnackBar('Élève modifié avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  Future<void> _supprimerEleve(Map<String, dynamic> eleve) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer ${eleve['full_name'] ?? 'cet élève'} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final response = await EleveService.deleteEleve(eleve['id']);
      
      if (response['success'] == true) {
        _showSnackBar('Élève supprimé avec succès', Colors.green);
        _loadData();
      } else {
        _showSnackBar(response['message'] ?? 'Erreur', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  int get _totalEleves => _allEleves.length;
  int get _totalGarcons => _allEleves.where((e) {
    final sexe = e['sexe'] ?? '';
    return sexe == 'M' || sexe == 'Masculin';
  }).length;
  int get _totalFilles => _allEleves.where((e) {
    final sexe = e['sexe'] ?? '';
    return sexe == 'F' || sexe == 'Feminin';
  }).length;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Gestion des élèves'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedClasseId != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Exporter en PDF',
            ),
            IconButton(
            icon: const Icon(Icons.add),
            onPressed: _ajouterEleve,
            tooltip: 'Ajouter un Eleve',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard('Total élèves', _totalEleves.toString(), const Color.fromARGB(255, 4, 252, 223)),
                      const SizedBox(width: 12),
                      _buildStatCard('Garçons', _totalGarcons.toString(), const Color(0xFFF47C3C)),
                      const SizedBox(width: 12),
                      _buildStatCard('Filles', _totalFilles.toString(), Colors.green),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        child: DropdownButton<int>(
                          value: _selectedClasseId,
                          hint: Text('Toutes les classes', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                          underline: const SizedBox(),
                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Toutes les classes'),
                            ),
                            ..._classes.map((classe) {
                              return DropdownMenuItem<int>(
                                value: classe['id'],
                                child: Text(classe['nom']),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClasseId = value;
                              if (value != null) {
                                final classe = _classes.firstWhere((c) => c['id'] == value);
                                _selectedClasseNom = classe['nom'];
                              } else {
                                _selectedClasseNom = null;
                              }
                              _filterEleves();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildFilterChip('Tous', _selectedFilter == 'Tous'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Garçons', _selectedFilter == 'Garçons'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Filles', _selectedFilter == 'Filles'),
                      const Spacer(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterEleves();
                    },
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey.shade500 : Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEleves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('Aucun élève trouvé', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowColor: MaterialStateProperty.all(
                                isDarkMode ? Colors.grey.shade800 : const Color(0xFFF47C3C).withOpacity(0.1),
                              ),
                              columns: [
                                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Sexe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Email Papa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Email Maman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black87))),
                              ],
                              rows: _filteredEleves.asMap().entries.map((entry) {
                                final index = entry.key;
                                final eleve = entry.value;
                                final sexe = eleve['sexe'] ?? '';
                                final isMasculin = sexe == 'M' || sexe == 'Masculin';
                                
                                return DataRow(
                                  color: MaterialStateProperty.all(isDarkMode ? Colors.grey.shade900 : Colors.white),
                                  cells: [
                                    DataCell(Text('${index + 1}', style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black87))),
                                    DataCell(Text(eleve['full_name'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black87))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isMasculin ? Colors.blue.shade50 : Colors.pink.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isMasculin ? 'Garçon' : 'Fille',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isMasculin ? Colors.blue : Colors.pink,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(eleve['classe_nom'] ?? '-', style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : Colors.black87))),
                                    DataCell(
                                    Text(eleve['email_papa'] ?? '-', 
                                    style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                    fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    )
                                    ),
                                    DataCell(
                                    Text(eleve['email_maman'] ?? '-', 
                                    style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                                    fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    )
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                            onPressed: () => _modifierEleve(eleve),
                                            tooltip: 'Modifier',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => _supprimerEleve(eleve),
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
          _filterEleves();
        });
      },
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
      checkmarkColor: const Color(0xFFF47C3C),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
      ),
    );
  }
}

// Dialogue pour ajouter/modifier un élève
class _AjouterModifierEleveDialog extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final Map<String, dynamic>? eleve;

  const _AjouterModifierEleveDialog({
    required this.classes,
    this.eleve,
  });

  @override
  __AjouterModifierEleveDialogState createState() => __AjouterModifierEleveDialogState();
}

class __AjouterModifierEleveDialogState extends State<_AjouterModifierEleveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  String _sexe = 'M';
  int? _classeId;

  @override
  void initState() {
    super.initState();
    if (widget.eleve != null) {
      _nomController.text = widget.eleve!['nom'] ?? '';
      _prenomController.text = widget.eleve!['prenom'] ?? '';
      _sexe = widget.eleve!['sexe'] == 'F' || widget.eleve!['sexe'] == 'Feminin' ? 'F' : 'M';
      _classeId = widget.eleve!['classe_id'];
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.eleve == null ? 'Ajouter un élève' : 'Modifier l\'élève'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sexe,
                decoration: InputDecoration(
                  labelText: 'Sexe',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculin')),
                  DropdownMenuItem(value: 'F', child: Text('Féminin')),
                ],
                onChanged: (value) => setState(() => _sexe = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _classeId,
                decoration: InputDecoration(
                  labelText: 'Classe',
                  prefixIcon: const Icon(Icons.class_),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.classes.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['nom'] as String),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _classeId = value),
                validator: (v) => v == null ? 'Sélectionnez une classe' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'nom': _nomController.text,
                'prenom': _prenomController.text,
                'sexe': _sexe == 'M' ? 'Masculin' : 'Feminin',
                'classe_id': _classeId,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
          child: Text(widget.eleve == null ? 'AJOUTER' : 'MODIFIER'),
        ),
      ],
    );
  }
}