<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Note;
use App\Models\Classe;
use App\Models\Matiere;
use App\Models\Eleve;
use App\Models\EmploiDuTemps;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class NoteAdminController extends Controller
{
    // Récupérer toutes les notes avec filtres
    public function index(Request $request)
    {
        $query = Note::with(['eleve.classe', 'matiere']);
        
        // Filtre par classe
        if ($request->has('classe_id') && $request->classe_id) {
            $query->whereHas('eleve', function($q) use ($request) {
                $q->where('classe_id', $request->classe_id);
            });
        }
        
        // Filtre par matière
        if ($request->has('matiere_id') && $request->matiere_id) {
            $query->where('matiere_id', $request->matiere_id);
        }
        
        // Filtre par trimestre
        if ($request->has('trimestre') && $request->trimestre) {
            $query->where('trimestre', $request->trimestre);
        }
        
        $notes = $query->orderBy('created_at', 'desc')->get();
        
        // Grouper les notes par élève, matière et trimestre
        $groupedNotes = [];
        foreach ($notes as $note) {
            $key = $note->eleve_id . '_' . $note->matiere_id . '_' . $note->trimestre;
            
            if (!isset($groupedNotes[$key])) {
                $groupedNotes[$key] = [
                    'eleve_id' => $note->eleve_id,
                    'eleve_nom' => $note->eleve ? $note->eleve->prenom . ' ' . $note->eleve->nom : 'Inconnu',
                    'classe_id' => $note->eleve ? $note->eleve->classe_id : null,
                    'classe_nom' => $note->eleve && $note->eleve->classe ? $note->eleve->classe->nom : 'Inconnu',
                    'matiere_id' => $note->matiere_id,
                    'matiere_nom' => $note->matiere ? $note->matiere->nom : 'Inconnu',
                    'professeur_nom' => $this->getProfesseurNom($note->eleve->classe_id ?? null, $note->matiere_id),
                    'trimestre' => $note->trimestre,
                    'interrogations' => [],
                    'devoirs' => [],
                    'moyenne' => 0,
                ];
            }
            
            // ✅ Ajouter la note avec son ID pour la modification/suppression
            $noteData = [
                'id' => $note->id,
                'note' => (float)$note->note,
                'created_at' => $note->created_at,
            ];
            
            if ($note->type_note == 'interrogation') {
                $groupedNotes[$key]['interrogations'][] = $noteData;
            } else {
                $groupedNotes[$key]['devoirs'][] = $noteData;
            }
            
            // Trier les interrogations par date (plus récent en premier)
            usort($groupedNotes[$key]['interrogations'], function($a, $b) {
                return strtotime($b['created_at']) - strtotime($a['created_at']);
            });
            
            // Trier les devoirs par date (plus récent en premier)
            usort($groupedNotes[$key]['devoirs'], function($a, $b) {
                return strtotime($b['created_at']) - strtotime($a['created_at']);
            });
            
            // Calculer la moyenne (uniquement des notes validées ou toutes ?)
            $total = 0;
            $count = 0;
            foreach ($groupedNotes[$key]['interrogations'] as $n) {
                $total += $n['note'];
                $count++;
            }
            foreach ($groupedNotes[$key]['devoirs'] as $n) {
                $total += $n['note'];
                $count++;
            }
            $groupedNotes[$key]['moyenne'] = $count > 0 ? round($total / $count, 2) : 0;
        }
        
        return response()->json([
            'success' => true,
            'data' => array_values($groupedNotes)
        ]);
    }
    
    private function getProfesseurNom($classeId, $matiereId)
    {
        if (!$classeId || !$matiereId) return 'Non assigné';
        
        $emploi = EmploiDuTemps::where('classe_id', $classeId)
            ->where('matiere_id', $matiereId)
            ->with('professeur')
            ->first();
        
        if ($emploi && $emploi->professeur) {
            return $emploi->professeur->prenom . ' ' . $emploi->professeur->nom;
        }
        
        return 'Non assigné';
    }
    
    // Récupérer les classes pour le filtre
    public function getClasses()
    {
        $classes = Classe::all();
        return response()->json([
            'success' => true,
            'data' => $classes
        ]);
    }
    
    // Récupérer les matières pour le filtre
    public function getMatieres()
    {
        $matieres = Matiere::all();
        return response()->json([
            'success' => true,
            'data' => $matieres
        ]);
    }
    
    // Modifier une note
    public function update(Request $request, $id)
    {
        $note = Note::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'note' => 'required|numeric|min:0|max:20',
            'type_note' => 'required|in:interrogation,devoir',
            'trimestre' => 'required|in:1,2,3',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }
        
        $note->update([
            'note' => $request->note,
            'type_note' => $request->type_note,
            'trimestre' => $request->trimestre,
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Note modifiée avec succès'
        ]);
    }
    
    // Supprimer une note
    public function destroy($id)
    {
        $note = Note::findOrFail($id);
        $note->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Note supprimée avec succès'
        ]);
    }
    
    // Ajouter une note
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'eleve_id' => 'required|exists:eleves,id',
            'matiere_id' => 'required|exists:matieres,id',
            'note' => 'required|numeric|min:0|max:20',
            'type_note' => 'required|in:interrogation,devoir',
            'trimestre' => 'required|in:1,2,3',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }
        
        $note = Note::create([
            'eleve_id' => $request->eleve_id,
            'matiere_id' => $request->matiere_id,
            'note' => $request->note,
            'type_note' => $request->type_note,
            'trimestre' => $request->trimestre,
            'is_validated' => false,
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Note ajoutée avec succès',
            'data' => $note
        ]);
    }
}