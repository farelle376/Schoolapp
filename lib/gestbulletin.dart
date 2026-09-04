// lib/screens/gestbulletin.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/admin_bulletin_service.dart';
import '../model/bulletin_admin_model.dart';
import 'bulletin_detail_screen.dart';
import '../services/annee_scolaire_service.dart';

class GestBulletinPage extends StatefulWidget {
  @override
  _GestBulletinPageState createState() => _GestBulletinPageState();
}

class _GestBulletinPageState extends State<GestBulletinPage> {
  final AdminBulletinService _service = AdminBulletinService();
  final AnneeScolaireService _anneeService = AnneeScolaireService();
  List<ClasseInfo> _classes = [];
  List<BulletinAdminModel> _bulletins = [];
  List<BulletinAdminModel> _filteredBulletins = [];
  bool _isLoading = true;
  bool _isLoadingList = false;
  bool _isExporting = false;
  String? _error;
  int? _selectedClasseId;
  String _selectedTrimestre = '1';
  int? _selectedAnneeId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  BulletinAdminModel? _selectedBulletin;
  bool _showBulletinDetail = false;

  final List<String> _trimestres = ['1', '2', '3'];

  @override
  void initState() {
    super.initState();
    _initData();
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
      _applyLocalFilter();
    });
  }

  void _applyLocalFilter() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredBulletins = List.from(_bulletins);
      });
    } else {
      setState(() {
        _filteredBulletins = _bulletins.where((bulletin) {
          return bulletin.fullName.toLowerCase().contains(_searchQuery);
        }).toList();
      });
    }
  }

  Future<void> _initData() async {
  // ⚠️ Cet écran n'avait aucun repli si "année en cours" échouait :
  // _selectedAnneeId restait null pour toujours et rien ne se chargeait
  // correctement derrière. getDefaultAnneeId() essaie l'année en cours
  // puis, à défaut, prend la plus récente des années existantes.
  final anneeId = await _anneeService.getDefaultAnneeId();
  if (anneeId > 0) {
    setState(() => _selectedAnneeId = anneeId);
  }
  await _loadClasses();
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
        if (_classes.isNotEmpty) {
          _selectedClasseId = _classes.first.id;
          _loadBulletins();
        }
      });
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

  Future<void> _loadBulletins() async {
    if (_selectedClasseId == null) return;

    setState(() {
      _isLoadingList = true;
      _error = null;
      _showBulletinDetail = false;
      _selectedBulletin = null;
    });

    try {
      final bulletins = await _service.getBulletinsByClasse(
        _selectedClasseId!,
        _selectedTrimestre,
        anneeScolaireId: _selectedAnneeId,
      );

      if (!mounted) return;

      setState(() {
        _bulletins = bulletins;
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

  Future<void> _deleteBulletin(BulletinAdminModel bulletin) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          'Confirmation',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Supprimer le bulletin de ${bulletin.fullName} (Trimestre ${bulletin.trimestre}) ?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoadingList = true);
      final success = await _service.deleteBulletin(bulletin.id);
      if (success) {
        await _loadBulletins();
        _showSnackBar('Bulletin supprimé', isError: false);
      } else {
        _showSnackBar('Erreur lors de la suppression');
        setState(() => _isLoadingList = false);
      }
    }
  }

  Future<void> _editBulletin(BulletinAdminModel bulletin) async {
    // ✅ Utilisation de inscriptionId
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulletinDetailScreen(
          inscriptionId: bulletin.inscriptionId ?? 0, // Utiliser inscriptionId
          eleveNom: bulletin.fullName,
          classe: bulletin.classe,
          trimestre: bulletin.trimestre,
        ),
      ),
    );

    if (result == true) {
      _loadBulletins();
    }
  }

  void _viewBulletin(BulletinAdminModel bulletin) async {
    // ✅ Utiliser inscriptionId pour charger les matières
    _showSnackBar('Chargement du bulletin...', isError: false);

    if (bulletin.matieresData == null || bulletin.matieresData!.isEmpty) {
      final updatedBulletin = await _loadMatiereDetailsForBulletin(bulletin);
      if (mounted) {
        setState(() {
          _selectedBulletin = updatedBulletin;
          _showBulletinDetail = true;
        });
      }
    } else {
      setState(() {
        _selectedBulletin = bulletin;
        _showBulletinDetail = true;
      });
    }
  }

  void _backToList() {
    setState(() {
      _showBulletinDetail = false;
      _selectedBulletin = null;
    });
  }

  // ✅ Charger le détail du bulletin DÉJÀ GÉNÉRÉ (matières, rang, total d'élèves)
  Future<BulletinAdminModel> _loadMatiereDetailsForBulletin(
      BulletinAdminModel bulletin) async {
    try {
      // ⚠️ Cette méthode appelait auparavant getNotesByInscriptionAndTrimestre(),
      // qui interroge NoteAdminController::getByInscription — un endpoint qui
      // renvoie une liste BRUTE de notes sous 'data.notes', sans les clés
      // 'matieres' / 'rang_general' / 'total_eleves' attendues ici. Résultat :
      // le bulletin s'affichait toujours avec "Aucune donnée de matière
      // disponible" et un rang "?/?", même juste après une génération réussie.
      //
      // Les données correctes (matières avec moyennes, rang, total d'élèves)
      // sont déjà calculées et stockées par generateBulletin() dans la colonne
      // notes_data du bulletin — on les récupère via getBulletinDetail(), qui
      // interroge AdminBulletinController::getBulletin() et les décode déjà
      // dans un BulletinAdminModel complet.
      final detail = await _service.getBulletinDetail(bulletin.id);

      print('📥 Détail bulletin chargé: ${detail != null}');
      print('📊 Matières chargées: ${detail?.matieresData?.length ?? 0}');

      return detail ?? bulletin;
    } catch (e) {
      print('❌ Erreur: $e');
      return bulletin;
    }
  }

  // ✅ Utilisation de inscriptionId
  Future<void> _generateBulletinForEleve(BulletinAdminModel bulletin) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inscriptionId = bulletin.inscriptionId ?? 0;

    final checkResult = await _service.checkNotesDisponibles(
        inscriptionId, _selectedTrimestre);

    if (!checkResult['toutes_disponibles']) {
      String missingNotesMessage =
          'Notes manquantes pour ${bulletin.fullName} :\n\n';
      // ✅ Le backend (AdminBulletinController::checkNotesDisponibles) renvoie
      // 'details' comme une LISTE (une entrée par matière), pas une Map avec
      // une clé 'matieres_manquantes' — l'ancien cast `as Map<String, dynamic>?`
      // provoquait un TypeError à l'exécution et empêchait tout le flux.
      final details = checkResult['details'] as List<dynamic>?;
      final matieresManquantes = details
              ?.where((m) => m is Map && m['est_disponible'] == false)
              .toList() ??
          [];

      if (matieresManquantes.isNotEmpty) {
        for (var matiere in matieresManquantes) {
          missingNotesMessage += '• ${matiere['matiere_nom']}\n';
        }
      } else {
        missingNotesMessage += 'Certaines notes ne sont pas disponibles.';
      }

      missingNotesMessage += '\n\nVoulez-vous quand même générer le bulletin ?';

      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            'Notes manquantes',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            missingNotesMessage,
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Continuer quand même'),
            ),
          ],
        ),
      );

      if (continueAnyway != true) {
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulletinDetailScreen(
          inscriptionId: inscriptionId,
          eleveNom: bulletin.fullName,
          classe: bulletin.classe,
          trimestre: _selectedTrimestre,
        ),
      ),
    );

    if (result == true) {
      _loadBulletins();
    }
  }

  // ✅ Utilisation de inscriptionId (provenant des données de l'API)
  Future<void> _generateAllBulletins() async {
    if (_selectedClasseId == null) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          'Générer tous les bulletins',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Générer les bulletins pour TOUS les élèves de cette classe ?\nTrimestre $_selectedTrimestre',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Générer tous'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoadingList = true);
      _showSnackBar('Vérification des notes en cours...', isError: false);

      // ✅ L'API doit renvoyer 'inscription_id' pour chaque élève
      final eleves = await _service.getElevesByClasse(_selectedClasseId!, anneeScolaireId: _selectedAnneeId);

      List<Map<String, dynamic>> elevesAvecNotes = [];
      List<Map<String, dynamic>> elevesSansNotes = [];

      for (var eleve in eleves) {
        final inscriptionId = eleve['inscription_id'];
        if (inscriptionId == null) {
          elevesSansNotes.add({
            'nom': eleve['nom'],
            'prenom': eleve['prenom'],
            'details': {'message': 'Inscription non trouvée'}
          });
          continue;
        }

        final checkResult = await _service.checkNotesDisponibles(
            inscriptionId, _selectedTrimestre);

        if (checkResult['toutes_disponibles']) {
          elevesAvecNotes.add(eleve);
        } else {
          elevesSansNotes.add({
            'nom': eleve['nom'],
            'prenom': eleve['prenom'],
            'details': checkResult['details']
          });
        }
      }

      String message = '';
      if (elevesAvecNotes.isNotEmpty) {
        message += ' ${elevesAvecNotes.length} élève(s) ont toutes les notes.\n\n';
      }
      if (elevesSansNotes.isNotEmpty) {
        message += ' ${elevesSansNotes.length} élève(s) ont des notes manquantes :\n';
        for (var eleve in elevesSansNotes) {
          message += '• ${eleve['prenom']} ${eleve['nom']}\n';
        }
        message +=
            '\nVoulez-vous générer les bulletins uniquement pour les élèves ayant toutes leurs notes ?';
      } else {
        message += 'Tous les élèves ont toutes leurs notes. Voulez-vous continuer ?';
      }

      final continueAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            'Récapitulatif des notes',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            message,
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            if (elevesAvecNotes.isNotEmpty)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Générer (${elevesAvecNotes.length} bulletins)'),
              ),
          ],
        ),
      );

      if (continueAnyway != true) {
        setState(() => _isLoadingList = false);
        return;
      }

      if (elevesAvecNotes.isEmpty) {
        _showSnackBar('Aucun élève n\'a toutes les notes nécessaires');
        setState(() => _isLoadingList = false);
        return;
      }

      _showSnackBar('Génération en cours...', isError: false);

      int successCount = 0;
      List<String> failedEleves = [];

      for (var eleve in elevesAvecNotes) {
        final inscriptionId = eleve['inscription_id'];
        final result = await _service.generateBulletin(
            inscriptionId, _selectedTrimestre);
        if (result['success']) {
          successCount++;
        } else {
          failedEleves.add('${eleve['prenom']} ${eleve['nom']}');
        }
      }

      await _loadBulletins();

      String resultMessage =
          '$successCount bulletins générés sur ${elevesAvecNotes.length}';
      if (failedEleves.isNotEmpty) {
        resultMessage += '\n❌ Échec pour: ${failedEleves.join(', ')}';
      }
      if (elevesSansNotes.isNotEmpty) {
        resultMessage +=
            '\n⚠️ ${elevesSansNotes.length} élève(s) non traités (notes manquantes)';
      }

      _showSnackBar(resultMessage, isError: failedEleves.isNotEmpty);
    }
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

  Color _getMoyenneColor(double moyenne) {
    if (moyenne >= 16) return Colors.green;
    if (moyenne >= 14) return Colors.lightGreen;
    if (moyenne >= 12) return Colors.orange;
    if (moyenne >= 10) return Colors.amber;
    return Colors.red;
  }

  String _getTrimestreLibelle(String trimestre) {
    switch (trimestre) {
      case '1':
        return 'PREMIER';
      case '2':
        return 'DEUXIÈME';
      case '3':
        return 'TROISIÈME';
      default:
        return 'PREMIER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des bulletins', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_showBulletinDetail)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _backToList,
              tooltip: 'Retour',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClasses,
          ),
          if (_showBulletinDetail && _selectedBulletin != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () => _exportBulletinToPdf(_selectedBulletin!),
              tooltip: 'Exporter PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _showBulletinDetail && _selectedBulletin != null
                  ? _buildBulletinDetailView(_selectedBulletin!)
                  : Column(
                      children: [
                        _buildClassSelector(),
                        _buildTrimestreSelector(),
                        _buildSearchBar(),
                        if (_selectedClasseId != null) ...[
                          _buildGenerateButton(),
                          Expanded(
                            child: _isLoadingList
                                ? const Center(child: CircularProgressIndicator())
                                : _filteredBulletins.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _filteredBulletins.length,
                                        itemBuilder: (context, index) {
                                          final bulletin = _filteredBulletins[index];
                                          return _buildBulletinCard(bulletin);
                                        },
                                      ),
                          ),
                        ],
                      ],
                    ),
    );
  }

  Widget _buildBulletinDetailView(BulletinAdminModel bulletin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletinHeaderTable(bulletin),
          const SizedBox(height: 24),
          _buildNotesTable(bulletin),
          const SizedBox(height: 24),
          _buildBulletinFooterTable(bulletin),
          const SizedBox(height: 20),
          _buildExportPdfButton(bulletin),
        ],
      ),
    );
  }

  Widget _buildBulletinHeaderTable(BulletinAdminModel bulletin) {
    // ⚠️ On affiche la vraie année scolaire renvoyée par le serveur (celle
    // de l'inscription/du bulletin), plus la date du jour qui ne correspond
    // pas forcément à l'année scolaire du bulletin consulté.
    final String anneeScolaire = bulletin.anneeScolaire.isNotEmpty
        ? bulletin.anneeScolaire
        : '${DateTime.now().year}-${DateTime.now().year + 1}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'BULLETIN DU ${_getTrimestreLibelle(bulletin.trimestre)} TRIMESTRE',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nom: ${bulletin.eleveNom}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'Classe: ${bulletin.classe}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prénom: ${bulletin.elevePrenom}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'Année scolaire: $anneeScolaire',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTable(BulletinAdminModel bulletin) {
    final matieresData = bulletin.matieresData;

    if (matieresData == null || matieresData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune donnée de matière disponible'),
            ],
          ),
        ),
      );
    }

    final List<MatiereBulletinAdmin> matieres = [];
    for (var matiere in matieresData) {
      if (matiere is Map<String, dynamic>) {
        matieres.add(MatiereBulletinAdmin.fromJson(matiere));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DataTable(
          columnSpacing: 12,
          headingRowColor:
              MaterialStateProperty.all(const Color(0xFFF47C3C).withOpacity(0.1)),
          columns: const [
            DataColumn(
                label: Text('Matières', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Coef', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Inter 1', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Inter 2', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Inter 3', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Inter 4', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Dev 1', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Dev 2', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Moy Interro',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Moy Devoirs',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Moy Coef',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Rang', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: matieres.map((matiere) {
            double moyInterro = 0;
            if (matiere.interrogations.isNotEmpty) {
              double sum = 0;
              for (var n in matiere.interrogations) sum += n.note;
              moyInterro = sum / matiere.interrogations.length;
            }

            double moyDevoirs = 0;
            if (matiere.devoirs.isNotEmpty) {
              double sum = 0;
              for (var n in matiere.devoirs) sum += n.note;
              moyDevoirs = sum / matiere.devoirs.length;
            }

            double inter1 =
                matiere.interrogations.length > 0 ? matiere.interrogations[0].note : 0;
            double inter2 =
                matiere.interrogations.length > 1 ? matiere.interrogations[1].note : 0;
            double inter3 =
                matiere.interrogations.length > 2 ? matiere.interrogations[2].note : 0;
            double inter4 =
                matiere.interrogations.length > 3 ? matiere.interrogations[3].note : 0;
            double dev1 =
                matiere.devoirs.length > 0 ? matiere.devoirs[0].note : 0;
            double dev2 =
                matiere.devoirs.length > 1 ? matiere.devoirs[1].note : 0;

            return DataRow(
              cells: [
                DataCell(Text(matiere.nom,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(matiere.coefficient?.toString() ?? '1',
                    textAlign: TextAlign.center)),
                DataCell(Text(inter1 > 0 ? inter1.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(inter2 > 0 ? inter2.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(inter3 > 0 ? inter3.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(inter4 > 0 ? inter4.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(dev1 > 0 ? dev1.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(dev2 > 0 ? dev2.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(moyInterro > 0 ? moyInterro.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(Text(moyDevoirs > 0 ? moyDevoirs.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMoyenneColor(matiere.moyenne).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      matiere.moyenne.toStringAsFixed(1),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getMoyenneColor(matiere.moyenne)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataCell(Text('${matiere.rang}', textAlign: TextAlign.center)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBulletinFooterTable(BulletinAdminModel bulletin) {
    print(
        '🔍 Affichage pied de page - Rang: ${bulletin.rang}, Total: ${bulletin.totalEleves}');

    double minMoyenne = 0;
    double maxMoyenne = 0;

    final matieresData = bulletin.matieresData;

    if (matieresData != null && matieresData.isNotEmpty) {
      final List<double> moyennes = [];
      for (var matiere in matieresData) {
        if (matiere is Map<String, dynamic>) {
          final moyenne = (matiere['moyenne'] ?? 0).toDouble();
          moyennes.add(moyenne);
        }
      }
      if (moyennes.isNotEmpty) {
        minMoyenne = moyennes.reduce((a, b) => a < b ? a : b);
        maxMoyenne = moyennes.reduce((a, b) => a > b ? a : b);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Moyenne trimestrielle: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Plus forte moyenne: ${maxMoyenne.toStringAsFixed(1)}/20',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'Plus faible moyenne: ${minMoyenne.toStringAsFixed(1)}/20',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'Rang général: ${bulletin.rang ?? "?"}/${bulletin.totalEleves ?? "?"}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMoyenneColor(bulletin.moyenneGenerale).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Appréciation:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    bulletin.appreciation.isNotEmpty
                        ? bulletin.appreciation
                        : 'Très bons résultats.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPdfButton(BulletinAdminModel bulletin) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _exportBulletinToPdf(bulletin),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
        label: const Text(
          'EXPORTER EN PDF',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool center = false, PdfColor? color, bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: 9,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: center
          ? pw.Center(
              child: pw.Text(text, style: style),
            )
          : pw.Text(text, style: style),
    );
  }

  /// Même code couleur que sur l'écran (vert/vert clair/orange/ambre/rouge
  /// selon la moyenne), converti en couleurs PDF. Le PDF exporté n'utilisait
  /// jusqu'ici aucune couleur, contrairement à l'écran.
  /// [opaque]=false renvoie une version pâle, utilisée comme fond.
  PdfColor _pdfMoyenneColor(double moyenne, {bool opaque = true}) {
    if (moyenne >= 16) return opaque ? PdfColors.green : PdfColors.green50;
    if (moyenne >= 14) return opaque ? PdfColors.lightGreen : PdfColors.lightGreen50;
    if (moyenne >= 12) return opaque ? PdfColors.orange : PdfColors.orange50;
    if (moyenne >= 10) return opaque ? PdfColors.amber : PdfColors.amber50;
    return opaque ? PdfColors.red : PdfColors.red50;
  }

  Future<void> _exportBulletinToPdf(BulletinAdminModel bulletin) async {
    try {
      _showSnackBar('📄 Génération du PDF en cours...', isError: false);

      // ⚠️ On utilise la vraie année scolaire renvoyée par le serveur,
      // pas la date du jour.
      final String anneeScolaire = bulletin.anneeScolaire.isNotEmpty
          ? bulletin.anneeScolaire
          : '${DateTime.now().year}-${DateTime.now().year + 1}';

      final matieresData = bulletin.matieresData;
      final List<MatiereBulletinAdmin> matieres = [];

      if (matieresData != null) {
        for (var matiere in matieresData) {
          if (matiere is Map<String, dynamic>) {
            matieres.add(MatiereBulletinAdmin.fromJson(matiere));
          }
        }
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      ' BULLETIN DU ${_getTrimestreLibelle(bulletin.trimestre)} TRIMESTRE',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Divider(thickness: 1),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                            child: pw.Text('Nom: ${bulletin.eleveNom}',
                                style: pw.TextStyle(fontSize: 12))),
                        pw.Expanded(
                            child: pw.Text('Classe: ${bulletin.classe}',
                                style: pw.TextStyle(fontSize: 12))),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                            child: pw.Text('Prénom: ${bulletin.elevePrenom}',
                                style: pw.TextStyle(fontSize: 12))),
                        pw.Expanded(
                            child: pw.Text('Année scolaire: $anneeScolaire',
                                style: pw.TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FixedColumnWidth(80),
                  1: pw.FixedColumnWidth(30),
                  2: pw.FixedColumnWidth(35),
                  3: pw.FixedColumnWidth(35),
                  4: pw.FixedColumnWidth(35),
                  5: pw.FixedColumnWidth(35),
                  6: pw.FixedColumnWidth(35),
                  7: pw.FixedColumnWidth(35),
                  8: pw.FixedColumnWidth(45),
                  9: pw.FixedColumnWidth(45),
                  10: pw.FixedColumnWidth(45),
                  11: pw.FixedColumnWidth(30),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _pdfHeaderCell('Matières'),
                      _pdfHeaderCell('Coef'),
                      _pdfHeaderCell('Inter1'),
                      _pdfHeaderCell('Inter2'),
                      _pdfHeaderCell('Inter3'),
                      _pdfHeaderCell('Inter4'),
                      _pdfHeaderCell('Dev1'),
                      _pdfHeaderCell('Dev2'),
                      _pdfHeaderCell('Moy Interro'),
                      _pdfHeaderCell('Moy Devoirs'),
                      _pdfHeaderCell('Moy Coef'),
                      _pdfHeaderCell('Rang'),
                    ],
                  ),

                  ...matieres.map((matiere) {
                    double moyInterro = 0;
                    if (matiere.interrogations.isNotEmpty) {
                      double sum = 0;
                      for (var n in matiere.interrogations) sum += n.note;
                      moyInterro = sum / matiere.interrogations.length;
                    }

                    double moyDevoirs = 0;
                    if (matiere.devoirs.isNotEmpty) {
                      double sum = 0;
                      for (var n in matiere.devoirs) sum += n.note;
                      moyDevoirs = sum / matiere.devoirs.length;
                    }

                    double inter1 = matiere.interrogations.length > 0
                        ? matiere.interrogations[0].note
                        : 0;
                    double inter2 = matiere.interrogations.length > 1
                        ? matiere.interrogations[1].note
                        : 0;
                    double inter3 = matiere.interrogations.length > 2
                        ? matiere.interrogations[2].note
                        : 0;
                    double inter4 = matiere.interrogations.length > 3
                        ? matiere.interrogations[3].note
                        : 0;
                    double dev1 = matiere.devoirs.length > 0
                        ? matiere.devoirs[0].note
                        : 0;
                    double dev2 = matiere.devoirs.length > 1
                        ? matiere.devoirs[1].note
                        : 0;

                    return pw.TableRow(
                      children: [
                        _pdfCell(matiere.nom),
                        _pdfCell(matiere.coefficient?.toString() ?? '1',
                            center: true),
                        _pdfCell(inter1 > 0 ? inter1.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(inter2 > 0 ? inter2.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(inter3 > 0 ? inter3.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(inter4 > 0 ? inter4.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(dev1 > 0 ? dev1.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(dev2 > 0 ? dev2.toStringAsFixed(0) : '-',
                            center: true),
                        _pdfCell(
                            moyInterro > 0 ? moyInterro.toStringAsFixed(1) : '-',
                            center: true),
                        _pdfCell(
                            moyDevoirs > 0 ? moyDevoirs.toStringAsFixed(1) : '-',
                            center: true),
                        _pdfCell(matiere.moyenne.toStringAsFixed(1),
                            center: true,
                            color: _pdfMoyenneColor(matiere.moyenne),
                            bold: true),
                        _pdfCell('${matiere.rang}', center: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            'Moyenne trimestrielle: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                                color: _pdfMoyenneColor(bulletin.moyenneGenerale)),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Plus forte moyenne: ${_getMaxMoyenne(matieres).toStringAsFixed(1)}/20',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Plus faible moyenne: ${_getMinMoyenne(matieres).toStringAsFixed(1)}/20',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'Rang: ${bulletin.rang ?? "--"}/${bulletin.totalEleves ?? "--"}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Text('Appréciation: ',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Expanded(
                          child: pw.Text(
                            bulletin.appreciation.isNotEmpty
                                ? bulletin.appreciation
                                : 'Très bons résultats. Continuez ainsi !',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Column(
                children: [
                  pw.Divider(),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      'Document généré automatiquement par SchoolApp',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Center(
                    child: pw.Text(
                      'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              'fiche_note_${bulletin.eleveNom}_T${bulletin.trimestre}.pdf');

      _showSnackBar('✅ PDF exporté avec succès', isError: false);
    } catch (e) {
      print('❌ Erreur export PDF: $e');
      _showSnackBar('Erreur lors de la génération du PDF');
    }
  }

  double _getMaxMoyenne(List<MatiereBulletinAdmin> matieres) {
    if (matieres.isEmpty) return 0;
    double max = matieres.first.moyenne;
    for (var m in matieres) {
      if (m.moyenne > max) max = m.moyenne;
    }
    return max;
  }

  double _getMinMoyenne(List<MatiereBulletinAdmin> matieres) {
    if (matieres.isEmpty) return 0;
    double min = matieres.first.moyenne;
    for (var m in matieres) {
      if (m.moyenne < min) min = m.moyenne;
    }
    return min;
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
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Rechercher un élève...',
            hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade500 : Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFF47C3C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDarkMode ? Colors.grey.shade500 : Colors.grey, size: 18),
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
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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

  Widget _buildClassSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 45,
      margin: const EdgeInsets.all(12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._classes.map((classe) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(classe.nom),
              selected: _selectedClasseId == classe.id,
              onSelected: (_) {
                setState(() {
                  _selectedClasseId = classe.id;
                  _searchController.clear();
                  _searchQuery = '';
                });
                _loadBulletins();
              },
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey[200],
              selectedColor: const Color(0xFFF47C3C).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedClasseId == classe.id ? const Color(0xFFF47C3C) : (isDarkMode ? Colors.grey.shade400 : Colors.grey[700]),
                fontWeight: _selectedClasseId == classe.id ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrimestreSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTrimestre,
          isExpanded: true,
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          items: _trimestres.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text('Trimestre $t'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTrimestre = value;
                _searchController.clear();
                _searchQuery = '';
              });
              _loadBulletins();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generateAllBulletins,
              icon: const Icon(Icons.add),
              label: const Text('Générer tous les bulletins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C3C),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Aucun bulletin trouvé' : 'Aucun bulletin généré',
            style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
          ),
          if (_searchQuery.isEmpty)
            const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            Text(
              'Générez des bulletins pour cette classe',
              style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade500 : Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildBulletinCard(BulletinAdminModel bulletin) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: InkWell(
        onTap: () => _viewBulletin(bulletin),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF47C3C), Color(0xFFFF6B35)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    bulletin.fullName.isNotEmpty ? bulletin.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bulletin.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bulletin.classe,
                      style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(isDarkMode ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trimestre ${bulletin.trimestre}',
                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMoyenneColor(bulletin.moyenneGenerale).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Moy: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getMoyenneColor(bulletin.moyenneGenerale),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _deleteBulletin(bulletin),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: isDarkMode ? Colors.grey.shade600 : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey[600]),
          ),
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