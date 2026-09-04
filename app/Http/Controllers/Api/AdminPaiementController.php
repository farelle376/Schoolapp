<?php
// app/Http/Controllers/Api/AdminPaiementController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Paiement;
use App\Models\Classe;
use App\Models\Eleve;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Barryvdh\DomPDF\Facade\Pdf;

class AdminPaiementController extends Controller
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
     * Récupérer les paiements par classe et par tranche
     */
    public function getPaiementsByClasseAndTranche($classeId, $tranche)
    {
        try {
            // Récupérer les IDs des élèves de la classe
            $eleveIds = Eleve::where('classe_id', $classeId)->pluck('id');
            
            // Récupérer les paiements pour ces élèves et la tranche
            $paiements = Paiement::whereIn('eleve_id', $eleveIds)
                ->whereHas('tranche', function($q) use ($tranche) {
                    $q->where('numero_tranche', $tranche);
                })
                ->with(['eleve.classe', 'tranche'])
                ->orderBy('created_at', 'desc')
                ->get();
            
            $data = $paiements->map(function($paiement) {
                return [
                    'id' => $paiement->id,
                    'reference' => $paiement->reference,
                    'eleve_id' => $paiement->eleve_id,
                    'eleve_nom' => $paiement->eleve->nom,
                    'eleve_prenom' => $paiement->eleve->prenom,
                    'classe' => $paiement->eleve->classe->nom ?? 'Non assigné',
                    'numero_tranche' => $paiement->tranche->numero_tranche ?? $tranche,
                    'libelle' => $paiement->tranche->libelle ?? "Tranche $tranche",
                    'description' => $paiement->tranche->description ?? null,
                    'montant' => (float) $paiement->montant,
                    'statut' => $paiement->statut,
                    'mode_paiement' => $paiement->mode_paiement,
                    'date_paiement' => $paiement->date_paiement ? $paiement->date_paiement->format('d/m/Y') : null,
                    'created_at' => $paiement->created_at->toISOString(),
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data
            ]);
        } catch (\Exception $e) {
            Log::error('getPaiementsByClasseAndTranche: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Télécharger le reçu d'un paiement
     */
    public function telechargerRecu($id)
    {
        try {
            $paiement = Paiement::with(['eleve.classe', 'tranche'])->findOrFail($id);
            
            $pdf = Pdf::loadView('pdf.recu_paiement', [
                'paiement' => $paiement,
                'eleve' => $paiement->eleve,
                'classe' => $paiement->eleve->classe,
                'tranche' => $paiement->tranche,
            ]);
            
            return $pdf->download("recu_{$paiement->reference}.pdf");
            
        } catch (\Exception $e) {
            Log::error('telechargerRecu: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}