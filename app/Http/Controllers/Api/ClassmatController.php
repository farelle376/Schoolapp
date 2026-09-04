<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classe;
use App\Models\Matiere;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class ClassmatController extends Controller
{
    // ==================== CLASSES ====================
    
    public function getClasses()
    {
        $classes = Classe::withCount('eleves')->get();
        
        return response()->json([
            'success' => true,
            'data' => $classes->map(function($classe) {
                return [
                    'id' => $classe->id,
                    'nom' => $classe->nom,
                    'effectif' => $classe->eleves_count,
                    'matieres' => $classe->matieres->map(function($matiere) {
                        return [
                            'id' => $matiere->id,
                            'nom' => $matiere->nom,
                            'coefficient' => $matiere->pivot->coefficient ?? 1,
                        ];
                    }),
                ];
            })
        ]);
    }
    public function addMultipleMatieres(Request $request)
{
    $request->validate([
        'matieres' => 'required|array',
        'matieres.*.nom' => 'required|string|unique:matieres,nom',
    ]);

    try {
        $created = [];
        foreach ($request->matieres as $matiere) {
            $newMatiere = Matiere::create([
                'nom' => $matiere['nom'],
            ]);
            $created[] = $newMatiere;
        }

        return response()->json([
            'success' => true,
            'message' => count($created) . ' matières ajoutées avec succès',
            'data' => $created
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}

    public function addClasse(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|unique:classes,libelle',
            'matieres' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        
        try {
            $classe = Classe::create([
                'nom' => $request->nom
            ]);
            
            if ($request->has('matieres') && !empty($request->matieres)) {
                $matieresData = [];
                foreach ($request->matieres as $matiere) {
                    $matieresData[$matiere['id']] = ['coefficient' => $matiere['coefficient'] ?? 1];
                }
                $classe->matieres()->attach($matieresData);
            }
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Classe ajoutée avec succès',
                'data' => $classe->load('matieres')
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ], 500);
        }
    }

    public function updateClasse(Request $request, $id)
    {
        $classe = Classe::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|unique:classes,libelle,' . $id,
            'matieres' => 'nullable|array',
            'matieres.*.id' => 'exists:matieres,id',
            'matieres.*.coefficient' => 'integer|min:1|max:10',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        
        try {
            $classe->update(['nom' => $request->nom]);
            
            if ($request->has('matieres')) {
                $matieresData = [];
                foreach ($request->matieres as $matiere) {
                    $matieresData[$matiere['id']] = ['coefficient' => $matiere['coefficient'] ?? 1];
                }
                $classe->matieres()->sync($matieresData);
            }
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Classe modifiée avec succès',
                'data' => $classe->load('matieres')
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ], 500);
        }
    }

    public function deleteClasse($id)
    {
        $classe = Classe::findOrFail($id);
        
        if ($classe->eleves()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer cette classe car elle contient des élèves'
            ], 400);
        }

        $classe->matieres()->detach();
        $classe->delete();

        return response()->json([
            'success' => true,
            'message' => 'Classe supprimée avec succès'
        ]);
    }

    // ==================== MATIERES ====================

    public function getMatieres()
    {
        $matieres = Matiere::all();
        
        return response()->json([
            'success' => true,
            'data' => $matieres->map(function($matiere) {
                return [
                    'id' => $matiere->id,
                    'nom' => $matiere->nom,
                    'coefficient' => $matiere->coefficient,
                    'classes' => $matiere->classes->map(function($classe) {
                        return [
                            'id' => $classe->id,
                            'nom' => $classe->nom,
                        ];
                    }),
                ];
            })
        ]);
    }

    public function addMatiere(Request $request)
{
    $validator = Validator::make($request->all(), [
        'nom' => 'required|string|unique:matieres',
        'coefficient' => 'nullable|integer|min:1|max:10',  // ← important: integer, pas array
        'classes' => 'nullable|array',
        'classes.*.id' => 'exists:classes,id',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'errors' => $validator->errors()
        ], 422);
    }

    DB::beginTransaction();
    
    try {
        // Créer la matière
        $matiere = Matiere::create([
            'nom' => $request->nom,
            'coefficient' => $request->coefficient ?? 1,
        ]);
        
        // Assigner les classes si présentes
        if ($request->has('classes') && is_array($request->classes) && !empty($request->classes)) {
            $classesData = [];
            foreach ($request->classes as $classe) {
                // Vérifier que $classe est un tableau et contient 'id'
                if (is_array($classe) && isset($classe['id'])) {
                    $classesData[$classe['id']] = ['coefficient' => $request->coefficient ?? 1];
                }
            }
            if (!empty($classesData)) {
                $matiere->classes()->attach($classesData);
            }
        }
        
        DB::commit();
        
        return response()->json([
            'success' => true,
            'message' => 'Matière ajoutée avec succès',
            'data' => $matiere->load('classes')
        ]);
    } catch (\Exception $e) {
        DB::rollBack();
        return response()->json([
            'success' => false,
            'message' => 'Erreur: ' . $e->getMessage()
        ], 500);
    }
}

    public function updateMatiere(Request $request, $id)
    {
        $matiere = Matiere::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string|unique:matieres,nom,' . $id,
            'coefficient' => 'nullable|integer|min:1|max:10',
            'classes' => 'nullable|array',
            'classes.*.id' => 'exists:classes,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        
        try {
            $matiere->update([
                'nom' => $request->nom,
                'coefficient' => $request->coefficient ?? $matiere->coefficient,
            ]);
            
            if ($request->has('classes')) {
                $classesData = [];
                foreach ($request->classes as $classe) {
                    $classesData[$classe['id']] = ['coefficient' => $request->coefficient ?? $matiere->coefficient];
                }
                $matiere->classes()->sync($classesData);
            }
            
            DB::commit();
            
            return response()->json([
                'success' => true,
                'message' => 'Matière modifiée avec succès',
                'data' => $matiere->load('classes')
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ], 500);
        }
    }

    public function deleteMatiere($id)
    {
        $matiere = Matiere::findOrFail($id);
        
        if ($matiere->notes()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer cette matière car elle a des notes'
            ], 400);
        }

        $matiere->classes()->detach();
        $matiere->delete();

        return response()->json([
            'success' => true,
            'message' => 'Matière supprimée avec succès'
        ]);
    }
}