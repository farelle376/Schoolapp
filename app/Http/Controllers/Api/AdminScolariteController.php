<?php
// app/Http/Controllers/Api/AdminScolariteController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Eleve;
use App\Models\TranchePaiement;
use App\Models\Classe;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminScolariteController extends Controller
{
    public function getClasses()
    {
        try {
            $classes = Classe::all();
            return response()->json([
                'success' => true,
                // `nom` est un accesseur (basé sur la colonne réelle
                // `libelle`) : Laravel ne le sérialise pas automatiquement
                // en JSON, il faut le mapper explicitement, sinon le
                // Flutter reçoit des classes sans nom (chip vide/invisible).
                'data' => $classes->map(fn($c) => [
                    'id' => $c->id,
                    'nom' => $c->nom ?? '',
                ]),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    public function getElevesByClasseAndTranche($classeId, $tranche, Request $request)
    {
        try {
            $paye = $request->get('paye');
            
            $query = TranchePaiement::where('numero_tranche', $tranche)
                ->whereHas('eleve', function($q) use ($classeId) {
                    $q->where('classe_id', $classeId);
                });
            
            if ($paye !== null) {
                $query->where('statut', $paye == '1' ? 'paye' : 'non_paye');
            }
            
            $tranches = $query->with('eleve.classe')->get();
            
            $data = $tranches->map(function($t) {
                return [
                    'id' => $t->eleve->id,
                    'nom' => $t->eleve->nom,
                    'prenom' => $t->eleve->prenom,
                    'classe' => $t->eleve->classe ? $t->eleve->classe->nom : 'Non assigné',
                    'est_paye' => $t->statut == 'paye',
                    'montant' => (float) $t->montant,
                    'date_paiement' => $t->updated_at ? $t->updated_at->format('d/m/Y') : null,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
   public function getTranchesByClasse($classeId)
{
    try {
        Log::info('📊 getTranchesByClasse - Classe ID: ' . $classeId);
        
        $tranches = [
            ['numero' => 1, 'libelle' => 'Inscription', 'montant' => 0, 'description' => 'Frais d\'inscription', 'date_limite' => null],
            ['numero' => 2, 'libelle' => '1er Trimestre', 'montant' => 0, 'description' => 'Frais du premier trimestre', 'date_limite' => null],
            ['numero' => 3, 'libelle' => '2ème Trimestre', 'montant' => 0, 'description' => 'Frais du deuxième trimestre', 'date_limite' => null],
            ['numero' => 4, 'libelle' => '3ème Trimestre', 'montant' => 0, 'description' => 'Frais du troisième trimestre', 'date_limite' => null],
        ];
        
        // Récupérer les données existantes avec la date
        $storedTranches = TranchePaiement::whereHas('eleve', function($q) use ($classeId) {
            $q->where('classe_id', $classeId);
        })
        ->select('numero_tranche', 'montant', 'libelle', 'description', 'date_limite')
        ->distinct()
        ->get();
        
        Log::info('📅 Données de la base: ' . json_encode($storedTranches));
        
        foreach ($storedTranches as $stored) {
            foreach ($tranches as &$tranche) {
                if ($tranche['numero'] == $stored->numero_tranche) {
                    $tranche['montant'] = (float) $stored->montant;
                    $tranche['libelle'] = $stored->libelle;
                    $tranche['description'] = $stored->description;
                    // AJOUTER LA DATE ICI
                    $tranche['date_limite'] = $stored->date_limite ? $stored->date_limite->format('Y-m-d') : null;
                    Log::info('✅ Tranche ' . $stored->numero_tranche . ' - Date ajoutée: ' . ($tranche['date_limite'] ?? 'null'));
                    break;
                }
            }
        }
        
        return response()->json([
            'success' => true,
            'data' => $tranches,
            'classe_id' => $classeId
        ]);
        
    } catch (\Exception $e) {
        Log::error('getTranchesByClasse: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}
    /**
     * Enregistrer les montants des tranches pour une classe
     * (sans colonne classe_id, via la relation eleve)
     */
   
   public function saveTranchesByClasse(Request $request, $classeId)
{
    try {
        Log::info('💰 saveTranchesByClasse - Classe ID: ' . $classeId);
        Log::info('💰 Données reçues: ' . json_encode($request->all()));
        
        $request->validate([
            'tranches' => 'required|array',
            'tranches.*.numero' => 'required|integer|in:1,2,3,4',
            'tranches.*.montant' => 'required|numeric|min:0',
            'tranches.*.libelle' => 'required|string',
        ]);
        
        $classe = Classe::findOrFail($classeId);
        $tranchesData = $request->tranches;
        
        $eleves = Eleve::where('classe_id', $classeId)->get();
        
        if ($eleves->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun élève trouvé dans cette classe'
            ], 404);
        }
        
        // Supprimer les anciennes tranches
        foreach ($eleves as $eleve) {
            TranchePaiement::where('eleve_id', $eleve->id)->delete();
        }
        
        $createdCount = 0;
        
        foreach ($eleves as $eleve) {
            foreach ($tranchesData as $trancheData) {
                if (($trancheData['montant'] ?? 0) > 0) {
                    // Sauvegarder la date
                    $dateLimite = null;
                    if (!empty($trancheData['date_limite'])) {
                        $dateLimite = $trancheData['date_limite'];
                        Log::info('📅 Sauvegarde de la date: ' . $dateLimite);
                    }
                    
                    TranchePaiement::create([
                        'eleve_id' => $eleve->id,
                        'numero_tranche' => $trancheData['numero'],
                        'libelle' => $trancheData['libelle'],
                        'description' => $trancheData['description'] ?? null,
                        'montant' => $trancheData['montant'],
                        'statut' => 'non_paye',
                        'date_limite' => $dateLimite,
                    ]);
                    $createdCount++;
                }
            }
        }
        
        return response()->json([
            'success' => true,
            'message' => "✓ {$createdCount} tranches générées pour {$eleves->count()} élèves",
        ]);
        
    } catch (\Exception $e) {
        Log::error('saveTranchesByClasse: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}
    /**
     * Générer les tranches pour une classe spécifique (si pas encore fait)
     */
    public function generateTranchesForClasse(Request $request)
    {
        try {
            $request->validate([
                'classe_id' => 'required|exists:classes,id',
                'tranche_id' => 'required|integer|in:1,2,3,4',
                'montant' => 'required|numeric|min:0',
            ]);
            
            $classeId = $request->classe_id;
            $trancheNumero = $request->tranche_id;
            $montant = $request->montant;
            $libelle = $request->libelle ?? "Tranche $trancheNumero";
            
            $eleves = Eleve::where('classe_id', $classeId)->get();
            $count = 0;
            
            foreach ($eleves as $eleve) {
                $existing = TranchePaiement::where('eleve_id', $eleve->id)
                    ->where('numero_tranche', $trancheNumero)
                    ->first();
                
                if (!$existing) {
                    TranchePaiement::create([
                        'eleve_id' => $eleve->id,
                        'classe_id' => $classeId,
                        'numero_tranche' => $trancheNumero,
                        'libelle' => $libelle,
                        'montant' => $montant,
                        'statut' => 'non_paye',
                    ]);
                    $count++;
                }
            }
            
            return response()->json([
                'success' => true,
                'message' => "{$count} tranches générées pour {$eleves->count()} élèves",
                'data' => ['generated' => $count]
            ]);
            
        } catch (\Exception $e) {
            Log::error('generateTranchesForClasse: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
 public function getElevesWithAllTranches($classeId)
{
    try {
        $classe = Classe::findOrFail($classeId);
        
        // Récupérer tous les élèves de la classe
        $eleves = Eleve::where('classe_id', $classeId)->get();
        
        $result = [];
        
        foreach ($eleves as $eleve) {
            // Récupérer les tranches de paiement existantes pour cet élève
            $tranches = TranchePaiement::where('eleve_id', $eleve->id)
                ->orderBy('numero_tranche')
                ->get();
            
            $tranchesData = [];
            foreach ($tranches as $tranche) {
                $tranchesData[] = [
                    'numero' => $tranche->numero_tranche,
                    'libelle' => $tranche->libelle,
                    'montant' => $tranche->montant,
                    'date_limite' => $tranche->date_limite ? $tranche->date_limite->format('d/m/Y') : null,
                    'est_paye' => $tranche->statut === 'paye',
                    'date_paiement' => $tranche->date_paiement ?? null,
                ];
            }
            
            $result[] = [
                'id' => $eleve->id,
                'nom' => $eleve->nom,
                'prenom' => $eleve->prenom,
                'paiements' => $tranchesData,
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => $result,
            'classe_nom' => $classe->nom
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}
}