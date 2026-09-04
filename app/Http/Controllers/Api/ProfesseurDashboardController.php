<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classe;
use App\Models\Eleve;
use App\Models\EmploiDuTemps;
use App\Models\Presence;
use App\Models\CahierDeTest;
use App\Models\SalairePaiement;
use App\Models\Note;
use App\Models\Professeur;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class ProfesseurDashboardController extends Controller
{
    // 1. Récupérer les classes du professeur connecté
    public function getClasses(Request $request)
    {
        // Récupérer l'ID depuis les paramètres de la requête
        $professeurId = $request->input('professeur_id');

        if (!$professeurId) {
            return response()->json([
                'success' => false,
                'message' => 'ID professeur manquant'
            ], 400);
        }

        // Récupérer les IDs des classes via classe_annee_matieres -> classe_annees
        // (l'association professeur ↔ classe ne passe plus par classe_professeur)
        $classeIds = DB::table('classe_annee_matieres')
            ->join('classe_annees', 'classe_annee_matieres.classe_annee_id', '=', 'classe_annees.id')
            ->where('classe_annee_matieres.professeur_id', $professeurId)
            ->pluck('classe_annees.classe_id')
            ->unique();

        // Récupérer les noms des classes
        $classes = Classe::whereIn('id', $classeIds)->get();

        return response()->json([
            'success' => true,
            'data' => $classes->map(function($classe) {
                return [
                    'id' => $classe->id,
                    'nom' => $classe->nom,
                    'students_count' => $classe->eleves()->count(),
                ];
            })
        ]);
    }

    // 2. Récupérer les élèves d'une classe
    public function getElevesByClasse(Request $request, $classeId)
    {
        $professeurId = $request->input('professeur_id');

        if (!$professeurId) {
            return response()->json([
                'success' => false,
                'message' => 'ID professeur manquant'
            ], 400);
        }

        // Vérifier que le professeur est bien associé à cette classe
        // (via classe_annee_matieres -> classe_annees)
        $isAssocie = DB::table('classe_annee_matieres')
            ->join('classe_annees', 'classe_annee_matieres.classe_annee_id', '=', 'classe_annees.id')
            ->where('classe_annee_matieres.professeur_id', $professeurId)
            ->where('classe_annees.classe_id', $classeId)
            ->exists();

        if (!$isAssocie) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n\'êtes pas autorisé à voir cette classe'
            ], 403);
        }

        $eleves = Eleve::where('classe_id', $classeId)
            ->orderBy('nom')
            ->orderBy('prenom')
            ->get();

        // Récupérer les informations de la classe
        $classe = Classe::find($classeId);

        return response()->json([
            'success' => true,
            'data' => [
                'classe' => [
                    'id' => $classe->id,
                    'nom' => $classe->nom,
                    'students_count' => $eleves->count(),
                ],
                'eleves' => $eleves->map(function($eleve,$index) {
                    return [
                        'id' => $eleve->id,
                        'numero' => $index + 1,
                        'nom' => $eleve->nom,
                        'prenom' => $eleve->prenom,
                        'full_name' => $eleve->prenom . ' ' . $eleve->nom,
                ];
            })
            ]
        ]);
    }

    // 3. Enregistrer les notes (une liste de notes pour plusieurs élèves)

public function saveNotes(Request $request)
{
    $validator = Validator::make($request->all(), [
        'classe_id' => 'required|exists:classes,id',
        'type_note' => 'required|in:interrogation,devoir',
        'trimestre' => 'required|in:1,2,3',
        'notes' => 'required|array',
        'notes.*.eleve_id' => 'required|exists:eleves,id',
        'notes.*.note' => 'required|numeric|min:0|max:20',
        'code_secret' => 'required|string|min:4',
        'professeur_id' => 'required|exists:professeurs,id',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur de validation',
            'errors' => $validator->errors()
        ], 422);
    }

    $professeur = Professeur::find($request->professeur_id);

    if (!$professeur) {
        return response()->json([
            'success' => false,
            'message' => 'Professeur non trouvé'
        ], 404);
    }

    // ✅ Récupérer la matière_id du professeur depuis la table professeurs
    $matiereId = $professeur->matiere_id;

    if (!$matiereId) {
        return response()->json([
            'success' => false,
            'message' => 'Aucune matière associée à ce professeur'
        ], 400);
    }

    // Vérification du code secret
    if ($professeur->code != $request->code_secret) {
        return response()->json([
            'success' => false,
            'message' => 'Code secret incorrect'
        ], 401);
    }

    // Vérifier que le professeur est bien associé à cette classe
    // (via classe_annee_matieres -> classe_annees)
    $estAssocie = DB::table('classe_annee_matieres')
        ->join('classe_annees', 'classe_annee_matieres.classe_annee_id', '=', 'classe_annees.id')
        ->where('classe_annee_matieres.professeur_id', $professeur->id)
        ->where('classe_annees.classe_id', $request->classe_id)
        ->exists();

    if (!$estAssocie) {
        return response()->json([
            'success' => false,
            'message' => 'Vous n\'êtes pas autorisé à noter cette classe'
        ], 403);
    }

    DB::beginTransaction();

    try {
        foreach ($request->notes as $noteData) {
            // Vérifier que l'élève est dans la classe
            $eleveDansClasse = Eleve::where('id', $noteData['eleve_id'])
                ->where('classe_id', $request->classe_id)
                ->exists();

            if (!$eleveDansClasse) {
                continue;
            }

            // ✅ Créer la note avec la matière_id du professeur
            Note::create([
                'eleve_id' => $noteData['eleve_id'],
                'matiere_id' => $matiereId,  // ← Récupéré du professeur
                'note' => $noteData['note'],
                'type_note' => $request->type_note,
                'trimestre' => $request->trimestre,
                'professeur_id' => $professeur->id,
                'is_validated' => true,
                'validated_at' => now(),
            ]);
        }

        DB::commit();

        return response()->json([
            'success' => true,
            'message' => 'Notes enregistrées avec succès'
        ]);

    } catch (\Exception $e) {
        DB::rollBack();
        return response()->json([
            'success' => false,
            'message' => 'Erreur: ' . $e->getMessage()
        ], 500);
    }
}    // 4. Récupérer l'emploi du temps du professeur

public function deleteNote($id)
{
    \Log::info('=== DELETE NOTE PROFESSEUR ===');
    \Log::info('ID: ' . $id);

    $note = Note::find($id);

    if (!$note) {
        return response()->json([
            'success' => false,
            'message' => 'Note non trouvée'
        ], 404);
    }

    // Vérifier que le professeur a le droit de supprimer cette note
    $professeurId = auth()->id();
    if ($note->professeur_id != $professeurId) {
        return response()->json([
            'success' => false,
            'message' => 'Vous n\'êtes pas autorisé à supprimer cette note'
        ], 403);
    }

    $note->delete();

    return response()->json([
        'success' => true,
        'message' => 'Note supprimée avec succès'
    ]);
}

public function getEmploiDuTemps(Request $request)
{
    $professeurId = $request->input('professeur_id');

    if (!$professeurId) {
        return response()->json([
            'success' => false,
            'message' => 'ID professeur manquant'
        ], 400);
    }

    $emplois = EmploiDuTemps::where('professeur_id', $professeurId)
        ->with(['classe', 'matiere'])
        ->orderByRaw("FIELD(jour, 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi')")
        ->orderBy('heure_debut')
        ->get();

    $emploisParJour = [];
    foreach ($emplois as $emploi) {
        $jour = $emploi->jour;
        if (!isset($emploisParJour[$jour])) {
            $emploisParJour[$jour] = [];
        }
        $emploisParJour[$jour][] = [
            'id' => $emploi->id,
            'matiere' => $emploi->matiere->nom,      // Matière d'abord
            'classe' => $emploi->classe->nom,        // Classe ensuite
            'heure_debut' => date('H:i', strtotime($emploi->heure_debut)),  // Format 08:00
            'heure_fin' => date('H:i', strtotime($emploi->heure_fin)),      // Format 10:00
            'salle' => $emploi->salle ?? '',
        ];
    }

    return response()->json([
        'success' => true,
        'data' => $emploisParJour
    ]);
}

public function updateNote(Request $request, $noteId)
{
    $validator = Validator::make($request->all(), [
        'note' => 'required|numeric|min:0|max:20',
        'professeur_id' => 'required|exists:professeurs,id',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur de validation',
            'errors' => $validator->errors()
        ], 422);
    }

    $professeur = Professeur::find($request->professeur_id);

    if (!$professeur) {
        return response()->json([
            'success' => false,
            'message' => 'Professeur non trouvé'
        ], 404);
    }

    $note = Note::find($noteId);

    if (!$note) {
        return response()->json([
            'success' => false,
            'message' => 'Note non trouvée'
        ], 404);
    }

    // Vérifier que la note appartient à la matière du professeur
    if ($note->matiere_id != $professeur->matiere_id) {
        return response()->json([
            'success' => false,
            'message' => 'Vous n\'êtes pas autorisé à modifier cette note'
        ], 403);
    }

    // ✅ MODIFIER la note existante
    $note->note = $request->note;
    $note->save();

    return response()->json([
        'success' => true,
        'message' => 'Note modifiée avec succès',
        'data' => $note
    ]);
}
public function getEleveNotes(Request $request, $eleveId)
{
    $professeurId = $request->input('professeur_id');

    if (!$professeurId) {
        return response()->json([
            'success' => false,
            'message' => 'ID professeur manquant'
        ], 400);
    }

    $professeur = Professeur::find($professeurId);

        if (!$professeur) {
            return response()->json([
                'success' => false,
                'message' => 'Professeur non trouvé'
            ], 404);
        }

    $notes = Note::where('eleve_id', $eleveId)
        ->where('matiere_id', $professeur->matiere_id)
        ->orderBy('trimestre')
        ->orderBy('type_note')
        ->orderBy('created_at', 'desc')
        ->get();

    return response()->json([
        'success' => true,
        'data' => $notes->map(function($note) {
            return [
                'id' => $note->id,
                'note' => $note->note,
                'type_note' => $note->type_note,
                'trimestre' => $note->trimestre,
                'is_validated' => $note->is_validated,
                'date' => $note->created_at->format('d/m/Y'),
            ];
        })
    ]);
}
}
