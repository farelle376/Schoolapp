<?php
// app/Http/Controllers/Api/AdminParentController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Famille;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Hash;

class AdminParentController extends Controller
{
    /**
     * Liste des parents avec pagination et recherche
     */
    public function index(Request $request)
    {
        try {
            $query = Famille::query();
            
            // Recherche par nom, prénom, téléphone ou email
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('nom', 'like', "%{$search}%")
                      ->orWhere('prenom', 'like', "%{$search}%")
                      ->orWhere('num_telephone', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }
            
            // Filtre par type de parent
            if ($request->has('type') && !empty($request->type)) {
                $query->where('type_parent', $request->type);
            }
            
            $parents = $query->orderBy('created_at', 'desc')->paginate(20);
            
            return response()->json([
                'success' => true,
                'data' => $parents->items(),
                'current_page' => $parents->currentPage(),
                'last_page' => $parents->lastPage(),
                'total' => $parents->total(),
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController index: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Statistiques des parents
     */
    public function getStats()
    {
        try {
            $total = Famille::count();
            $peres = Famille::where('type_parent', 'pere')->count();
            $meres = Famille::where('type_parent', 'mere')->count();
            $tuteurs = Famille::where('type_parent', 'tuteur')->count();
            $actifs = Famille::where('is_active', true)->count();
            $inactifs = Famille::where('is_active', false)->count();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'total' => $total,
                    'pere' => $peres,
                    'mere' => $meres,
                    'tuteur' => $tuteurs,
                    'actif' => $actifs,
                    'inactif' => $inactifs,
                ]
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController getStats: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    
    /**
     * Créer un parent
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'type_parent' => 'required|in:pere,mere,tuteur',
                'num_telephone' => 'required|string|unique:familles',
                'email' => 'nullable|email|unique:familles',
            ]);
            
            $parent = Famille::create([
                'nom' => $request->nom,
                'prenom' => $request->prenom,
                'type_parent' => $request->type_parent,
                'num_telephone' => $request->num_telephone,
                'email' => $request->email,
                'is_active' => $request->is_active ?? true,
            ]);
            
            return response()->json([
                'success' => true,
                'message' => 'Parent créé avec succès',
                'data' => $parent
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController store: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Afficher un parent
     */
    public function show($id)
    {
        try {
            $parent = Famille::with('eleves')->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $parent
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController show: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Modifier un parent
     */
    public function update(Request $request, $id)
    {
        try {
            $parent = Famille::findOrFail($id);
            
            $request->validate([
                'nom' => 'sometimes|string|max:255',
                'prenom' => 'sometimes|string|max:255',
                'type_parent' => 'sometimes|in:pere,mere,tuteur',
                'num_telephone' => 'sometimes|string|unique:familles,num_telephone,' . $id,
                'email' => 'nullable|email|unique:familles,email,' . $id,
                'is_active' => 'sometimes|boolean',
            ]);
            
            $parent->update($request->all());
            
            return response()->json([
                'success' => true,
                'message' => 'Parent modifié avec succès',
                'data' => $parent
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController update: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Supprimer un parent
     */
    public function destroy($id)
    {
        try {
            $parent = Famille::findOrFail($id);
            $parent->delete();
            
            return response()->json([
                'success' => true,
                'message' => 'Parent supprimé avec succès'
            ]);
            
        } catch (\Exception $e) {
            Log::error('AdminParentController destroy: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}