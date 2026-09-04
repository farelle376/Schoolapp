<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Inscription;
use App\Models\ClasseAnnee;
use App\Models\Eleve;
use Illuminate\Http\Request;

class InscriptionController extends Controller
{
    public function index(Request $request)
    {
        $query = Inscription::with(['eleve', 'classeAnnee.classe', 'classeAnnee.anneeScolaire']);

        if ($request->has('annee_scolaire_id')) {
            $query->whereHas('classeAnnee', function ($q) use ($request) {
                $q->where('annee_scolaire_id', $request->annee_scolaire_id);
            });
        }

        if ($request->has('classe_id')) {
            $query->whereHas('classeAnnee', function ($q) use ($request) {
                $q->where('classe_id', $request->classe_id);
            });
        }

        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }

        $inscriptions = $query->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $inscriptions
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'eleve_id' => 'required|exists:eleves,id',
            'classe_id' => 'required|exists:classes,id',
            'annee_scolaire_id' => 'required|exists:annees_scolaires,id',
            'date_inscription' => 'required|date',
            'statut' => 'sometimes|in:actif,transfere,abandon',
        ]);

        // Trouver ou créer la classe_annee correspondante
        $classeAnnee = ClasseAnnee::firstOrCreate([
            'classe_id' => $request->classe_id,
            'annee_scolaire_id' => $request->annee_scolaire_id,
        ]);

        // Vérifier que l'élève n'est pas déjà inscrit pour cette classe_annee
        $existing = Inscription::where('eleve_id', $request->eleve_id)
                               ->where('classe_annee_id', $classeAnnee->id)
                               ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Cet élève est déjà inscrit pour cette année scolaire'
            ], 400);
        }

        $inscription = Inscription::create([
            'eleve_id' => $request->eleve_id,
            'classe_annee_id' => $classeAnnee->id,
            'date_inscription' => $request->date_inscription,
            'statut' => $request->statut ?? 'actif',
        ]);

        $inscription->load(['eleve', 'classeAnnee.classe', 'classeAnnee.anneeScolaire']);

        return response()->json([
            'success' => true,
            'message' => 'Inscription créée avec succès',
            'data' => $inscription
        ], 201);
    }

    public function show($id)
    {
        $inscription = Inscription::with(['eleve', 'classeAnnee.classe', 'classeAnnee.anneeScolaire'])->find($id);
        if (!$inscription) {
            return response()->json(['success' => false, 'message' => 'Inscription non trouvée'], 404);
        }
        return response()->json(['success' => true, 'data' => $inscription]);
    }

    public function update(Request $request, $id)
    {
        $inscription = Inscription::find($id);
        if (!$inscription) {
            return response()->json(['success' => false, 'message' => 'Inscription non trouvée'], 404);
        }

        $request->validate([
            'classe_id' => 'sometimes|exists:classes,id',
            'annee_scolaire_id' => 'sometimes|exists:annees_scolaires,id',
            'statut' => 'sometimes|in:actif,transfere,abandon',
            'date_inscription' => 'sometimes|date',
        ]);

        $updateData = [];

        if ($request->has('classe_id') || $request->has('annee_scolaire_id')) {
            $classeId = $request->classe_id ?? $inscription->classeAnnee->classe_id;
            $anneeId = $request->annee_scolaire_id ?? $inscription->classeAnnee->annee_scolaire_id;

            $classeAnnee = ClasseAnnee::firstOrCreate([
                'classe_id' => $classeId,
                'annee_scolaire_id' => $anneeId,
            ]);

            $updateData['classe_annee_id'] = $classeAnnee->id;
        }

        if ($request->has('statut')) {
            $updateData['statut'] = $request->statut;
        }

        if ($request->has('date_inscription')) {
            $updateData['date_inscription'] = $request->date_inscription;
        }

        $inscription->update($updateData);
        $inscription->load(['eleve', 'classeAnnee.classe', 'classeAnnee.anneeScolaire']);

        return response()->json([
            'success' => true,
            'message' => 'Inscription mise à jour',
            'data' => $inscription
        ]);
    }

    public function destroy($id)
    {
        $inscription = Inscription::find($id);
        if (!$inscription) {
            return response()->json(['success' => false, 'message' => 'Inscription non trouvée'], 404);
        }

        $inscription->delete();

        return response()->json([
            'success' => true,
            'message' => 'Inscription supprimée'
        ]);
    }

    public function getByEleve($eleveId)
    {
        $inscriptions = Inscription::with(['classeAnnee.classe', 'classeAnnee.anneeScolaire'])
                                   ->where('eleve_id', $eleveId)
                                   ->orderBy('id', 'desc')
                                   ->get();

        return response()->json([
            'success' => true,
            'data' => $inscriptions
        ]);
    }

    public function passerClasseSuperieure(Request $request)
    {
        $request->validate([
            'eleve_id' => 'required|exists:eleves,id',
            'nouvelle_classe_id' => 'required|exists:classes,id',
            'annee_scolaire_id' => 'required|exists:annees_scolaires,id',
        ]);

        $eleve = Eleve::find($request->eleve_id);

        // Désactiver l'ancienne inscription active
        $ancienne = Inscription::where('eleve_id', $eleve->id)
                               ->where('statut', 'actif')
                               ->first();
        if ($ancienne) {
            $ancienne->update(['statut' => 'transfere']);
        }

        // Trouver ou créer la classe_annee pour la nouvelle classe
        $classeAnnee = ClasseAnnee::firstOrCreate([
            'classe_id' => $request->nouvelle_classe_id,
            'annee_scolaire_id' => $request->annee_scolaire_id,
        ]);

        $nouvelle = Inscription::create([
            'eleve_id' => $eleve->id,
            'classe_annee_id' => $classeAnnee->id,
            'date_inscription' => now()->toDateString(),
            'statut' => 'actif',
        ]);

        $nouvelle->load(['classeAnnee.classe', 'classeAnnee.anneeScolaire']);

        return response()->json([
            'success' => true,
            'message' => 'Élève passé en classe supérieure avec succès',
            'data' => $nouvelle
        ]);
    }
}