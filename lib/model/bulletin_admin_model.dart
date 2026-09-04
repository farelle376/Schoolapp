
class ClasseInfo {
  final int id;
  final String nom;

  ClasseInfo({
    required this.id,
    required this.nom,
  });

  factory ClasseInfo.fromJson(Map<String, dynamic> json) {
    return ClasseInfo(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
    );
  }
}

class BulletinAdminModel {
  final int id;
  final int inscriptionId;
  final String eleveNom;
  final String elevePrenom;
  final String classe;
  final String anneeScolaire;
  final String trimestre;
  final double moyenneGenerale;
  final String mention;
  final int? rang;
  final int? totalEleves; 
  final String appreciation;
  final List<dynamic> notes;
  final DateTime createdAt;

  final List<dynamic>? matieresData;

  BulletinAdminModel({
    required this.id,
    required this.inscriptionId,
    required this.eleveNom,
    required this.elevePrenom,
    required this.classe,
    required this.anneeScolaire,
    required this.trimestre,
    required this.moyenneGenerale,
    required this.mention,
    this.rang,
    this.totalEleves,
    required this.appreciation,
    required this.notes,
    required this.createdAt,
    this.matieresData,
  });

  factory BulletinAdminModel.fromJson(Map<String, dynamic> json) {
    return BulletinAdminModel(
      id: json['id'] ?? 0,
      inscriptionId: json['inscription_id'] ?? 0,
      eleveNom: json['eleve_nom']?.toString() ?? '',
      elevePrenom: json['eleve_prenom']?.toString() ?? '',
      classe: json['classe']?.toString() ?? '',
      // ⚠️ Même correctif que côté parent : on lit la vraie année scolaire
      // envoyée par le serveur au lieu de la recalculer depuis la date du jour.
      anneeScolaire: json['annee_scolaire']?.toString() ?? '',
      trimestre: json['trimestre']?.toString() ?? '1',
      moyenneGenerale: (json['moyenne_generale'] ?? 0).toDouble(),
      mention: json['mention']?.toString() ?? '',
      rang: json['rang'] ?? json['rang_general'], 
      totalEleves: json['total_eleves'],
      appreciation: json['appreciation']?.toString() ?? '',
      notes: json['notes'] ?? [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      matieresData: json['matieres'],
    );
  }

  String get fullName => '$elevePrenom $eleveNom';
}

class MatiereBulletinAdmin {
  final int id;
  final String nom;
  final int? coefficient;
  final double moyenne;
  final int rang;
  final int totalEleves;
  final List<NoteDetailAdmin> interrogations;
  final List<NoteDetailAdmin> devoirs;

  MatiereBulletinAdmin({
    required this.id,
    required this.nom,
    this.coefficient,
    required this.moyenne,
    required this.rang,
    required this.totalEleves,
    required this.interrogations,
    required this.devoirs,
  });

  factory MatiereBulletinAdmin.fromJson(Map<String, dynamic> json) {
    final List<NoteDetailAdmin> interros = [];
    final List<NoteDetailAdmin> devoirsList = [];
    
    if (json['interrogations'] != null && json['interrogations'] is List) {
      for (var interro in json['interrogations']) {
        interros.add(NoteDetailAdmin.fromJson(interro));
      }
    }
    
    if (json['devoirs'] != null && json['devoirs'] is List) {
      for (var devoir in json['devoirs']) {
        devoirsList.add(NoteDetailAdmin.fromJson(devoir));
      }
    }
    
    // ✅ Le backend (AdminBulletinController::generateBulletin) enregistre
    // chaque matière sous les clés 'matiere_id' / 'matiere_nom' / 'moyenne_eleve'
    // (pas 'id' / 'nom' / 'moyenne') — avec les anciennes clés, ce modèle
    // lisait toujours des valeurs par défaut (0, chaîne vide), donc le
    // tableau affichait des matières sans nom et une moyenne à 0.0 même
    // quand les données étaient correctement calculées côté serveur.
    // NB : le backend ne calcule pas de rang/total d'élèves PAR matière
    // (seulement au niveau du bulletin entier) — ces deux champs restent
    // donc à 0 tant qu'aucun calcul par matière n'est ajouté côté serveur.
    return MatiereBulletinAdmin(
      id: json['matiere_id'] ?? json['id'] ?? 0,
      nom: json['matiere_nom'] ?? json['nom'] ?? '',
      coefficient: json['coefficient'],
      moyenne: double.tryParse(
              (json['moyenne_eleve'] ?? json['moyenne'])?.toString() ?? '') ??
          0.0,
      rang: json['rang'] ?? 0,
      totalEleves: json['total_eleves'] ?? 0,
      interrogations: interros,
      devoirs: devoirsList,
    );
  }
}

class NoteDetailAdmin {
  final int numero;
  final double note;
  final String appreciation;

  NoteDetailAdmin({
    required this.numero,
    required this.note,
    required this.appreciation,
  });

  factory NoteDetailAdmin.fromJson(Map<String, dynamic> json) {
    return NoteDetailAdmin(
      numero: json['numero'] ?? 0,
      // ✅ Le backend caste la colonne `note` en 'decimal:2' côté Laravel,
      // ce qui la sérialise TOUJOURS en chaîne (ex: "10.00"), jamais en
      // nombre JSON. `.toDouble()` n'existe pas sur String, d'où le crash
      // "NoSuchMethodError: 'toDouble'". On parse donc explicitement,
      // en acceptant aussi bien une chaîne qu'un nombre déjà décodé.
      note: double.tryParse(json['note']?.toString() ?? '') ?? 0.0,
      appreciation: json['appreciation'] ?? '',
    );
  }
}