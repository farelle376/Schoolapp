// lib/screens/student_dashboard_page.dart

import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../services/api_service.dart';
import '../model/note_model.dart';
import '../model/matiere_model.dart';
import '../model/schedule_model.dart';
import '../model/bulletin_model.dart';
import '../model/tranche_paiement_model.dart';
import '../model/payment_model.dart';
import 'payment_webview_screen.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/pdf_service.dart';
import 'package:pdf/widgets.dart' as pw;

class StudentDashboardPage extends StatefulWidget {
  final int inscriptionId;          
  final int childId;             
  final String childName;
  final String childClass;
  final String parentInitiales;
  final String parentNom;
  final Map<String, dynamic> parentData;
  final String mode;

  const StudentDashboardPage({
    Key? key,
    required this.inscriptionId,
    required this.childId,
    required this.childName,
    required this.childClass,
    required this.parentInitiales,
    required this.parentNom,
    required this.parentData,
    this.mode = 'parent',
  }) : super(key: key);

  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  // ✅ mode: 'parent' — sans ça, le service lit le token 'admin_token'
  // (jamais défini dans une session parent), ce qui envoie un Bearer
  // vide/invalide et fait échouer emploi du temps / notes / paiements.
  final ParentService _parentService = ParentService(mode: 'parent');
  final ApiService _api = ApiService();

  int _selectedIndex = 0;
  int _selectedScheduleTab = 0;
  bool _isLoading = true;
  Set<int> _downloadingIds = {};

  List<ScheduleModel> _schedule = [];
  List<ScheduleModel> _coursList = [];
  List<ScheduleModel> _tdList = [];
  List<ScheduleModel> _evaluationList = [];

  List<MatiereModel> _matieres = [];
  String _selectedTrimestre = '1';
  List<String> _trimestres = ['1', '2', '3'];
  double _moyenneGenerale = 0;
  int? _rangGeneral;
  int? _totalEleves;

  List<BulletinModel> _bulletins = [];

  List<TranchePaiementModel> _tranches = [];
  List<PaiementModel> _historiquePaiements = [];
  bool _isLoadingTranches = true;
  bool _isLoadingHistorique = true;
  int? _paiementEnCours;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadMatieresWithNotes(),
        _loadSchedule(),
        _loadBulletins(),
        _loadTranches(),
        _loadHistoriquePaiements(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== NOTES ====================
  Future<void> _loadMatieresWithNotes() async {
    try {
      final response = await _parentService.getMyNotes(
        widget.inscriptionId,
        _selectedTrimestre,
      );
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        final List<MatiereModel> matieresTraitees = [];

        for (var matiereData in data) {
          final details = matiereData['details'];
          if (details != null) {
            // Traitement des interrogations (tri et numérotation)
            final interrosData = details['interrogations'];
            List<InterrogationNote> interrosAvecNumero = [];
            if (interrosData != null && interrosData['notes'] != null) {
              final List<dynamic> notesInterros = interrosData['notes'];
              notesInterros.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
              for (int i = 0; i < notesInterros.length; i++) {
                final note = notesInterros[i];
                interrosAvecNumero.add(InterrogationNote(
                  numero: i + 1,
                  note: (note['note'] ?? 0).toDouble(),
                  date: note['date'] ?? '',
                ));
              }
            }

            // Traitement des devoirs (tri et numérotation)
            final devoirsData = details['devoirs'];
            List<DevoirNote> devoirsAvecNumero = [];
            if (devoirsData != null && devoirsData['notes'] != null) {
              final List<dynamic> notesDevoirs = devoirsData['notes'];
              notesDevoirs.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
              for (int i = 0; i < notesDevoirs.length; i++) {
                final note = notesDevoirs[i];
                devoirsAvecNumero.add(DevoirNote(
                  numero: i + 1,
                  note: (note['note'] ?? 0).toDouble(),
                  date: note['date'] ?? '',
                ));
              }
            }

            final nouveauxDetails = DetailsMatiere(
              interrogations: DetailsInterrogations(
                notes: interrosAvecNumero,
                nombre: interrosAvecNumero.length,
                moyenne: interrosData?['moyenne']?.toDouble(),
              ),
              devoirs: DetailsDevoirs(
                notes: devoirsAvecNumero,
                nombre: devoirsAvecNumero.length,
                somme: devoirsData?['somme']?.toDouble(),
              ),
            );

            matieresTraitees.add(MatiereModel(
              id: matiereData['id'] ?? 0,
              nom: matiereData['nom'] ?? '',
              coefficient: matiereData['coefficient'] ?? 1,
              moyenne: matiereData['moyenne']?.toDouble(),
              rang: matiereData['rang'],
              totalEleves: matiereData['total_eleves'],
              peutCalculer: matiereData['peut_calculer'] ?? false,
              aMoyenne: matiereData['a_moyenne'] ?? false,
              details: nouveauxDetails,
              notes: (matiereData['notes'] as List?)?.map((n) => NoteModel.fromJson(n)).toList(),
            ));
          } else {
            matieresTraitees.add(MatiereModel.fromJson(matiereData));
          }
        }

        setState(() {
          _matieres = matieresTraitees;
          _moyenneGenerale = response['moyenne_generale']?.toDouble() ?? 0;
          _rangGeneral = response['rang_general'];
          _totalEleves = response['total_eleves'];
        });
      }
    } catch (e) {
      print('Erreur chargement matières: $e');
      setState(() => _matieres = []);
    }
  }

  // ==================== EMPLOI DU TEMPS ====================
  Future<void> _loadSchedule() async {
    try {
      final schedule = await _parentService.getMySchedule(widget.inscriptionId);
      setState(() {
        _coursList = schedule.where((c) => c.typeCours == 'cours').toList();
        _tdList = schedule.where((c) => c.typeCours == 'td').toList();
        _evaluationList = schedule.where((c) => c.typeCours == 'evaluation').toList();
        _schedule = _coursList;
      });
    } catch (e) {
      print('Erreur getSchedule: $e');
      setState(() {
        _coursList = [];
        _tdList = [];
        _evaluationList = [];
        _schedule = [];
      });
    }
  }

  // ==================== BULLETINS ====================
  Future<void> _loadBulletins() async {
    try {
      final bulletins = await _parentService.getMyReports(widget.inscriptionId);
      setState(() => _bulletins = bulletins);
      print('✅ ${_bulletins.length} bulletins chargés');
    } catch (e) {
      print('❌ Erreur chargement bulletins: $e');
      setState(() => _bulletins = []);
    }
  }

  // ==================== PAIEMENTS ====================
  Future<void> _loadTranches() async {
    setState(() => _isLoadingTranches = true);
    try {
      final tranches = await _parentService.getMyTranchesPaiement(widget.inscriptionId);
      setState(() => _tranches = tranches);
    } catch (e) {
      print('❌ Erreur chargement tranches: $e');
    } finally {
      setState(() => _isLoadingTranches = false);
    }
  }

  Future<void> _loadHistoriquePaiements() async {
    setState(() => _isLoadingHistorique = true);
    try {
      final historique = await _parentService.getMyHistoriquePaiements(widget.inscriptionId);
      setState(() => _historiquePaiements = historique);
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
    } finally {
      setState(() => _isLoadingHistorique = false);
    }
  }

  // ==================== PAIEMENT KKiaPay ====================
  Future<void> _initierPaiement(TranchePaiementModel tranche) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement sécurisé'),
        // ⚠️ SingleChildScrollView : AlertDialog ne rend pas son `content`
        // scrollable par défaut. Sur petit écran, dès que le clavier
        // s'ouvre (saisie nom/email/téléphone), l'espace vertical restant
        // ne suffit plus pour ce Column et ça déborde ("RenderFlex
        // overflowed"). Avec le scroll, le formulaire défile au lieu de
        // déborder.
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              child: Image.network(
                'https://kkiapay.me/img/logo.png',
                errorBuilder: (_, __, ___) => const Icon(Icons.credit_card, size: 40, color: Color(0xFFF47C3C)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF47C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ⚠️ Flexible : deux Text non contraints dans un Row avec
                  // spaceBetween débordent horizontalement dès que la
                  // largeur du dialogue (AlertDialog) est un peu étroite —
                  // "RenderFlex overflowed" sur l'axe horizontal. Le
                  // libellé (plus long) peut maintenant rétrécir/passer à
                  // la ligne au lieu de déborder.
                  const Flexible(
                    child: Text('Montant à payer :', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${tranche.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom complet *', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone *', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous allez être redirigé vers la page de paiement sécurisé',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF47C3C)),
            child: const Text('CONTINUER'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _paiementEnCours = tranche.id);

    try {
      final response = await _api.post('/parent/payer-kkiapay', {
        'inscription_id': widget.inscriptionId,   // ✅ avec inscription_id
        'tranche_id': tranche.id,
        'telephone': phoneController.text,
        'nom': nameController.text,
        'email': emailController.text,
      });

      if (response['success'] == true) {
        final paymentUrl = response['data']['payment_url'];
        final paiementId = response['data']['paiement_id'];

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              paiementId: paiementId,
            ),
          ),
        );

        if (result != null && result['success'] == true) {
          await _loadTranches();
          await _loadHistoriquePaiements();
          _showSnackBar('✅ Paiement réussi !');
        } else if (result != null && result['failed'] == true) {
          // ⚠️ Distingue un échec réel (numéro invalide, fonds
          // insuffisants...) d'une simple annulation par l'utilisateur —
          // voir payment_webview_screen.dart::_marquerEchoue.
          _showSnackBar('❌ Paiement échoué. Veuillez réessayer.');
        } else {
          _showSnackBar('❌ Paiement annulé');
        }
      } else {
        _showSnackBar(response['message'] ?? 'Erreur');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _paiementEnCours = null);
    }
  }

  // ==================== TÉLÉCHARGER REÇU ====================
  Future<void> _telechargerRecu(PaiementModel paiement) async {
    if (paiement.id == 0) {
      _showSnackBar('Reçu non disponible');
      return;
    }

    setState(() {
      _downloadingIds.add(paiement.id);
    });

    try {
      String dateFormatee = paiement.formattedDate;
      if (dateFormatee == 'Date non spécifiée') {
        dateFormatee = DateTime.now().toString().split(' ')[0];
      }

      final bytes = await PdfService.generateReceiptBytes(
        reference: paiement.reference,
        date: dateFormatee,
        eleveNom: widget.childName.split(' ').last,
        elevePrenom: widget.childName.split(' ').first,
        classe: widget.childClass,
        libelle: paiement.libelle,
        description: paiement.description ?? 'Frais de scolarité',
        montant: paiement.montant,
        modePaiement: _getModePaiementLabel(paiement.modePaiement ?? 'espèces'),
      );

      await PdfService.downloadPdf(bytes, 'recu_${paiement.reference}.pdf');
      _showSnackBar('✅ Reçu téléchargé avec succès');
    } catch (e) {
      print('❌ Erreur: $e');
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _downloadingIds.remove(paiement.id);
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('✅') ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF0D2B4E), Color(0xFF1F4E79)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildErrorWidget()
                          : IndexedStack(
                              index: _selectedIndex,
                              children: [
                                _buildScheduleList(),
                                _buildNotesList(),
                                _buildBulletinList(),
                                _buildPaymentsList(),
                              ],
                            ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ET NAVIGATION ====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(color: Color(0xFFF47C3C), shape: BoxShape.circle),
            child: Center(
              child: Text(
                _getInitiales(widget.childName),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.childName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(widget.childClass, style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  widget.parentInitiales,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.calendar_today, 'Emploi du temps', 0),
          _buildNavItem(Icons.grade, 'Notes', 1),
          _buildNavItem(Icons.insert_drive_file, 'Bulletin', 2),
          _buildNavItem(Icons.payment, 'Paiements', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[400], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          const SizedBox(height: 20),
          Text(_error!, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  String _getInitiales(String nomComplet) {
    if (nomComplet.isEmpty) return '?';
    final parts = nomComplet.split(' ');
    String initiales = '';
    for (var part in parts) {
      if (part.isNotEmpty) initiales += part[0].toUpperCase();
    }
    return initiales.length > 2 ? initiales.substring(0, 2) : initiales;
  }

  // ==================== EMPLOI DU TEMPS ====================
  Widget _buildScheduleList() {
    if (_coursList.isEmpty && _tdList.isEmpty && _evaluationList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun cours pour cette semaine', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('L\'emploi du temps sera bientôt disponible', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildScheduleTab('Cours', 0, _coursList.length),
              const SizedBox(width: 12),
              _buildScheduleTab('TD', 1, _tdList.length),
              const SizedBox(width: 12),
              _buildScheduleTab('Évaluations', 2, _evaluationList.length),
            ],
          ),
        ),
        Expanded(child: _buildScheduleContent()),
      ],
    );
  }

  Widget _buildScheduleTab(String title, int index, int count) {
    final isSelected = _selectedScheduleTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedScheduleTab = index;
           _schedule = index == 0 ? _coursList : (index == 1 ? _tdList : _evaluationList);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[300]!, width: 1),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.grey[700])),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                    child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    if (_schedule.isEmpty) {
      String message = _selectedScheduleTab == 0 ? 'Aucun cours magistral' : (_selectedScheduleTab == 1 ? 'Aucun travail dirigé' : 'Aucune évaluation');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final Map<String, List<ScheduleModel>> coursParJour = {};
    for (var cours in _schedule) {
      final jour = cours.jour.toLowerCase();
      if (!coursParJour.containsKey(jour)) coursParJour[jour] = [];
      coursParJour[jour]!.add(cours);
    }

    const order = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: order.map((jour) {
        final coursDuJour = coursParJour[jour] ?? [];
        if (coursDuJour.isEmpty) return const SizedBox.shrink();
        coursDuJour.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_getJourNom(jour), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
            ),
            ...coursDuJour.map((c) => _buildCoursCard(c)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCoursCard(ScheduleModel cours) {
    String heureDebut = cours.heureDebut.length > 5 ? cours.heureDebut.substring(0, 5) : cours.heureDebut;
    String heureFin = cours.heureFin.length > 5 ? cours.heureFin.substring(0, 5) : cours.heureFin;

    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    switch (cours.typeCours) {
      case 'td':
        typeColor = Colors.orange;
        typeIcon = Icons.assignment;
        typeLabel = 'Travaux Dirigés';
        break;
      case 'tp':
        typeColor = Colors.green;
        typeIcon = Icons.science;
        typeLabel = 'Travaux Pratiques';
        break;
      case 'evaluation':
        typeColor = Colors.red;
        typeIcon = Icons.quiz;
        typeLabel = 'Évaluation';
        break;
      default:
        typeColor = const Color(0xFFF47C3C);
        typeIcon = Icons.school;
        typeLabel = 'Cours Magistral';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: cours.typeCours == 'evaluation' ? Border.all(color: Colors.red.withOpacity(0.3), width: 1) : null,
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(typeIcon, color: typeColor, size: 24)),
          ),
          title: Text(cours.matiere, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cours.professeur.isNotEmpty ? cours.professeur : 'Professeur non assigné', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(typeLabel, style: TextStyle(fontSize: 10, color: typeColor)),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(heureDebut, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                Container(width: 2, height: 4, color: Colors.grey[400]),
                Text(heureFin, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getJourNom(String jour) {
    switch (jour) {
      case 'lundi':
        return 'Lundi';
      case 'mardi':
        return 'Mardi';
      case 'mercredi':
        return 'Mercredi';
      case 'jeudi':
        return 'Jeudi';
      case 'vendredi':
        return 'Vendredi';
      case 'samedi':
        return 'Samedi';
      default:
        return jour;
    }
  }

  // ==================== NOTES ====================
  Widget _buildNotesList() {
    // ⚠️ Le backend renvoie une entrée par matière de la classe, même
    // quand aucune note n'a encore été saisie pour le trimestre choisi
    // (chaque matière est alors "vide" : pas d'interro/devoir, pas de
    // moyenne). Du coup `_matieres.isEmpty` ne détecte jamais ce cas —
    // il faut vérifier si TOUTES les matières sont vides pour ce trimestre.
    final bool aucuneNotePourTrimestre = _matieres.isNotEmpty &&
        _matieres.every((m) =>
            (m.details?.interrogations.notes.isEmpty ?? true) &&
            (m.details?.devoirs.notes.isEmpty ?? true));
    final bool estVide = _matieres.isEmpty || aucuneNotePourTrimestre;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Matières', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
              const Spacer(),
              if (_moyenneGenerale > 0 && !estVide)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMoyenneColor(_moyenneGenerale).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.grade, size: 14, color: _getMoyenneColor(_moyenneGenerale)),
                          const SizedBox(width: 4),
                          Text(
                            'Moy: ${_moyenneGenerale.toStringAsFixed(1)}/20',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getMoyenneColor(_moyenneGenerale)),
                          ),
                        ],
                      ),
                      Text(
                        _rangGeneral != null ? 'Rang: $_rangGeneral/$_totalEleves' : 'Rang: --/${_totalEleves ?? 0}',
                        style: TextStyle(fontSize: 10, color: _rangGeneral != null ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF47C3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _selectedTrimestre,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFF47C3C)),
                  underline: const SizedBox(),
                  style: const TextStyle(color: Color(0xFF0D2B4E)),
                  items: _trimestres.map((t) => DropdownMenuItem(value: t, child: Text('Trimestre $t'))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTrimestre = value;
                        // Efface immédiatement l'ancienne liste pour éviter
                        // d'afficher un instant les notes du trimestre précédent.
                        _matieres = [];
                      });
                      _loadMatieresWithNotes();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: estVide
              ? Container(
                  color: Colors.white,
                  width: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grade_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune note disponible pour le Trimestre $_selectedTrimestre',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadMatieresWithNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF47C3C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text('Actualiser'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matieres.length,
                  itemBuilder: (context, index) => _buildMatiereCard(_matieres[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildMatiereCard(MatiereModel matiere) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF47C3C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              matiere.coefficient.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF47C3C)),
            ),
          ),
        ),
        title: Text(matiere.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coefficient: ${matiere.coefficient}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (matiere.details != null && matiere.details!.interrogations.moyenne != null && matiere.details!.devoirs.somme != null)
              Text(
                'Interro: ${matiere.details!.interrogations.moyenne!.toStringAsFixed(1)} | Devoirs: ${matiere.details!.devoirs.somme!.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (matiere.hasMoyenne)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: matiere.moyenneColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(matiere.moyenneTexte, style: TextStyle(fontWeight: FontWeight.bold, color: matiere.moyenneColor)),
              )
            else if (matiere.peutCalculer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('En attente', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            if (matiere.hasRang)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Rang: ${matiere.rangTexte}', style: TextStyle(fontSize: 10, color: matiere.hasRang ? Colors.grey[500] : Colors.grey[400])),
              ),
          ],
        ),
        children: [
          if (matiere.details != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interrogations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  ...matiere.details!.interrogations.notes.map((interro) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Interrogation ${interro.numero}:', style: const TextStyle(fontSize: 13)),
                        Text(
                          '${interro.note.toStringAsFixed(1)}/20',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: interro.note >= 10 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  )),
                  if (matiere.details!.interrogations.moyenne != null) const Divider(),
                  if (matiere.details!.interrogations.moyenne != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Moyenne interrogations:', style: TextStyle(fontSize: 12)),
                        Text(
                          '${matiere.details!.interrogations.moyenne!.toStringAsFixed(1)}/20',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Devoirs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 8),
                  ...matiere.details!.devoirs.notes.map((devoir) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Devoir ${devoir.numero}:', style: const TextStyle(fontSize: 13)),
                        Text(
                          '${devoir.note.toStringAsFixed(1)}/20',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: devoir.note >= 10 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const Divider(),
          ],
          if (matiere.notes != null && matiere.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(),
            ),
        ],
      ),
    );
  }

  // ==================== BULLETIN ====================
  Widget _buildBulletinList() {
    if (_bulletins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun bulletin disponible', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Le bulletin sera disponible une fois publié', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    BulletinModel? selectedBulletin = _bulletins.firstWhere(
      (b) => b.trimestre == _selectedTrimestre,
      orElse: () => _bulletins.first,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletinHeaderTable(selectedBulletin),
                const SizedBox(height: 24),
                _buildNotesTable(selectedBulletin),
                const SizedBox(height: 24),
                _buildBulletinFooterTable(selectedBulletin),
              ],
            ),
          ),
        ),
        _buildExportPdfButton(selectedBulletin),
      ],
    );
  }

  Widget _buildBulletinHeaderTable(BulletinModel bulletin) {
    // ⚠️ On affiche désormais la vraie année scolaire renvoyée par le
    // serveur (celle de l'inscription/du bulletin), plus la date du jour
    // qui ne correspond pas forcément à l'année scolaire du bulletin consulté.
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Nom: ${bulletin.eleveNom}', style: const TextStyle(fontSize: 14))),
              Expanded(child: Text('Classe: ${bulletin.classe}', style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Prénom: ${bulletin.elevePrenom}', style: const TextStyle(fontSize: 14))),
              Expanded(child: Text('Année scolaire: $anneeScolaire', style: const TextStyle(fontSize: 14))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTable(BulletinModel bulletin) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF47C3C).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('Matières', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Coef', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Interro 1', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Interro 2', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Interro 3', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Interro 4', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Devoir 1', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Devoir 2', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Moy Interro', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Moy Devoirs', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Moy Coef', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rang', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: bulletin.matieres.map((matiere) {
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
            double inter1 = matiere.interrogations.length > 0 ? matiere.interrogations[0].note : 0;
            double inter2 = matiere.interrogations.length > 1 ? matiere.interrogations[1].note : 0;
            double inter3 = matiere.interrogations.length > 2 ? matiere.interrogations[2].note : 0;
            double inter4 = matiere.interrogations.length > 3 ? matiere.interrogations[3].note : 0;
            double dev1 = matiere.devoirs.length > 0 ? matiere.devoirs[0].note : 0;
            double dev2 = matiere.devoirs.length > 1 ? matiere.devoirs[1].note : 0;

            return DataRow(
              cells: [
                DataCell(Text(matiere.nom)),
                DataCell(Text(matiere.coefficient?.toString() ?? '1')),
                DataCell(Text(inter1 > 0 ? inter1.toStringAsFixed(1) : '-')),
                DataCell(Text(inter2 > 0 ? inter2.toStringAsFixed(1) : '-')),
                DataCell(Text(inter3 > 0 ? inter3.toStringAsFixed(1) : '-')),
                DataCell(Text(inter4 > 0 ? inter4.toStringAsFixed(1) : '-')),
                DataCell(Text(dev1 > 0 ? dev1.toStringAsFixed(1) : '-')),
                DataCell(Text(dev2 > 0 ? dev2.toStringAsFixed(1) : '-')),
                DataCell(Text(moyInterro > 0 ? moyInterro.toStringAsFixed(1) : '-')),
                DataCell(Text(moyDevoirs > 0 ? moyDevoirs.toStringAsFixed(1) : '-')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: matiere.moyenneColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      matiere.moyenneTexte,
                      style: TextStyle(fontWeight: FontWeight.bold, color: matiere.moyenneColor),
                    ),
                  ),
                ),
                DataCell(Text(matiere.rangTexte)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBulletinFooterTable(BulletinModel bulletin) {
    double minMoyenne = bulletin.matieres.map((m) => m.moyenne).reduce((a, b) => a < b ? a : b);
    double maxMoyenne = bulletin.matieres.map((m) => m.moyenne).reduce((a, b) => a > b ? a : b);

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
              Expanded(child: Text('Moyenne trimestrielle: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              Expanded(child: Text('Plus forte moyenne: ${maxMoyenne.toStringAsFixed(1)}/20', style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Plus faible moyenne: ${minMoyenne.toStringAsFixed(1)}/20', style: const TextStyle(fontSize: 14))),
              Expanded(child: Text('Rang: ${bulletin.rang}/${bulletin.totalEleves}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bulletin.mentionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Appréciation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(child: Text(bulletin.appreciation ?? 'Très bons résultats. Vous êtes sur la bonne voie.', style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPdfButton(BulletinModel bulletin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () => _exportBulletinToPdf(bulletin),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
          label: const Text('EXPORTER EN PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Future<void> _exportBulletinToPdf(BulletinModel bulletin) async {
    try {
      _showSnackBar('📄 PDF exporté');
      // ⚠️ Même correctif que côté écran : on utilise la vraie année
      // scolaire renvoyée par le serveur, pas la date du jour.
      final String anneeScolaire = bulletin.anneeScolaire.isNotEmpty
          ? bulletin.anneeScolaire
          : '${DateTime.now().year}-${DateTime.now().year + 1}';

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (_) => [
            pw.Center(
              child: pw.Text(
                'BULLETIN DU ${_getTrimestreLibelle(bulletin.trimestre)} TRIMESTRE',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(children: [pw.Expanded(child: pw.Text('Nom: ${bulletin.eleveNom}')), pw.Expanded(child: pw.Text('Classe: ${bulletin.classe}'))]),
            pw.SizedBox(height: 10),
            pw.Row(children: [pw.Expanded(child: pw.Text('Prénom: ${bulletin.elevePrenom}')), pw.Expanded(child: pw.Text('Année scolaire: $anneeScolaire'))]),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  // ⚠️ Le PDF n'appliquait jusqu'ici aucune couleur — tout
                  // sortait en noir et blanc alors que l'écran colore les
                  // moyennes (vert/orange/rouge) selon leur valeur. On
                  // reproduit ce code couleur dans le PDF exporté.
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                  children: [
                    _pdfHeaderCell('Matières'),
                    _pdfHeaderCell('Coef'),
                    _pdfHeaderCell('Inter1'),
                    _pdfHeaderCell('Inter2'),
                    _pdfHeaderCell('Inter3'),
                    _pdfHeaderCell('Inter4'),
                    _pdfHeaderCell('Dev1'),
                    _pdfHeaderCell('Dev2'),
                    _pdfHeaderCell('MInter'),
                    _pdfHeaderCell('MDev'),
                    _pdfHeaderCell('MCoef'),
                    _pdfHeaderCell('Rng'),
                  ],
                ),
                ...bulletin.matieres.map((matiere) {
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
                  return pw.TableRow(
                    children: [
                      _pdfCell(matiere.nom),
                      _pdfCell(matiere.coefficient?.toString() ?? '1'),
                      _pdfCell(matiere.interrogations.length > 0 ? matiere.interrogations[0].note.toStringAsFixed(0) : '-'),
                      _pdfCell(matiere.interrogations.length > 1 ? matiere.interrogations[1].note.toStringAsFixed(0) : '-'),
                      _pdfCell(matiere.interrogations.length > 2 ? matiere.interrogations[2].note.toStringAsFixed(0) : '-'),
                      _pdfCell(matiere.interrogations.length > 3 ? matiere.interrogations[3].note.toStringAsFixed(0) : '-'),
                      _pdfCell(matiere.devoirs.length > 0 ? matiere.devoirs[0].note.toStringAsFixed(0) : '-'),
                      _pdfCell(matiere.devoirs.length > 1 ? matiere.devoirs[1].note.toStringAsFixed(0) : '-'),
                      _pdfCell(moyInterro > 0 ? moyInterro.toStringAsFixed(1) : '-'),
                      _pdfCell(moyDevoirs > 0 ? moyDevoirs.toStringAsFixed(1) : '-'),
                      _pdfCell(matiere.moyenneTexte, color: _pdfMoyenneColor(matiere.moyenne), bold: true),
                      _pdfCell(matiere.rangTexte),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Text(
                  'Moyenne trimestrielle: ${bulletin.moyenneGenerale.toStringAsFixed(1)}/20',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfMoyenneColor(bulletin.moyenneGenerale),
                  ),
                ),
              ),
              pw.Expanded(child: pw.Text('Rang: ${bulletin.rang}/${bulletin.totalEleves}')),
            ]),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _pdfMoyenneColor(bulletin.moyenneGenerale, opaque: false),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text('Appréciation: ${bulletin.appreciation ?? "Très bons résultats."}'),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'bulletin_${bulletin.eleveNom}_T${bulletin.trimestre}.pdf');
    } catch (e) {
      print('❌ Erreur export PDF: $e');
      _showSnackBar('Erreur lors de la génération du PDF');
    }
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Container(padding: pw.EdgeInsets.all(8), child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
  }

  pw.Widget _pdfCell(String text, {PdfColor? color, bool bold = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Même code couleur que sur l'écran (Colors.green/lightGreen/orange/
  /// amber/red selon la moyenne), converti en couleurs PDF.
  /// [opaque]=false renvoie une version pâle, utilisée comme fond.
  PdfColor _pdfMoyenneColor(double moyenne, {bool opaque = true}) {
    if (moyenne >= 16) return opaque ? PdfColors.green : PdfColors.green50;
    if (moyenne >= 14) return opaque ? PdfColors.lightGreen : PdfColors.lightGreen50;
    if (moyenne >= 12) return opaque ? PdfColors.orange : PdfColors.orange50;
    if (moyenne >= 10) return opaque ? PdfColors.amber : PdfColors.amber50;
    return opaque ? PdfColors.red : PdfColors.red50;
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

  // ==================== PAIEMENTS ====================
  Widget _buildPaymentsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tranches de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
          const SizedBox(height: 12),
          if (_isLoadingTranches)
            const Center(child: CircularProgressIndicator())
          else if (_tranches.isEmpty)
            const Center(child: Text('Aucune tranche disponible'))
          else
            ..._tranches.map((t) => _buildTrancheCard(t)),
          const SizedBox(height: 24),
          const Text('Historique des paiements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
          const SizedBox(height: 12),
          if (_isLoadingHistorique)
            const Center(child: CircularProgressIndicator())
          else if (_historiquePaiements.isEmpty)
            const Center(child: Text('Aucun paiement effectué'))
          else
            ..._historiquePaiements.map((p) => _buildRecuCard(p)),
        ],
      ),
    );
  }

  Widget _buildTrancheCard(TranchePaiementModel tranche) {
    final isLoading = _paiementEnCours == tranche.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tranche.libelle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tranche.estPaye ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tranche.estPaye ? 'Payé' : 'En attente', style: TextStyle(color: tranche.estPaye ? Colors.green : Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Montant: ${tranche.montantFormatted}'),
            const SizedBox(height: 12),
            if (!tranche.estPaye)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _initierPaiement(tranche),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C3C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('PAYER'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecuCard(PaiementModel paiement) {
    final isPaye = paiement.estValide;
    final isEchoue = paiement.estRefuse;
    final isLoading = _downloadingIds.contains(paiement.id);
    // Couleur du badge/icône : vert = payé, rouge = échoué, orange = en attente.
    final statusColor = isPaye ? Colors.green : (isEchoue ? Colors.red : Colors.orange);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isEchoue ? Icons.error_outline : Icons.receipt, color: statusColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paiement.libelle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(paiement.montantFormatted, style: const TextStyle(fontSize: 12)),
                  if (paiement.datePaiement != null) Text('Payé le: ${paiement.formattedDate}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  if (paiement.modePaiement != null) Text('Mode: ${_getModePaiementLabel(paiement.modePaiement!)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            // ⚠️ Un paiement échoué n'a pas de reçu à télécharger (aucun PDF
            // n'est généré côté serveur pour un paiement 'refuse') : on
            // remplace le bouton de téléchargement par un statut visuel
            // au lieu de proposer un téléchargement qui échouerait.
            if (isEchoue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Échoué',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              )
            else
              isLoading
                  ? const SizedBox(width: 40, height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF47C3C))))
                  : IconButton(
                      icon: const Icon(Icons.download, color: Colors.blue),
                      onPressed: () => _telechargerRecu(paiement),
                      tooltip: 'Télécharger',
                    ),
          ],
        ),
      ),
    );
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'mtn':
        return 'MTN';
      case 'moov':
        return 'Moov';
      case 'celtis':
        return 'Celtis';
      default:
        return mode;
    }
  }

  Color _getMoyenneColor(double moyenne) {
    if (moyenne >= 16) return Colors.green;
    if (moyenne >= 14) return Colors.lightGreen;
    if (moyenne >= 12) return Colors.orange;
    if (moyenne >= 10) return Colors.amber;
    return Colors.red;
  }
}