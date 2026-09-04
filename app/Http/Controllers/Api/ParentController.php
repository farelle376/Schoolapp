<?php
// app/Http/Controllers/Api/ParentController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Famille;
use App\Models\Eleve;
use App\Models\Note;
use App\Models\Paiement;
use App\Models\EmploiDuTemps;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\NotificationParent;
use App\Models\Message;      
use App\Models\Conversation;
use App\Models\Bulletin;

class ParentController extends Controller
{
    /**
     * Récupérer la liste des enfants
     */
    public function getChildren(Request $request)
    {
        try {
            $parent = $request->user();
            
            Log::info('📚 [getChildren] Parent', [
                'id' => $parent?->id,
                'email' => $parent?->email
            ]);
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $children = $parent->eleves()->with('classe')->get();
            
            Log::info('📊 Enfants trouvés', ['count' => $children->count()]);
            
            $data = $children->map(function($child) {
                return [
                    'id' => $child->id,
                    'nom' => $child->nom,
                    'prenom' => $child->prenom,
                    'nom_complet' => $child->prenom . ' ' . $child->nom,
                    'classe' => $child->classe ? $child->classe->nom : null,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data
            ]);
            
        } catch (\Exception $e) {
            Log::error('❌ getChildren: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Nombre de notifications non lues
     */
    public function getUnreadCount(Request $request)
    {
        try {
            $parent = $request->user();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $count = NotificationParent::where('parent_id', $parent->id)
                ->where('est_lu', false)
                ->count();
            
            return response()->json([
                'success' => true,
                'count' => $count
            ]);
            
        } catch (\Exception $e) {
            Log::error('getUnreadCount: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'count' => 0
            ], 500);
        }
    }
    public function getChildBulletins($childId)
{
    try {
        // Vérifier que l'enfant appartient bien au parent
        $parent = auth()->user();
        $enfant = Eleve::where('id', $childId)
            ->where('parent_id', $parent->id)
            ->first();
        
        if (!$enfant) {
            return response()->json([
                'success' => false,
                'message' => 'Enfant non trouvé'
            ], 404);
        }
        
        // Récupérer les bulletins de l'élève
        $bulletins = Bulletin::where('eleve_id', $childId)
            ->orderBy('trimestre', 'asc')
            ->get();
        
        $result = [];
        foreach ($bulletins as $bulletin) {
            // Récupérer les détails des matières pour ce bulletin
            $matieresData = [];
            
            // Récupérer les notes de l'élève pour ce trimestre
            $notes = Note::where('eleve_id', $childId)
                ->where('trimestre', $bulletin->trimestre)
                ->with('matiere')
                ->get();
            
            // Grouper les notes par matière
            $notesParMatiere = $notes->groupBy('matiere_id');
            
            foreach ($notesParMatiere as $matiereId => $notesGroupees) {
                $matiere = $notesGroupees->first()->matiere;
                
                // Calculer la moyenne de l'élève pour cette matière
                $moyenneEleve = $notesGroupees->avg('note');
                
                // Calculer la moyenne de la classe pour cette matière
                $moyenneClasse = Note::where('trimestre', $bulletin->trimestre)
                    ->whereHas('eleve', function($query) use ($enfant) {
                        $query->where('classe_id', $enfant->classe_id);
                    })
                    ->where('matiere_id', $matiereId)
                    ->avg('note');
                
                // Calculer le rang de l'élève pour cette matière
                $elevesNotes = Note::where('trimestre', $bulletin->trimestre)
                    ->whereHas('eleve', function($query) use ($enfant) {
                        $query->where('classe_id', $enfant->classe_id);
                    })
                    ->where('matiere_id', $matiereId)
                    ->select('eleve_id', \DB::raw('AVG(note) as moyenne'))
                    ->groupBy('eleve_id')
                    ->orderBy('moyenne', 'desc')
                    ->get();
                
                $rang = 1;
                foreach ($elevesNotes as $index => $en) {
                    if ($en->eleve_id == $childId) {
                        $rang = $index + 1;
                        break;
                    }
                }
                
                // Séparer interrogations et devoirs
                $interrogations = [];
                $devoirs = [];
                $numInterro = 1;
                $numDevoir = 1;
                
                foreach ($notesGroupees as $note) {
                    if ($note->type == 'interrogation') {
                        $interrogations[] = [
                            'numero' => $numInterro++,
                            'note' => $note->note,
                            'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                        ];
                    } else {
                        $devoirs[] = [
                            'numero' => $numDevoir++,
                            'note' => $note->note,
                            'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                        ];
                    }
                }
                
                $matieresData[] = [
                    'id' => $matiere->id,
                    'nom' => $matiere->nom,
                    'coefficient' => $matiere->coefficient,
                    'moyenne' => round($moyenneEleve, 2),
                    'moyenne_classe' => round($moyenneClasse, 2),
                    'rang' => $rang,
                    'total_eleves' => $elevesNotes->count(),
                    'interrogations' => $interrogations,
                    'devoirs' => $devoirs,
                ];
            }
            
            // Calculer la moyenne générale
            $moyenneGenerale = 0;
            $totalCoefficients = 0;
            foreach ($matieresData as $matiere) {
                $moyenneGenerale += $matiere['moyenne'] * $matiere['coefficient'];
                $totalCoefficients += $matiere['coefficient'];
            }
            if ($totalCoefficients > 0) {
                $moyenneGenerale = round($moyenneGenerale / $totalCoefficients, 2);
            }
            
            // Calculer le rang général
            $tousEleves = Eleve::where('classe_id', $enfant->classe_id)->get();
            $rangsGeneraux = [];
            foreach ($tousEleves as $eleve) {
                $moy = $this->calculerMoyenneGenerale($eleve->id, $bulletin->trimestre);
                $rangsGeneraux[$eleve->id] = $moy;
            }
            arsort($rangsGeneraux);
            $rangGeneral = array_search($childId, array_keys($rangsGeneraux)) + 1;
            
            // Déterminer la mention
            $mention = $this->getMention($moyenneGenerale);
            
            $result[] = [
                'id' => $bulletin->id,
                'eleve_id' => $childId,
                'eleve_nom' => $enfant->nom,
                'eleve_prenom' => $enfant->prenom,
                'classe' => $enfant->classe->nom,
                'trimestre' => $bulletin->trimestre,
                'moyenne_generale' => $moyenneGenerale,
                'rang' => $rangGeneral,
                'total_eleves' => $tousEleves->count(),
                'mention' => $mention,
                'matieres' => $matieresData,
                'date_generation' => $bulletin->created_at->format('d/m/Y H:i'),
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => $result
        ]);
        
    } catch (\Exception $e) {
        \Log::error('Erreur getChildBulletins: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}

private function calculerMoyenneGenerale($eleveId, $trimestre)
{
    $notes = Note::where('eleve_id', $eleveId)
        ->where('trimestre', $trimestre)
        ->with('matiere')
        ->get();
    
    $notesParMatiere = $notes->groupBy('matiere_id');
    $moyenneGenerale = 0;
    $totalCoefficients = 0;
    
    foreach ($notesParMatiere as $matiereId => $notesGroupees) {
        $matiere = $notesGroupees->first()->matiere;
        $moyenneMatiere = $notesGroupees->avg('note');
        $moyenneGenerale += $moyenneMatiere * $matiere->coefficient;
        $totalCoefficients += $matiere->coefficient;
    }
    
    if ($totalCoefficients > 0) {
        return round($moyenneGenerale / $totalCoefficients, 2);
    }
    
    return 0;
}

private function getMention($moyenne)
{
    if ($moyenne >= 16) return 'Très Bien';
    if ($moyenne >= 14) return 'Bien';
    if ($moyenne >= 12) return 'Assez Bien';
    if ($moyenne >= 10) return 'Passable';
    return 'Insuffisant';
}

    /**
     * Récupérer les matières avec notes
     */
    public function getMatieresWithNotes($eleveId, Request $request)
    {
        return $this->getNotes($eleveId, $request);
    }
    
    /**
     * Récupérer les détails d'un enfant
     */
    public function getChildDetails($eleveId, Request $request)
    {
        try {
            $parent = $request->user();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $child = $parent->eleves()->with('classe')->where('eleves.id', $eleveId)->first();
            
            if (!$child) {
                return response()->json([
                    'success' => false,
                    'message' => 'Enfant non trouvé'
                ], 404);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $child->id,
                    'nom' => $child->nom,
                    'prenom' => $child->prenom,
                    'nom_complet' => $child->full_name,
                    'classe' => $child->classe ? [
                        'id' => $child->classe->id,
                        'nom' => $child->classe->nom,
                        'niveau' => $child->classe->niveau,
                        'nom_complet' => $child->classe->nom_complet,
                    ] : null,
                ],
            ]);
            
        } catch (\Exception $e) {
            Log::error('getChildDetails: ' . $e->getMessage());
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
        
        $moyenneInterrogations = 0;
        if ($interrogations->count() > 0) {
            $sommeInterrogations = $interrogations->sum('note');
            $moyenneInterrogations = $sommeInterrogations / $interrogations->count();
        }
        
        $sommeDevoirs = $devoirs->sum('note');
        $moyenneFinale = ($moyenneInterrogations + $sommeDevoirs) / 3;
        
        return round($moyenneFinale, 2);
    }
    
    /**
     * Récupérer les notes d'un enfant
     */
    public function getNotes($eleveId, Request $request)
    {
        try {
            $parent = $request->user();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $child = $parent->eleves()->where('eleves.id', $eleveId)->with('classe.matieres')->first();
            
            if (!$child) {
                return response()->json([
                    'success' => false,
                    'message' => 'Enfant non trouvé'
                ], 404);
            }
            
            $trimestre = $request->get('trimestre', '1');
            
            $tousEleves = Eleve::where('classe_id', $child->classe_id)->with('notes')->get();
            $matieres = $child->classe->matieres;
            $result = [];
            
            foreach ($matieres as $matiere) {
                $moyenneEleve = $this->calculateMatiereMoyenne($eleveId, $matiere->id, $trimestre);
                
                $moyennesParEleve = [];
                foreach ($tousEleves as $autreEleve) {
                    $moyenne = $this->calculateMatiereMoyenne($autreEleve->id, $matiere->id, $trimestre);
                    $moyennesParEleve[$autreEleve->id] = $moyenne;
                }
                
                arsort($moyennesParEleve);
                $rang = 1;
                $rangEleve = null;
                foreach ($moyennesParEleve as $id => $moy) {
                    if ($id == $eleveId) {
                        $rangEleve = $rang;
                        break;
                    }
                    $rang++;
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
                
                $moyenneInterrogations = 0;
                $sommeInterrogations = 0;
                $interrogationsListe = [];
                foreach ($interrogations as $interro) {
                    $sommeInterrogations += $interro->note;
                    $interrogationsListe[] = [
                        'id' => $interro->id,
                        'note' => (float) $interro->note,
                        'date' => $interro->created_at ? $interro->created_at->format('d/m/Y') : '',
                    ];
                }
                if ($interrogations->count() > 0) {
                    $moyenneInterrogations = $sommeInterrogations / $interrogations->count();
                }
                
                $sommeDevoirs = 0;
                $devoirsListe = [];
                foreach ($devoirs as $devoir) {
                    $sommeDevoirs += $devoir->note;
                    $devoirsListe[] = [
                        'id' => $devoir->id,
                        'note' => (float) $devoir->note,
                        'date' => $devoir->created_at ? $devoir->created_at->format('d/m/Y') : '',
                    ];
                }
                
                $moyenneFinale = ($moyenneInterrogations + $sommeDevoirs) / 3;
                $peutCalculer = ($interrogations->count() >= 1 || $devoirs->count() >= 1);
                $aMoyenne = ($interrogations->count() == 3 && $devoirs->count() == 2);
                
                $allNotes = Note::where('eleve_id', $eleveId)
                    ->where('matiere_id', $matiere->id)
                    ->where('trimestre', $trimestre)
                    ->orderBy('type_note')
                    ->orderBy('created_at', 'desc')
                    ->get();
                
                $result[] = [
                    'id' => $matiere->id,
                    'nom' => $matiere->nom,
                    'coefficient' => $matiere->pivot->coefficient,
                    'moyenne' => $aMoyenne ? round($moyenneFinale, 2) : null,
                    'rang' => $rangEleve,
                    'total_eleves' => count($tousEleves),
                    'peut_calculer' => $peutCalculer,
                    'a_moyenne' => $aMoyenne,
                    'details' => [
                        'interrogations' => [
                            'notes' => $interrogationsListe,
                            'nombre' => $interrogations->count(),
                            'somme' => round($sommeInterrogations, 2),
                            'moyenne' => $interrogations->count() > 0 ? round($moyenneInterrogations, 2) : null,
                        ],
                        'devoirs' => [
                            'notes' => $devoirsListe,
                            'nombre' => $devoirs->count(),
                            'somme' => round($sommeDevoirs, 2),
                        ],
                    ],
                    'notes' => $allNotes->map(function($note) {
                        return [
                            'id' => $note->id,
                            'note' => (float) $note->note,
                            'type_note' => $note->type_note,
                            'appreciation' => $this->getAppreciation($note->note),
                            'date' => $note->created_at ? $note->created_at->format('d/m/Y') : '',
                            'is_validated' => (bool) $note->is_validated,
                        ];
                    }),
                ];
            }
            
            usort($result, function($a, $b) {
                if ($a['moyenne'] === null && $b['moyenne'] === null) return 0;
                if ($a['moyenne'] === null) return 1;
                if ($b['moyenne'] === null) return -1;
                return $b['moyenne'] <=> $a['moyenne'];
            });
            
            return response()->json([
                'success' => true,
                'data' => $result,
                'trimestre' => $trimestre,
                'trimestres_disponibles' => ['1', '2', '3'],
            ]);
            
        } catch (\Exception $e) {
            Log::error('getNotes: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Récupérer l'emploi du temps d'un enfant
     */
    public function getSchedule($eleveId, Request $request)
    {
        try {
            $parent = $request->user();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $child = $parent->eleves()->where('eleves.id', $eleveId)->first();
            
            if (!$child) {
                return response()->json([
                    'success' => false,
                    'message' => 'Enfant non trouvé'
                ], 404);
            }
            
            if (!$child->classe_id) {
                return response()->json([
                    'success' => true,
                    'data' => []
                ]);
            }
            
            $emplois = EmploiDuTemps::where('classe_id', $child->classe_id)
                ->where('est_active', true)
                ->with(['matiere', 'professeur'])
                ->orderBy('jour')
                ->orderBy('heure_debut')
                ->get();
            
            $scheduleData = [];
            foreach ($emplois as $emploi) {
                $scheduleData[] = [
                    'id' => $emploi->id,
                    'matiere' => $emploi->matiere ? $emploi->matiere->nom : 'Inconnue',
                    'professeur' => $emploi->professeur ? $emploi->professeur->nom . ' ' . $emploi->professeur->prenom : 'Non assigné',
                    'heure_debut' => date('H:i', strtotime($emploi->heure_debut)),
                    'heure_fin' => date('H:i', strtotime($emploi->heure_fin)),
                    'jour' => $emploi->jour,
                    'type_cours' => $emploi->type_cours,
                ];
            }
            
            return response()->json([
                'success' => true,
                'data' => $scheduleData,
            ]);
            
        } catch (\Exception $e) {
            Log::error('getSchedule: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Récupérer les bulletins d'un enfant
     */
  public function getReports($childId)
{
    try {
        // Récupérer l'élève
        $enfant = Eleve::find($childId);
        
        if (!$enfant) {
            return response()->json([
                'success' => false,
                'message' => 'Élève non trouvé'
            ], 404);
        }
        
        // ✅ Récupérer les bulletins de l'élève depuis la table bulletins
        $bulletins = Bulletin::where('eleve_id', $childId)
            ->orderBy('trimestre', 'asc')
            ->get();
        
        $result = [];
        
        foreach ($bulletins as $bulletin) {
            // Récupérer les notes_data si existant
            $notesData = [];
            if ($bulletin->notes_data) {
                $notesData = json_decode($bulletin->notes_data, true);
            }
            
            $result[] = [
                'id' => $bulletin->id,
                'eleve_id' => $bulletin->eleve_id,
                'eleve_nom' => $enfant->nom,
                'eleve_prenom' => $enfant->prenom,
                'classe' => $enfant->classe->nom ?? 'N/A',
                'trimestre' => $bulletin->trimestre,
                'moyenne_generale' => (float) $bulletin->moyenne_generale,
                'rang' => $bulletin->rang,
                'total_eleves' => $bulletin->total_eleves,
                'mention' => $bulletin->mention,
                'appreciation' => $bulletin->appreciation,
                'notes_data' => $notesData,
                'date_generation' => $bulletin->created_at->format('d/m/Y H:i'),
                // Pour la compatibilité avec votre modèle Flutter
                'matieres' => $this->getMatieresFromNotes($enfant->id, $bulletin->trimestre),
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => $result
        ]);
        
    } catch (\Exception $e) {
        \Log::error('Erreur getReports: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}

// Méthode helper pour récupérer les matières avec les notes
private function getMatieresFromNotes($eleveId, $trimestre)
{
    $notes = Note::where('eleve_id', $eleveId)
        ->where('trimestre', $trimestre)
        ->with('matiere')
        ->get();
    
    $matieresData = [];
    $notesParMatiere = $notes->groupBy('matiere_id');
    
    foreach ($notesParMatiere as $matiereId => $notesGroupees) {
        $matiere = $notesGroupees->first()->matiere;
        $moyenneMatiere = $notesGroupees->avg('note');
        
        // Séparer interrogations et devoirs
        $interrogations = [];
        $devoirs = [];
        $numInterro = 1;
        $numDevoir = 1;
        
        foreach ($notesGroupees as $note) {
            if ($note->type == 'interrogation' || $note->type == 'interro') {
                $interrogations[] = [
                    'numero' => $numInterro++,
                    'note' => (float) $note->note,
                    'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                ];
            } else {
                $devoirs[] = [
                    'numero' => $numDevoir++,
                    'note' => (float) $note->note,
                    'appreciation' => $note->appreciation ?? ($note->note >= 10 ? 'Acquis' : 'À améliorer'),
                ];
            }
        }
        
        // Calculer la moyenne de la classe pour cette matière
        $moyenneClasse = Note::where('trimestre', $trimestre)
            ->whereHas('eleve', function($query) use ($eleveId) {
                $eleve = Eleve::find($eleveId);
                if ($eleve) {
                    $query->where('classe_id', $eleve->classe_id);
                }
            })
            ->where('matiere_id', $matiereId)
            ->avg('note');
        
        // Calculer le rang
        $elevesNotes = Note::where('trimestre', $trimestre)
            ->whereHas('eleve', function($query) use ($eleveId) {
                $eleve = Eleve::find($eleveId);
                if ($eleve) {
                    $query->where('classe_id', $eleve->classe_id);
                }
            })
            ->where('matiere_id', $matiereId)
            ->select('eleve_id', \DB::raw('AVG(note) as moyenne'))
            ->groupBy('eleve_id')
            ->orderBy('moyenne', 'desc')
            ->get();
        
        $rang = 1;
        foreach ($elevesNotes as $index => $en) {
            if ($en->eleve_id == $eleveId) {
                $rang = $index + 1;
                break;
            }
        }
        
        $matieresData[] = [
            'id' => $matiere->id,
            'nom' => $matiere->nom,
            'coefficient' => $matiere->coefficient,
            'moyenne' => round($moyenneMatiere, 2),
            'moyenne_classe' => round($moyenneClasse, 2),
            'rang' => $rang,
            'total_eleves' => $elevesNotes->count(),
            'interrogations' => $interrogations,
            'devoirs' => $devoirs,
        ];
    }
    
    return $matieresData;
}
    
    /**
     * Récupérer les notifications d'un parent
     */
    public function getNotifications(Request $request)
    {
        try {
            $parent = $request->user();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Parent non authentifié'
                ], 401);
            }
            
            $notifications = NotificationParent::where('parent_id', $parent->id)
                ->orderBy('created_at', 'desc')
                ->paginate(20);
            
            return response()->json([
                'success' => true,
                'data' => $notifications,
            ]);
            
        } catch (\Exception $e) {
            Log::error('getNotifications: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
public function getUnreadMessagesCount(Request $request)
{
    try {
        $parent = $request->user();
        
        if (!$parent) {
            return response()->json([
                'success' => false,
                'message' => 'Parent non authentifié'
            ], 401);
        }
        
        // Récupérer toutes les conversations du parent
        $conversationIds = Conversation::where('parent_id', $parent->id)->pluck('id');
        
        // Compter les messages non lus (envoyés par l'admin)
        $count = Message::whereIn('conversation_id', $conversationIds)
            ->where('est_lu', false)
            ->where('admin_id', '!=', null)
            ->count();
        
        return response()->json([
            'success' => true,
            'count' => $count
        ]);
        
    } catch (\Exception $e) {
        Log::error('getUnreadMessagesCount: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'count' => 0
        ], 500);
    }
}
    /**
     * Marquer une notification comme lue
     */
    public function markNotificationRead($id, Request $request)
    {
        try {
            $parent = $request->user();
            
            $notification = NotificationParent::where('id', $id)
                ->where('parent_id', $parent->id)
                ->first();
            
            if (!$notification) {
                return response()->json([
                    'success' => false,
                    'message' => 'Notification non trouvée'
                ], 404);
            }
            
            $notification->update([
                'est_lu' => true,
                'lu_at' => now(),
            ]);
            
            return response()->json([
                'success' => true,
                'message' => 'Notification marquée comme lue'
            ]);
            
        } catch (\Exception $e) {
            Log::error('markNotificationRead: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Obtenir l'appréciation
     */
    private function getAppreciation($note)
    {
        if ($note >= 16) return 'Excellent';
        if ($note >= 14) return 'Très bien';
        if ($note >= 12) return 'Bien';
        if ($note >= 10) return 'Assez bien';
        return 'Insuffisant';
    }
}