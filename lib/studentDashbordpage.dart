// lib/screens/studentdashboardpage.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/note_model.dart';
import '../model/payment_model.dart';
import '../model/tranche_paiement_model.dart';
import '../model/schedule_model.dart';
import '../model/matiere_model.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'kkiapay_payment_screen.dart';
import '../services/pdf_service.dart';
import 'package:universal_html/html.dart' as html;

class StudentDashboardPage extends StatefulWidget {
  final int childId;
  final String childName;
  final String childClass;
  final String parentInitiales;
  final String parentNom;
  final Map<String, dynamic> parentData;

  const StudentDashboardPage({
    Key? key,
    required this.childId,
    required this.childName,
    required this.childClass,
    required this.parentInitiales,
    required this.parentNom,
    required this.parentData,
  }) : super(key: key);

  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _selectedIndex = 0;
  int _selectedScheduleTab = 0;
  bool _isLoading = true;
 Set<int> _downloadingIds = {};
  List<TranchePaiementModel> _tranches = [];
  List<PaiementModel> _historiquePaiements = [];
  bool _isLoadingTranches = true;
  bool _isLoadingHistorique = true;
  int? _paiementEnCours;
  List<ScheduleModel> _schedule = [];
  List<ScheduleModel> _coursList = [];
  List<ScheduleModel> _tdList = [];
  List<ScheduleModel> _evaluationList = [];
  List<dynamic> _bulletins = [];
  List<MatiereModel> _matieres = [];
  String _selectedTrimestre = '1';
  List<String> _trimestres = ['1', '2', '3'];
  double _moyenneGenerale = 0;
  int? _rangGeneral;
  int? _totalEleves;
  String? _error;

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _coursList = [];
    _tdList = [];
    _evaluationList = [];
    _schedule = [];
    _loadData();
  }


Future<void> _loadTranches() async {
  setState(() {
    _isLoadingTranches = true;
  });

  try {
    final response = await _api.get('/parent/children/${widget.childId}/tranches-paiement');
    
    print('📦 Response tranches: $response');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      print('✅ Tranches reçues: ${data.length}');
      
      setState(() {
        _tranches = data.map((json) => TranchePaiementModel.fromJson(json)).toList();
      });
    } else {
      print('❌ Erreur tranches: ${response['message']}');
    }
  } catch (e) {
    print('❌ Erreur chargement tranches: $e');
  } finally {
    setState(() {
      _isLoadingTranches = false;
    });
  }
}

Future<void> _telechargerRecu(PaiementModel paiement) async {
  if (paiement.id == 0) {
    _showSnackBar('Reçu non disponible');
    return;
  }

  // Ajouter l'ID à l'ensemble des téléchargements en cours
  setState(() {
    _downloadingIds.add(paiement.id);
  });

  try {
    // Formater la date
    String dateFormatee = paiement.formattedDate;
    if (dateFormatee == 'Date non spécifiée') {
      dateFormatee = DateTime.now().toString().split(' ')[0];
    }
    
    // Générer le PDF
    final bytes = await PdfService.generateReceiptBytes(
      reference: paiement.reference,
      date: dateFormatee,
      eleveNom: widget.childName.split(' ').last,
      elevePrenom: widget.childName.split(' ').first,
      classe: widget.childClass,
      libelle: paiement.libelle,
      description: paiement.description ?? 'Frais de scolarité',
      montant: paiement.montant,
      modePaiement: _getModePaiementLabel(paiement.modePaiement ?? 'kkiapay'),
    );
    
    // Télécharger le PDF
    await PdfService.downloadPdf(bytes, 'recu_${paiement.reference}.pdf');
    
    _showSnackBar('✅ Reçu téléchargé avec succès');
    print('📄 Génération du reçu:');
    print('  - Référence: ${paiement.reference}');
    print('  - Date: $dateFormatee');
    print('  - Élève: ${widget.childName}');
    print('  - Classe: ${widget.childClass}');
    print('  - Libellé: ${paiement.libelle}');
    print('  - Montant: ${paiement.montant}');
    print('  - Mode: ${_getModePaiementLabel(paiement.modePaiement ?? 'kkiapay')}');
  } catch (e) {
    print('❌ Erreur: $e');
    _showSnackBar('Erreur: $e');
  } finally {
    // Retirer l'ID de l'ensemble
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

Future<void> _loadHistoriquePaiements() async {
  setState(() {
    _isLoadingHistorique = true;
  });

  try {
    final response = await _api.get('/parent/children/${widget.childId}/historique-paiements');
    
    print('📦 Response historique: $response');
    
    if (response['success'] == true) {
      final List<dynamic> data = response['data'];
      print('✅ Historique reçu: ${data.length} paiements');
      
      setState(() {
        _historiquePaiements = data.map((json) => PaiementModel.fromJson(json)).toList();
      });
    } else {
      print('❌ Erreur historique: ${response['message']}');
    }
  } catch (e) {
    print('❌ Erreur chargement historique: $e');
  } finally {
    setState(() {
      _isLoadingHistorique = false;
    });
  }
}
Widget _buildRecuCard(PaiementModel paiement) {
  final isPaye = paiement.estValide;
  final isLoading = _downloadingIds.contains(paiement.id);
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isPaye ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt,
              color: isPaye ? Colors.green : Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paiement.libelle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  paiement.montantFormatted,
                  style: const TextStyle(fontSize: 12),
                ),
                if (paiement.datePaiement != null)
                  Text(
                    'Payé le: ${paiement.formattedDate}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                if (paiement.modePaiement != null)
                  Text(
                    'Mode: ${_getModePaiementLabel(paiement.modePaiement!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          // Bouton de téléchargement avec indicateur
          isLoading
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF47C3C),
                    ),
                  ),
                )
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


Future<void> _initierPaiement(TranchePaiementModel tranche) async {
  // Créer les contrôleurs pour le dialogue
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text(
        'Paiement sécurisé',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D2B4E),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo KKiaPay
            Container(
              height: 60,
              child: Image.network(
                'https://kkiapay.me/img/logo.png',
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.credit_card,
                  size: 40,
                  color: Color(0xFFF47C3C),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Montant
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF47C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant à payer :',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${tranche.montant.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF47C3C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Champ Nom complet
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Entrez votre nom et prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            // Champ Email
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                hintText: 'exemple@email.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            // Champ Téléphone
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: 'Ex: 97123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous allez être redirigé vers la page de paiement sécurisé',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isEmpty ||
                emailController.text.isEmpty ||
                phoneController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez remplir tous les champs'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            // Sauvegarder les informations dans parentData
            final parentData = widget.parentData;
            parentData['prenom'] = nameController.text;
            parentData['email'] = emailController.text;
            parentData['telephone'] = phoneController.text;
            
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF47C3C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('PAYER'),
        ),
      ],
    ),
  );

  if (result == true) {
    // Appeler la méthode de paiement avec UN SEUL paramètre
    await _initierPaiementKKiaPay(tranche);
  }
}


// lib/screens/studentdashboardpage.dart

Future<void> _initierPaiementKKiaPay(TranchePaiementModel tranche) async {
  setState(() {
    _paiementEnCours = tranche.id;
  });

  try {
    final parentData = widget.parentData;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KkiapayPaymentScreen(
          amount: tranche.montant.toStringAsFixed(0),
          phone: parentData['telephone'] ?? '97000000',
          name: parentData['prenom'] ?? 'Parent',
          email: parentData['email'] ?? 'parent@schoolapp.com',
          trancheId: tranche.id,
        ),
      ),
    );
    
    print('📦 Résultat paiement: $result');
    
    if (result != null && result['success'] == true) {
      // Vérifier le paiement avec le backend
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final verification = await _api.post('/parent/verifier-paiement', {
        'transaction_id': result['transactionId'],
        'tranche_id': tranche.id,
      });
      
      if (mounted) Navigator.pop(context);
      
      if (verification['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement réussi !'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadTranches();
        await _loadHistoriquePaiements();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verification['message'] ?? '❌ Erreur lors de la vérification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() {
      _paiementEnCours = null;
    });
  }
}
Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      _showSnackBar('Impossible d\'ouvrir le lien de paiement');
    }
  } catch (e) {
    print('Erreur lancement URL: $e');
    _showSnackBar('Erreur: $e');
  }
}


Future<String?> _showTelephoneDialog() async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Numéro de téléphone'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: 'Ex: 771234567',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF47C3C),
          ),
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}


  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadMatieresWithNotes();
      await _loadTranches();
      await _loadHistoriquePaiements();
      await _loadSchedule();

      final bulletinsResponse = await _api.get('/parent/children/${widget.childId}/reports');
      if (bulletinsResponse['success'] == true) {
        setState(() {
          _bulletins = bulletinsResponse['data'] ?? [];
        });
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMatieresWithNotes() async {
    try {
      final response = await _api.get(
        '/parent/children/${widget.childId}/notes?trimestre=$_selectedTrimestre'
      );
      
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        setState(() {
          _matieres = data.map((json) => MatiereModel.fromJson(json)).toList();
          _moyenneGenerale = response['moyenne_generale']?.toDouble() ?? 0;
          _rangGeneral = response['rang_general'];
          _totalEleves = response['total_eleves'];
        });
      }
    } catch (e) {
      print('Erreur chargement matières: $e');
      setState(() {
        _matieres = [];
      });
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final response = await _api.get('/parent/children/${widget.childId}/schedule');
      
      if (response['success'] == true) {
        final scheduleData = response['data'];
        
        if (scheduleData is List) {
          final allCourses = ScheduleModel.fromList(scheduleData);
          
          setState(() {
            _coursList = allCourses.where((c) => c.typeCours == 'cours').toList();
            _tdList = allCourses.where((c) => c.typeCours == 'td').toList();
            _evaluationList = allCourses.where((c) => c.typeCours == 'evaluation').toList();
            _schedule = _coursList;
          });
        } else {
          setState(() {
            _coursList = [];
            _tdList = [];
            _evaluationList = [];
            _schedule = [];
          });
        }
      } else {
        setState(() {
          _coursList = [];
          _tdList = [];
          _evaluationList = [];
          _schedule = [];
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFF0D2B4E),
              Color(0xFF1F4E79),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF47C3C),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitiales(widget.childName),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.childName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.childClass,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.parentInitiales,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
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
              
              // Navigation en bas
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[400],
              size: 24,
            ),
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
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF47C3C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  String _getInitiales(String nomComplet) {
    if (nomComplet.isEmpty) return '?';
    List<String> parts = nomComplet.split(' ');
    String initiales = '';
    for (var part in parts) {
      if (part.isNotEmpty) {
        initiales += part[0].toUpperCase();
      }
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
            Text(
              'Aucun cours pour cette semaine',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'L\'emploi du temps sera bientôt disponible',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
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
            switch (index) {
              case 0:
                _schedule = _coursList;
                break;
              case 1:
                _schedule = _tdList;
                break;
              case 2:
                _schedule = _evaluationList;
                break;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? const Color(0xFFF47C3C) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
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
      String message = '';
      switch (_selectedScheduleTab) {
        case 0:
          message = 'Aucun cours magistral';
          break;
        case 1:
          message = 'Aucun travail dirigé';
          break;
        case 2:
          message = 'Aucune évaluation';
          break;
      }
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
      if (!coursParJour.containsKey(jour)) {
        coursParJour[jour] = [];
      }
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
              child: Text(
                _getJourNom(jour),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B4E),
                ),
              ),
            ),
            ...coursDuJour.map((cours) => _buildCoursCard(cours)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCoursCard(ScheduleModel cours) {
    String heureDebut = cours.heureDebut;
    String heureFin = cours.heureFin;
    
    if (heureDebut.length > 5) heureDebut = heureDebut.substring(0, 5);
    if (heureFin.length > 5) heureFin = heureFin.substring(0, 5);
    
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
          border: cours.typeCours == 'evaluation' 
              ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
              : null,
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(typeIcon, color: typeColor, size: 24)),
          ),
          title: Text(cours.matiere, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cours.professeur.isNotEmpty ? cours.professeur : 'Professeur non assigné',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(typeLabel, style: TextStyle(fontSize: 10, color: typeColor)),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
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
      case 'lundi': return 'Lundi';
      case 'mardi': return 'Mardi';
      case 'mercredi': return 'Mercredi';
      case 'jeudi': return 'Jeudi';
      case 'vendredi': return 'Vendredi';
      case 'samedi': return 'Samedi';
      default: return jour;
    }
  }

  // ==================== NOTES ====================

  Widget _buildNotesList() {
    if (_matieres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucune note disponible', style: TextStyle(color: Colors.grey[600])),
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
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Matières', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2B4E))),
              const Spacer(),
              if (_moyenneGenerale > 0)
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
                            'Moy: ${_moyenneGenerale.toStringAsFixed(1)}/20'
                            'Moy: --/20',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getMoyenneColor(_moyenneGenerale)),
                          ),
                        ],
                      ),
                      Text(
                      _rangGeneral != null 
                          ? 'Rang: $_rangGeneral/$_totalEleves' 
                          : 'Rang: --/${_totalEleves ?? 0}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _rangGeneral != null ? Colors.grey[600] : Colors.grey[400],
                      ),
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
                  items: _trimestres.map((trimestre) {
                    return DropdownMenuItem<String>(
                      value: trimestre,
                      child: Text('Trimestre $trimestre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTrimestre = value);
                      _loadMatieresWithNotes();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
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
                child: Text(
                  matiere.moyenneTexte,
                  style: TextStyle(fontWeight: FontWeight.bold, color: matiere.moyenneColor),
                ),
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
            child: Text(
              'Rang: ${matiere.rangTexte}',  // Affiche "--/25" si pas de rang
              style: TextStyle(
                fontSize: 10,
                color: matiere.hasRang ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
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
              child: Column(
                children: [
                  const Text('Toutes les notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...matiere.notes!.map((note) => _buildNoteItem(note)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(NoteModel note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: note.getTypeNoteColor(), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(note.getTypeNoteLabel(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: note.getTypeNoteColor())),
                    const SizedBox(width: 8),
                    Expanded(child: Text(note.appreciation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(note.date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: note.note >= 10 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${note.note.toStringAsFixed(1)}/20',
              style: TextStyle(fontWeight: FontWeight.bold, color: note.note >= 10 ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BULLETIN ====================

  Widget _buildBulletinList() {
    if (_bulletins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun bulletin disponible', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bulletins.length,
      itemBuilder: (context, index) {
        final bulletin = _bulletins[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
            title: Text('Trimestre ${bulletin['trimestre'] ?? index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(bulletin['mention'] ?? 'En attente'),
            trailing: const Icon(Icons.download, color: Colors.grey),
            onTap: () {},
          ),
        );
      },
    );
  }

Widget _buildPaymentsList() {
  print('🏦 Construction liste paiements');
  print('🏦 Tranches: ${_tranches.length}');
  print('🏦 Historique: ${_historiquePaiements.length}');
  
  // Afficher les détails des tranches
  for (var t in _tranches) {
    print('🏦 Tranche: ${t.libelle} - ${t.montant} - ${t.estPaye}');
  }
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section des tranches
        const Text(
          'Tranches de paiement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2B4E),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingTranches)
          const Center(child: CircularProgressIndicator())
        else if (_tranches.isEmpty)
          const Center(
            child: Text('Aucune tranche disponible'),
          )
        else
          ..._tranches.map((tranche) => _buildTrancheCard(tranche)),
        
        const SizedBox(height: 24),
        
        // Section des reçus
        const Text(
          'Historique des paiements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2B4E),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingHistorique)
          const Center(child: CircularProgressIndicator())
        else if (_historiquePaiements.isEmpty)
          const Center(
            child: Text('Aucun paiement effectué'),
          )
        else
          ..._historiquePaiements.map((paiement) => _buildRecuCard(paiement)),
      ],
    ),
  );
}

Widget _buildTrancheCard(TranchePaiementModel tranche) {
  final isLoading = _paiementEnCours == tranche.id;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tranche.libelle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B4E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tranche.estPaye
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tranche.estPaye ? 'Payé' : 'En attente',
                  style: TextStyle(
                    fontSize: 12,
                    color: tranche.estPaye ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Montant: ${tranche.montantFormatted}',
            style: const TextStyle(fontSize: 14),
          ),
          if (tranche.description != null)
            Text(
              tranche.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (tranche.dateLimite != null && !tranche.estPaye)
            Text(
              'Date limite: ${_formatDate(tranche.dateLimite!)}',
              style: TextStyle(fontSize: 12, color: Colors.red[400]),
            ),
          const SizedBox(height: 12),
          if (!tranche.estPaye)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _initierPaiement(tranche), // <-- Appel correct
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47C3C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('PAYER'),
              ),
            ),
        ],
      ),
    ),
  );
}
// Ajoutez cette méthode pour formater la date
String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  } catch (e) {
    return dateString;
  }
}

String _getModePaiementLabel(String mode) {
  switch (mode) {
    case 'mobile Money':
      return 'mobile Money';
    case 'celtis':
      return 'celtis';
    case 'moov':
      return 'moov';
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