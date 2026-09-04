<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Eleve;
use App\Models\Matiere;
use App\Models\Note;
use App\Models\Bulletin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminNoteController extends Controller
{
    public function getNotesByEleveAndTrimestre($eleveId, Request $request)
    {
        try {
            $trimestre = $request->query('trimestre', '1');
            
            Log::info('=== getNotesByEleveAndTrimestre ===');
            Log::info('Eleve ID: ' . $eleveId);
            Log::info('Trimestre: ' . $trimestre);
            
            $eleve = Eleve::findOrFail($eleveId);
            
            // Récupérer le bulletin pour obtenir le rang général
            $bulletin = Bulletin::where('eleve_id', $eleveId)
                ->where('trimestre', $trimestre)
                ->first();
            
            Log::info('Bulletin trouvé: ' . ($bulletin ? 'Oui' : 'Non'));
            
            // Récupérer les matières de la classe de l'élève
            $matieres = Matiere::whereHas('classes', function($query) use ($eleve) {
                $query->where('classes.id', $eleve->classe_id);
            })->get();
            
            Log::info('Nombre de matières: ' . $matieres->count());
            
            $matieresData = [];
            
            foreach ($matieres as $matiere) {
                // Récupérer les interrogations
                $interrogations = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('trimestre', $trimestre)
                    ->where('type_note', 'interrogation')
                    ->orderBy('created_at', 'asc')
                    ->get();
                
                // Récupérer les devoirs
                $devoirs = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('trimestre', $trimestre)
                    ->where('type_note', 'devoir')
                    ->orderBy('created_at', 'asc')
                    ->get();
                
                // Toutes les notes pour calculer la moyenne
                $toutesNotes = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('trimestre', $trimestre)
                    ->get();
                
                // Calculer le rang pour cette matière
                $elevesClasse = Eleve::where('classe_id', $eleve->classe_id)->pluck('id');
                
                $moyennesEleves = [];
                foreach ($elevesClasse as $id) {
                    $moyenne = Note::where('eleve_id', $id)
                        ->where('matiere_id', $matiere->id)
                        ->where('trimestre', $trimestre)
                        ->avg('note');
                    if ($moyenne !== null) {
                        $moyennesEleves[$id] = round(floatval($moyenne), 2);
                    }
                }
                
                arsort($moyennesEleves);
                
                $rangMatiere = 1;
                foreach ($moyennesEleves as $id => $moy) {
                    if ($id == $eleveId) {
                        break;
                    }
                    $rangMatiere++;
                }
                
                $totalElevesMatiere = count($moyennesEleves);
                
                $interrogationsList = [];
                $numInterro = 1;
                foreach ($interrogations as $note) {
                    $interrogationsList[] = [
                        'numero' => $numInterro++,
                        'note' => floatval($note->note),
                        'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                        'date' => $note->created_at ? $note->created_at->format('d/m/Y') : null,
                    ];
                }
                
                $devoirsList = [];
                $numDevoir = 1;
                foreach ($devoirs as $note) {
                    $devoirsList[] = [
                        'numero' => $numDevoir++,
                        'note' => floatval($note->note),
                        'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                        'date' => $note->created_at ? $note->created_at->format('d/m/Y') : null,
                    ];
                }
                
                // Calculer la moyenne de l'élève pour cette matière
                $moyenneEleve = $toutesNotes->isEmpty() ? 0 : round(floatval($toutesNotes->avg('note')), 2);
                
                $matieresData[] = [
                    'id' => $matiere->id,
                    'nom' => $matiere->nom,
                    'coefficient' => $matiere->coefficient,
                    'moyenne' => $moyenneEleve,
                    'rang' => $rangMatiere,
                    'total_eleves' => $totalElevesMatiere,
                    'interrogations' => $interrogationsList,
                    'devoirs' => $devoirsList,
                ];
            }
            
            // Récupérer le rang général et le total d'élèves
            $rangGeneral = 0;
            $totalEleves = 0;
            
            if ($bulletin) {
                $rangGeneral = $bulletin->rang;
                $totalEleves = $bulletin->total_eleves;
                Log::info('Rang général depuis bulletin: ' . $rangGeneral);
                Log::info('Total élèves depuis bulletin: ' . $totalEleves);
            } else {
                // Calculer le rang général à partir des notes si pas de bulletin
                $elevesClasse = Eleve::where('classe_id', $eleve->classe_id)->pluck('id');
                $moyennesGenerales = [];
                
                foreach ($elevesClasse as $id) {
                    $moyenne = Note::where('eleve_id', $id)
                        ->where('trimestre', $trimestre)
                        ->avg('note');
                    if ($moyenne !== null) {
                        $moyennesGenerales[$id] = round(floatval($moyenne), 2);
                    }
                }
                
                arsort($moyennesGenerales);
                
                $rangGeneral = 1;
                foreach ($moyennesGenerales as $id => $moy) {
                    if ($id == $eleveId) {
                        break;
                    }
                    $rangGeneral++;
                }
                $totalEleves = count($moyennesGenerales);
                
                Log::info('Rang général calculé: ' . $rangGeneral);
                Log::info('Total élèves calculé: ' . $totalEleves);
            }
            
            return response()->json([
                'success' => true,
                'matieres' => $matieresData,
                'rang_general' => $rangGeneral,
                'total_eleves' => $totalEleves,
            ]);
            
        } catch (\Exception $e) {
            Log::error('Erreur getNotesByEleveAndTrimestre: ' . $e->getMessage());
            Log::error($e->getTraceAsString());
            
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'matieres' => []
            ], 500);
        }
    }
}