<?php
// app/Http/Controllers/Api/KKiaPayController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use App\Models\TranchePaiement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class KKiaPayController extends Controller
{
    /**
     * Vérifier le statut d'un paiement KKiaPay
     */
    public function verifierPaiement(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|string',
            'tranche_id' => 'required|integer',
        ]);
        
        try {
            $transactionId = $request->transaction_id;
            $trancheId = $request->tranche_id;
            
            // Récupérer la tranche
            $tranche = TranchePaiement::find($trancheId);
            if (!$tranche) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tranche non trouvée'
                ], 404);
            }
            
            // Pour le sandbox, on simule un paiement réussi
            // En production, vous devriez vérifier auprès de KKiaPay
            $isSandbox = env('KKIAPAY_ENVIRONMENT', 'sandbox') === 'sandbox';
            
            if ($isSandbox) {
                // Simulation pour le sandbox
                $paiement = Paiement::create([
                    'eleve_id' => $tranche->eleve_id,
                    'tranche_id' => $tranche->id,
                    'reference' => $transactionId,
                    'numero_tranche' => $tranche->numero_tranche,
                    'libelle' => $tranche->libelle,
                    'montant' => $tranche->montant,
                    'statut' => 'valide',
                    'date_paiement' => now(),
                    'mode_paiement' => 'kkiapay',
                    'description' => $tranche->description,
                ]);
                
                // Mettre à jour la tranche
                $tranche->update(['statut' => 'paye']);
                
                return response()->json([
                    'success' => true,
                    'message' => 'Paiement vérifié avec succès',
                    'data' => [
                        'paiement_id' => $paiement->id,
                        'reference' => $transactionId,
                    ]
                ]);
            }
            
            // Pour la production, vérifier auprès de l'API KKiaPay
            $apiKey = env('KKIAPAY_PUBLIC_KEY');
            
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type' => 'application/json',
            ])->get("https://api.kkiapay.me/v1/transactions/$transactionId");
            
            if ($response->successful()) {
                $transaction = $response->json();
                
                if (isset($transaction['status']) && $transaction['status'] === 'SUCCESS') {
                    $paiement = Paiement::create([
                        'eleve_id' => $tranche->eleve_id,
                        'tranche_id' => $tranche->id,
                        'reference' => $transactionId,
                        'numero_tranche' => $tranche->numero_tranche,
                        'libelle' => $tranche->libelle,
                        'montant' => $tranche->montant,
                        'statut' => 'valide',
                        'date_paiement' => now(),
                        'mode_paiement' => 'kkiapay',
                        'description' => $tranche->description,
                    ]);
                    
                    $tranche->update(['statut' => 'paye']);
                    
                    return response()->json([
                        'success' => true,
                        'message' => 'Paiement vérifié avec succès',
                        'data' => [
                            'paiement_id' => $paiement->id,
                            'reference' => $transactionId,
                        ]
                    ]);
                }
            }
            
            return response()->json([
                'success' => false,
                'message' => 'Paiement non confirmé'
            ], 400);
            
        } catch (\Exception $e) {
            Log::error('KKiaPay Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la vérification: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Webhook pour recevoir les confirmations de paiement
     */
    public function webhook(Request $request)
    {
        try {
            $payload = $request->all();
            Log::info('KKiaPay Webhook reçu:', $payload);
            
            if (isset($payload['transaction_id'])) {
                $transactionId = $payload['transaction_id'];
                $status = $payload['status'] ?? null;
                
                if ($status === 'SUCCESS') {
                    // Chercher une tranche associée (via metadata)
                    $trancheId = $payload['metadata']['tranche_id'] ?? null;
                    
                    if ($trancheId) {
                        $tranche = TranchePaiement::find($trancheId);
                        if ($tranche && $tranche->statut !== 'paye') {
                            $tranche->update(['statut' => 'paye']);
                            
                            Paiement::create([
                                'eleve_id' => $tranche->eleve_id,
                                'tranche_id' => $tranche->id,
                                'reference' => $transactionId,
                                'numero_tranche' => $tranche->numero_tranche,
                                'libelle' => $tranche->libelle,
                                'montant' => $tranche->montant,
                                'statut' => 'valide',
                                'date_paiement' => now(),
                                'mode_paiement' => 'kkiapay',
                                'description' => $tranche->description,
                            ]);
                        }
                    }
                }
            }
            
            return response()->json(['status' => 'success']);
            
        } catch (\Exception $e) {
            Log::error('KKiaPay Webhook error: ' . $e->getMessage());
            return response()->json(['status' => 'error'], 500);
        }
    }
    /**
 * Afficher la page de paiement (pour WebView)
 */
public function showPaymentPage($trancheId, Request $request)
{
    $tranche = TranchePaiement::with('eleve')->findOrFail($trancheId);
    $eleve = $tranche->eleve;
    
    $amount = $request->query('amount', $tranche->montant);
    $phone = $request->query('phone', '97000000');
    $name = $request->query('name', 'Parent');
    $email = $request->query('email', 'parent@schoolapp.com');
    $paiementId = $request->query('paiement_id');
    
    return view('payment.kkiapay', [
        'tranche' => $tranche,
        'eleve' => $eleve,
        'amount' => $amount,
        'phone' => $phone,
        'name' => $name,
        'email' => $email,
        'trancheId' => $trancheId,
        'paiementId' => $paiementId
    ]);
}
}