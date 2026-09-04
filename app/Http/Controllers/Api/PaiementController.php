<?php
// app/Http/Controllers/Api/PaiementController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TranchePaiement;
use App\Models\Paiement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class PaiementController extends Controller
{
    /**
     * Récupérer les tranches de paiement d'un élève
     */
    public function getTranches($eleveId, Request $request)
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
            
            $tranches = TranchePaiement::where('eleve_id', $eleveId)
                ->orderBy('numero_tranche')
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => $tranches,
                'eleve' => [
                    'id' => $child->id,
                    'nom' => $child->nom,
                    'prenom' => $child->prenom,
                    'classe' => $child->classe ? $child->classe->nom_complet : null,
                ]
            ]);
            
        } catch (\Exception $e) {
            Log::error('getTranches: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Récupérer l'historique des paiements d'un élève
     */
    public function getHistorique($eleveId, Request $request)
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
            
            $paiements = Paiement::where('eleve_id', $eleveId)
                ->orderBy('created_at', 'desc')
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => $paiements,
            ]);
            
        } catch (\Exception $e) {
            Log::error('getHistorique: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Initier un paiement pour une tranche (méthode générique)
     */
    public function initierPaiement(Request $request)
    {
        $request->validate([
            'tranche_id' => 'required|exists:tranches_paiement,id',
            'mode_paiement' => 'required|in:orange_money,wave,free_money',
            'telephone' => 'required|string',
        ]);
        
        try {
            $tranche = TranchePaiement::findOrFail($request->tranche_id);
            $parent = $request->user();
            
            // Vérifier que l'élève appartient au parent
            $parent->eleves()->where('id', $tranche->eleve_id)->firstOrFail();
            
            if ($tranche->statut == 'paye') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette tranche a déjà été payée'
                ], 422);
            }
            
            $reference = 'PAY-' . strtoupper(Str::random(12));
            
            $paiement = Paiement::create([
                'eleve_id' => $tranche->eleve_id,
                'tranche_id' => $tranche->id,
                'reference' => $reference,
                'numero_tranche' => $tranche->numero_tranche,
                'libelle' => $tranche->libelle,
                'montant' => $tranche->montant,
                'statut' => 'en_attente',
                'description' => $tranche->description,
                'mode_paiement' => $request->mode_paiement,
                'telephone' => $request->telephone,
            ]);
            
            return response()->json([
                'success' => true,
                'message' => 'Paiement initié avec succès',
                'data' => [
                    'paiement_id' => $paiement->id,
                    'reference' => $reference,
                    'montant' => $paiement->montant,
                    'statut' => 'en_attente',
                ]
            ]);
            
        } catch (\Exception $e) {
            Log::error('initierPaiement: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Confirmer un paiement (webhook)
     */
    public function confirmerPaiement(Request $request)
    {
        $request->validate([
            'reference' => 'required|string',
            'statut' => 'required|in:valide,refuse',
        ]);
        
        try {
            $paiement = Paiement::where('reference', $request->reference)->firstOrFail();
            
            $paiement->update([
                'statut' => $request->statut,
                'date_paiement' => $request->statut == 'valide' ? now() : null,
            ]);
            
            if ($request->statut == 'valide') {
                // Mettre à jour le statut de la tranche
                TranchePaiement::where('id', $paiement->tranche_id)
                    ->update(['statut' => 'paye']);
            }
            
            return response()->json([
                'success' => true,
                'message' => 'Paiement mis à jour'
            ]);
            
        } catch (\Exception $e) {
            Log::error('confirmerPaiement: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Initier un paiement avec KKiaPay
     */
    public function payerAvecKKiaPay(Request $request)
{
    $request->validate([
        'tranche_id' => 'required|exists:tranches_paiement,id',
        'telephone' => 'required|string',
        'nom' => 'required|string',
        'email' => 'required|email',
    ]);
    
    try {
        Log::info('💰 payerAvecKKiaPay - Début', $request->all());
        
        $tranche = TranchePaiement::findOrFail($request->tranche_id);
        $parent = $request->user();
        
        // Vérifier que l'élève appartient au parent
        $parent->eleves()->where('eleves.id', $tranche->eleve_id)->firstOrFail();
        
        if ($tranche->statut == 'paye') {
            return response()->json([
                'success' => false,
                'message' => 'Cette tranche a déjà été payée'
            ], 422);
        }
        
        // Créer un paiement en attente
        $reference = 'PAY-' . strtoupper(Str::random(12));
        
        $paiement = Paiement::create([
            'eleve_id' => $tranche->eleve_id,
            'tranche_id' => $tranche->id,
            'reference' => $reference,
            'numero_tranche' => $tranche->numero_tranche,
            'libelle' => $tranche->libelle,
            'montant' => $tranche->montant,
            'statut' => 'en_attente',
            'description' => $tranche->description,
            'mode_paiement' => 'kkiapay',
            'telephone' => $request->telephone,
        ]);
        
        // URL de la page de paiement
        $paymentUrl = url('/payment/kkiapay/' . $tranche->id . '?' . http_build_query([
            'amount' => $tranche->montant,
            'phone' => $request->telephone,
            'name' => $request->nom,
            'email' => $request->email,
            'tranche_id' => $tranche->id,
            'paiement_id' => $paiement->id,
        ]));
        
        Log::info('💰 Payment URL: ' . $paymentUrl);
        
        return response()->json([
            'success' => true,
            'message' => 'Redirection vers le paiement',
            'data' => [
                'payment_url' => $paymentUrl,
                'paiement_id' => $paiement->id,
                'reference' => $reference,
            ]
        ]);
        
    } catch (\Exception $e) {
        Log::error('❌ payerAvecKKiaPay: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}public function verifierPaiementKKiaPay(Request $request)
{
    $request->validate([
        'transaction_id' => 'required|string',
        'paiement_id' => 'required|exists:paiements,id',
    ]);
    
    try {
        Log::info('🔍 verifierPaiementKKiaPay - Début', [
            'transaction_id' => $request->transaction_id,
            'paiement_id' => $request->paiement_id
        ]);
        
        $paiement = Paiement::findOrFail($request->paiement_id);
        $tranche = TranchePaiement::find($paiement->tranche_id);
        
        // Mettre à jour le paiement
        $paiement->update([
            'statut' => 'valide',
            'date_paiement' => now(),
            'transaction_id' => $request->transaction_id,
        ]);
        
        // METTRE À JOUR LA TRANCHE
        if ($tranche) {
            $tranche->update(['statut' => 'paye']);
            Log::info('✅ Tranche mise à jour: ' . $tranche->id . ' -> paye');
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Paiement vérifié avec succès',
            'data' => [
                'paiement' => $paiement,
                'tranche' => $tranche
            ]
        ]);
        
    } catch (\Exception $e) {
        Log::error('❌ verifierPaiementKKiaPay: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}
    
    /**
     * Vérifier le statut d'un paiement KKiaPay (callback après paiement)
     */
  
}