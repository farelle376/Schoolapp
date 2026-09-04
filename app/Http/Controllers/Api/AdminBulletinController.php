<?php
// app/Http/Controllers/Api/AdminBulletinController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bulletin;
use App\Models\Classe;
use App\Models\Eleve;
use App\Models\Note;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class AdminBulletinController extends Controller
{
    /**
     * Récupérer toutes les classes
     */
    public function getClasses()
    {
        try {
            $classes = Classe::all();
            return response()->json([
                'success' => true,
                'data' => $classes
            ]);
        } catch (\Exception $e) {
            Log::error('getClasses: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Récupérer les élèves d'une classe
     */
    public function getElevesByClasse($classeId)
    {
        try {
            $eleves = Eleve::where('classe_id', $classeId)
                ->select('id', 'nom', 'prenom')
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => $eleves
            ]);
        } catch (\Exception $e) {
            Log::error('getElevesByClasse: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Récupérer les bulletins d'une classe pour un trimestre
     */
    public function getBulletinsByClasse($classeId, $trimestre)
    {
        try {
            $bulletins = Bulletin::where('classe_id', $classeId)
                ->where('trimestre', $trimestre)
                ->with('eleve')
                ->get();

            $data = $bulletins->map(function ($bulletin) {
                return [
                    'id' => $bulletin->id,
                    'eleve_id' => $bulletin->eleve_id,
                    'eleve_nom' => $bulletin->eleve->nom,
                    'eleve_prenom' => $bulletin->eleve->prenom,
                    'classe' => $bulletin->eleve->classe->nom ?? '',
                    'trimestre' => $bulletin->trimestre,
                    'moyenne_generale' => (float) $bulletin->moyenne_generale,
                    'mention' => $bulletin->mention,
                    'appreciation' => $bulletin->appreciation,
                    'created_at' => $bulletin->created_at->toISOString(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $data
            ]);
        } catch (\Exception $e) {
            Log::error('getBulletinsByClasse: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Vérifier si toutes les notes sont disponibles pour générer le bulletin
     */
    public function checkNotesDisponibles($eleveId, $trimestre)
    {
        try {
            $eleve = Eleve::with('classe.matieres')->findOrFail($eleveId);
            $matieres = $eleve->classe->matieres;
            
            $resultats = [];
            $toutesDisponibles = true;
            
            foreach ($matieres as $matiere) {
                $nbInterrogations = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'interrogation')
                    ->where('trimestre', $trimestre)
                    ->count();
                
                $nbDevoirs = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'devoir')
                    ->where('trimestre', $trimestre)
                    ->count();
                
                $estDisponible = ($nbInterrogations >= 3 && $nbDevoirs >= 2);
                
                $resultats[] = [
                    'matiere_id' => $matiere->id,
                    'matiere_nom' => $matiere->nom,
                    'nb_interrogations' => $nbInterrogations,
                    'nb_devoirs' => $nbDevoirs,
                    'interrogations_requises' => 3,
                    'devoirs_requis' => 2,
                    'est_disponible' => $estDisponible
                ];
                
                if (!$estDisponible) {
                    $toutesDisponibles = false;
                }
            }
            
            return response()->json([
                'success' => true,
                'toutes_disponibles' => $toutesDisponibles,
                'details' => $resultats
            ]);
            
        } catch (\Exception $e) {
            Log::error('checkNotesDisponibles: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer la moyenne d'une matière pour un élève
     */
    private function calculateMatiereMoyenne($eleveId, $matiereId, $trimestre)
    {
        $interrogations = Note::where('eleve_id', $eleveId)
            ->where('matiere_id', $matiereId)
            ->where('type_note', 'interrogation')
            ->where('trimestre', $trimestre)
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();
        
        $devoirs = Note::where('eleve_id', $eleveId)
            ->where('matiere_id', $matiereId)
            ->where('type_note', 'devoir')
            ->where('trimestre', $trimestre)
            ->orderBy('created_at', 'desc')
            ->limit(2)
            ->get();
        
        $moyenneInterrogations = $interrogations->isNotEmpty() ? $interrogations->avg('note') : 0;
        $sommeDevoirs = $devoirs->sum('note');
        $moyenneFinale = ($moyenneInterrogations + $sommeDevoirs) / 3;
        
        return round($moyenneFinale, 2);
    }

    /**
     * Calculer la moyenne de la classe pour une matière
     */
    private function calculateClasseMoyenne($classeId, $matiereId, $trimestre)
    {
        $eleves = Eleve::where('classe_id', $classeId)->get();
        $totalMoyennes = 0;
        $count = 0;
        
        foreach ($eleves as $eleve) {
            $moyenne = $this->calculateMatiereMoyenne($eleve->id, $matiereId, $trimestre);
            if ($moyenne > 0) {
                $totalMoyennes += $moyenne;
                $count++;
            }
        }
        
        return $count > 0 ? round($totalMoyennes / $count, 2) : 0;
    }

    /**
     * Obtenir l'appréciation en fonction de la note
     */
    private function getAppreciation($note)
    {
        if ($note >= 16) return 'Excellent';
        if ($note >= 14) return 'Très bien';
        if ($note >= 12) return 'Bien';
        if ($note >= 10) return 'Assez bien';
        return 'Insuffisant';
    }

    /**
     * Obtenir la mention en fonction de la moyenne générale
     */
    private function getMention($moyenne)
    {
        if ($moyenne >= 16) return 'Très Bien';
        if ($moyenne >= 14) return 'Bien';
        if ($moyenne >= 12) return 'Assez Bien';
        if ($moyenne >= 10) return 'Passable';
        return 'Insuffisant';
    }

    /**
     * Obtenir l'appréciation générale
     */
    private function getAppreciationGenerale($moyenne)
    {
        if ($moyenne >= 16) {
            return 'Félicitations pour vos excellents résultats. Continuez ainsi !';
        } elseif ($moyenne >= 14) {
            return 'Très bons résultats. Vous êtes sur la bonne voie.';
        } elseif ($moyenne >= 12) {
            return 'Bons résultats. Quelques efforts supplémentaires vous permettront de progresser.';
        } elseif ($moyenne >= 10) {
            return 'Résultats passables. Un peu plus de travail est nécessaire.';
        } else {
            return 'Des efforts significatifs sont nécessaires pour améliorer vos résultats.';
        }
    }

    /**
     * Générer le bulletin (calcul + sauvegarde)
     */
    public function generateBulletin(Request $request)
    {
        try {
            $request->validate([
                'eleve_id' => 'required|exists:eleves,id',
                'trimestre' => 'required|in:1,2,3',
            ]);
            
            $eleveId = $request->eleve_id;
            $trimestre = $request->trimestre;
            
            $eleve = Eleve::with('classe.matieres')->findOrFail($eleveId);
            $classe = $eleve->classe;
            
            if (!$classe) {
                return response()->json([
                    'success' => false,
                    'message' => 'Élève non assigné à une classe'
                ], 400);
            }
            
            $matieres = $classe->matieres;
            $notesData = [];
            $totalNotes = 0;
            $totalCoefficients = 0;
            $toutesDisponibles = true;
            
            foreach ($matieres as $matiere) {
                $nbInterrogations = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'interrogation')
                    ->where('trimestre', $trimestre)
                    ->count();
                
                $nbDevoirs = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'devoir')
                    ->where('trimestre', $trimestre)
                    ->count();
                
                if ($nbInterrogations < 3 || $nbDevoirs < 2) {
                    $toutesDisponibles = false;
                    break;
                }
                
                $interrogations = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'interrogation')
                    ->where('trimestre', $trimestre)
                    ->orderBy('created_at', 'desc')
                    ->limit(3)
                    ->get();
                
                $devoirs = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('type_note', 'devoir')
                    ->where('trimestre', $trimestre)
                    ->orderBy('created_at', 'desc')
                    ->limit(2)
                    ->get();
                
                $moyenneInterrogations = $interrogations->avg('note');
                $sommeDevoirs = $devoirs->sum('note');
                $moyenneEleve = ($moyenneInterrogations + $sommeDevoirs) / 3;
                $moyenneClasse = $this->calculateClasseMoyenne($classe->id, $matiere->id, $trimestre);
                $coefficient = $matiere->pivot->coefficient ?? 1;
                
                $notesData[] = [
                    'matiere_id' => $matiere->id,
                    'matiere_nom' => $matiere->nom,
                    'interrogations' => $interrogations->map(function($n) {
                        return ['id' => $n->id, 'note' => $n->note, 'date' => $n->created_at->format('d/m/Y')];
                    }),
                    'devoirs' => $devoirs->map(function($n) {
                        return ['id' => $n->id, 'note' => $n->note, 'date' => $n->created_at->format('d/m/Y')];
                    }),
                    'moyenne_interrogations' => round($moyenneInterrogations, 2),
                    'somme_devoirs' => round($sommeDevoirs, 2),
                    'moyenne_eleve' => round($moyenneEleve, 2),
                    'moyenne_classe' => $moyenneClasse,
                    'coefficient' => $coefficient,
                    'appreciation' => $this->getAppreciation($moyenneEleve)
                ];
                
                $totalNotes += $moyenneEleve * $coefficient;
                $totalCoefficients += $coefficient;
            }
            
            if (!$toutesDisponibles) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de générer le bulletin. Toutes les notes ne sont pas encore disponibles (3 interrogations et 2 devoirs par matière requis).',
                    'code' => 'NOTES_INCOMPLETES'
                ], 400);
            }
            
            $moyenneGenerale = $totalCoefficients > 0 ? round($totalNotes / $totalCoefficients, 2) : 0;
            $mention = $this->getMention($moyenneGenerale);
            $appreciationGenerale = $this->getAppreciationGenerale($moyenneGenerale);
            
            // Calculer le rang
            $tousEleves = Eleve::where('classe_id', $classe->id)->get();
            $moyennesEleves = [];
            
            foreach ($tousEleves as $e) {
                $total = 0;
                $coeff = 0;
                foreach ($classe->matieres as $m) {
                    $moy = $this->calculateMatiereMoyenne($e->id, $m->id, $trimestre);
                    $coef = $m->pivot->coefficient ?? 1;
                    $total += $moy * $coef;
                    $coeff += $coef;
                }
                $moyGen = $coeff > 0 ? round($total / $coeff, 2) : 0;
                if ($moyGen > 0) {
                    $moyennesEleves[$e->id] = $moyGen;
                }
            }
            
            arsort($moyennesEleves);
            $rang = 1;
            $rangEleve = null;
            foreach ($moyennesEleves as $id => $moy) {
                if ($id == $eleveId) {
                    $rangEleve = $rang;
                    break;
                }
                $rang++;
            }
            
            // Sauvegarder ou mettre à jour le bulletin
            $bulletin = Bulletin::updateOrCreate(
                [
                    'eleve_id' => $eleveId,
                    'trimestre' => $trimestre,
                ],
                [
                    'classe_id' => $classe->id,
                    'moyenne_generale' => $moyenneGenerale,
                    'mention' => $mention,
                    'appreciation' => $appreciationGenerale,
                    'rang' => $rangEleve,
                    'total_eleves' => count($moyennesEleves),
                    'notes_data' => json_encode($notesData),
                    'generated_at' => now(),
                ]
            );
            
            return response()->json([
                'success' => true,
                'message' => 'Bulletin généré avec succès',
                'data' => [
                    'bulletin_id' => $bulletin->id,
                    'eleve_id' => $eleveId,
                    'eleve_nom' => $eleve->nom,
                    'eleve_prenom' => $eleve->prenom,
                    'classe' => $classe->nom,
                    'trimestre' => $trimestre,
                    'moyenne_generale' => $moyenneGenerale,
                    'mention' => $mention,
                    'appreciation' => $appreciationGenerale,
                    'rang' => $rangEleve,
                    'total_eleves' => count($moyennesEleves),
                    'matieres' => $notesData
                ]
            ]);
            
        } catch (\Exception $e) {
            Log::error('generateBulletin: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Récupérer un bulletin existant
     */
    public function getBulletin($id)
    {
        try {
            $bulletin = Bulletin::with('eleve.classe')->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $bulletin->id,
                    'eleve_id' => $bulletin->eleve_id,
                    'eleve_nom' => $bulletin->eleve->nom,
                    'eleve_prenom' => $bulletin->eleve->prenom,
                    'classe' => $bulletin->eleve->classe->nom,
                    'trimestre' => $bulletin->trimestre,
                    'moyenne_generale' => (float) $bulletin->moyenne_generale,
                    'mention' => $bulletin->mention,
                    'appreciation' => $bulletin->appreciation,
                    'rang' => $bulletin->rang,
                    'total_eleves' => $bulletin->total_eleves,
                    'matieres' => json_decode($bulletin->notes_data, true),
                    'created_at' => $bulletin->created_at->toISOString()
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('getBulletin: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
  
    
    /**
     * Mettre à jour un bulletin
     */
    public function updateBulletin(Request $request, $id)
    {
        try {
            $bulletin = Bulletin::findOrFail($id);
            
            $bulletin->update($request->only(['appreciation', 'mention']));
            
            return response()->json([
                'success' => true,
                'message' => 'Bulletin mis à jour'
            ]);
        } catch (\Exception $e) {
            Log::error('updateBulletin: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Supprimer un bulletin
     */
    public function deleteBulletin($id)
    {
        try {
            $bulletin = Bulletin::findOrFail($id);
            $bulletin->delete();
            
            return response()->json([
                'success' => true,
                'message' => 'Bulletin supprimé'
            ]);
        } catch (\Exception $e) {
            Log::error('deleteBulletin: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}