<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmploiDuTemps;
use App\Models\Classe;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class EmploiDuTempsController extends Controller
{
    /**
     * Liste des emplois du temps
     */
    public function index(Request $request)
    {
        $query = EmploiDuTemps::with(['classe', 'matiere', 'professeur']);
        
        // Filtres
        if ($request->classe_id) {
            $query->where('classe_id', $request->classe_id);
        }
        
        if ($request->professeur_id) {
            $query->where('professeur_id', $request->professeur_id);
        }
        
        if ($request->jour) {
            $query->where('jour', $request->jour);
        }
        
        
        $emplois = $query->orderBy('jour')
            ->orderBy('heure_debut')
            ->paginate(50);
        
        return response()->json([
            'success' => true,
            'data' => $emplois
        ]);
    }
    
    /**
     * Emploi du temps d'une classe
     */
    public function getByClasse($classeId, Request $request)
    {
        $classe = Classe::findOrFail($classeId);
        
        $query = EmploiDuTemps::with(['matiere', 'professeur'])
            ->where('classe_id', $classeId)
            ->actif();
        
    
        
        $emplois = $query->get();
        
        // Organiser par jour
        $emploisParJour = [];
        $jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
        
        foreach ($jours as $jour) {
            $emploisParJour[$jour] = $emplois->where('jour', $jour)
                ->sortBy('heure_debut')
                ->values();
        }
        
        return response()->json([
            'success' => true,
            'classe' => $classe->nom_complet,
            'data' => $emploisParJour
        ]);
    }
    
    /**
     * Emploi du temps d'un professeur
     */
    public function getByProfesseur($professeurId, Request $request)
    {
        $query = EmploiDuTemps::with(['classe', 'matiere'])
            ->where('professeur_id', $professeurId)
            ->actif();
        
        
        $emplois = $query->orderBy('jour')
            ->orderBy('heure_debut')
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => $emplois
        ]);
    }
    
    /**
     * Créer un cours
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'classe_id' => 'required|exists:classes,id',
            'matiere_id' => 'required|exists:matieres,id',
            'professeur_id' => 'required|exists:professeurs,id',
            'jour' => 'required|in:lundi,mardi,mercredi,jeudi,vendredi,samedi',
            'heure_debut' => 'required|date_format:H:i',
            'heure_fin' => 'required|date_format:H:i|after:heure_debut',
            'type_cours' => 'nullable|in:cours,td,tp,evaluation',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }
        
        $emploi = EmploiDuTemps::create($request->all());
        
        // Vérifier les conflits
        $conflits = $emploi->verifierConflit();
        
        if ($conflits['has_conflit']) {
            return response()->json([
                'success' => true,
                'warning' => 'Cours créé mais avec des conflits',
                'conflits' => $conflits,
                'data' => $emploi->load(['classe', 'matiere', 'professeur'])
            ], 201);
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Cours ajouté avec succès',
            'data' => $emploi->load(['classe', 'matiere', 'professeur'])
        ], 201);
    }
    
    /**
     * Afficher un cours
     */
    public function show($id)
    {
        $emploi = EmploiDuTemps::with(['classe', 'matiere', 'professeur'])
            ->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $emploi
        ]);
    }
    
    /**
     * Mettre à jour un cours
     */
    public function update(Request $request, $id)
    {
        $emploi = EmploiDuTemps::findOrFail($id);
        
        $validator = Validator::make($request->all(), [
            'classe_id' => 'exists:classes,id',
            'matiere_id' => 'exists:matieres,id',
            'professeur_id' => 'exists:professeurs,id',
            'jour' => 'in:lundi,mardi,mercredi,jeudi,vendredi,samedi',
            'heure_debut' => 'date_format:H:i',
            'heure_fin' => 'date_format:H:i|after:heure_debut',
            'type_cours' => 'in:cours,td,tp,evaluation',
            'est_active' => 'boolean',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }
        
        $emploi->update($request->all());
        
        return response()->json([
            'success' => true,
            'message' => 'Cours mis à jour avec succès',
            'data' => $emploi->load(['classe', 'matiere', 'professeur'])
        ]);
    }
    
    /**
     * Supprimer un cours
     */
    public function destroy($id)
    {
        $emploi = EmploiDuTemps::findOrFail($id);
        $emploi->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Cours supprimé avec succès'
        ]);
    }
    
    /**
     * Activer/Désactiver un cours
     */
    public function toggleStatus($id)
    {
        $emploi = EmploiDuTemps::findOrFail($id);
        $emploi->est_active = !$emploi->est_active;
        $emploi->save();
        
        return response()->json([
            'success' => true,
            'message' => $emploi->est_active ? 'Cours activé' : 'Cours désactivé',
            'est_active' => $emploi->est_active
        ]);
    }
    
    /**
     * Vérifier les conflits pour un cours
     */
    public function checkConflits(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'classe_id' => 'required|exists:classes,id',
            'professeur_id' => 'required|exists:professeurs,id',
            'jour' => 'required|in:lundi,mardi,mercredi,jeudi,vendredi,samedi',
            'heure_debut' => 'required|date_format:H:i',
            'heure_fin' => 'required|date_format:H:i|after:heure_debut',
            'cours_id' => 'nullable|exists:emplois_du_temps,id',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }
        
        $emploi = new EmploiDuTemps($request->all());
        
        if ($request->cours_id) {
            $emploi->id = $request->cours_id;
        }
        
        $conflits = $emploi->verifierConflit();
        
        return response()->json([
            'success' => true,
            'conflits' => $conflits
        ]);
    }
}