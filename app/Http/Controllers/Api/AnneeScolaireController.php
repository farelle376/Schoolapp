<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AnneeScolaire;
use Illuminate\Http\Request;

class AnneeScolaireController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
       $annees = AnneeScolaire::orderBy('date_debut', 'desc')->get();
    return response()->json([
        'success' => true,
        'data' => $annees
    ]); 
    }
    
    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
{
    $request->validate([
        'libelle' => 'required|string|max:20|unique:annees_scolaires',
        'date_debut' => 'required|date',
        'date_fin' => 'required|date|after:date_debut',
    ]);

    $annee = AnneeScolaire::create($request->all());

    return response()->json([
        'success' => true,
        'message' => 'Année scolaire créée avec succès',
        'data' => $annee
    ], 201);
}

    /**
     * Display the specified resource.
     */
    public function show($id)
{
    $annee = AnneeScolaire::find($id);
    if (!$annee) {
        return response()->json(['success' => false, 'message' => 'Année non trouvée'], 404);
    }
    return response()->json(['success' => true, 'data' => $annee]);
}

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
{
    $annee = AnneeScolaire::find($id);
    if (!$annee) {
        return response()->json(['success' => false, 'message' => 'Année non trouvée'], 404);
    }

    $request->validate([
        'libelle' => 'sometimes|string|max:20|unique:annees_scolaires,libelle,' . $id,
        'date_debut' => 'sometimes|date',
        'date_fin' => 'sometimes|date|after:date_debut',
    ]);

    $annee->update($request->all());

    return response()->json([
        'success' => true,
        'message' => 'Année scolaire mise à jour',
        'data' => $annee
    ]);
}

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
{
    $annee = AnneeScolaire::find($id);
    if (!$annee) {
        return response()->json(['success' => false, 'message' => 'Année non trouvée'], 404);
    }

    // Vérifier s'il y a des inscriptions liées
    if ($annee->inscriptions()->count() > 0) {
        return response()->json([
            'success' => false,
            'message' => 'Impossible de supprimer : cette année a des inscriptions'
        ], 400);
    }

    $annee->delete();

    return response()->json([
        'success' => true,
        'message' => 'Année scolaire supprimée'
    ]);
}

public function anneeEnCours()
{
    $annee = AnneeScolaire::where('date_debut', '<=', now())
                          ->where('date_fin', '>=', now())
                          ->first();

    if (!$annee) {
        return response()->json(['success' => false, 'message' => 'Aucune année en cours'], 404);
    }

    return response()->json(['success' => true, 'data' => $annee]);
}
}
