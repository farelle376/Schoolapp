<?php
// app/Http/Controllers/Api/EleveAdminController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Classe;
use App\Models\Eleve;
use App\Models\Famille;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class EleveAdminController extends Controller
{
    public function getAllEleves()
    {
        $eleves = Eleve::with(['classe', 'famille'])->get();
        
        return response()->json([
            'success' => true,
            'data' => $eleves->map(function($eleve) {
                return [
                    'id' => $eleve->id,
                    'nom' => $eleve->nom,
                    'prenom' => $eleve->prenom,
                    'full_name' => $eleve->prenom . ' ' . $eleve->nom,
                    'sexe' => $eleve->sexe,
                    'classe_id' => $eleve->classe_id,
                    'classe_nom' => $eleve->classe->nom,
                ];
            })
        ]);
    }

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
                ];
            })
        ]);
    }

    public function getElevesByClasse($classeId)
    {
        $eleves = Eleve::where('classe_id', $classeId)->with('parents')->get();
        
        return response()->json([
            'success' => true,
            'data' => $eleves->map(function($eleve) {
                $emailPere = null;
                $emailMere = null;
                
                foreach ($eleve->parents as $parent) {
                    if ($parent->type_parent == 'pere') {
                        $emailPere = $parent->email;
                    } elseif ($parent->type_parent == 'mere') {
                        $emailMere = $parent->email;
                    }
                }
                
                return [
                    'id' => $eleve->id,
                    'matricule' => $eleve->matricule,
                    'nom' => $eleve->nom,
                    'prenom' => $eleve->prenom,
                    'full_name' => $eleve->prenom . ' ' . $eleve->nom,
                    'sexe' => $eleve->sexe,
                    'classe_id' => $eleve->classe_id, 
                    'num_papa' => $eleve->num_papa,
                    'num_maman' => $eleve->num_maman,
                    'email_papa' => $emailPere,      
                    'email_maman' => $emailMere,
                    'parents' => $eleve->parents->map(function($parent) {
                        return [
                            'id' => $parent->id,
                            'type' => $parent->type_parent,
                            'nom' => $parent->nom,
                            'prenom' => $parent->prenom,
                            'telephone' => $parent->num_telephone,
                            'email' => $parent->email,
                        ];
                    }),
                ];
            })
        ]);
    }

    public function getAllElevesWithClasses()
    {
        $classes = Classe::with('eleves.parents')->get();
        
        $data = [];
        foreach ($classes as $classe) {
            foreach ($classe->eleves as $eleve) {
                $emailPapa = null;
                $emailMaman = null;
                
                foreach ($eleve->parents as $parent) {
                    if ($parent->type_parent == 'pere') {
                        $emailPapa = $parent->email;
                    } elseif ($parent->type_parent == 'mere') {
                        $emailMaman = $parent->email;
                    }
                }
                
                $data[] = [
                    'id' => $eleve->id,
                    'nom' => $eleve->nom,
                    'prenom' => $eleve->prenom,
                    'full_name' => $eleve->prenom . ' ' . $eleve->nom,
                    'sexe' => $eleve->sexe,
                    'classe_id' => $classe->id,
                    'classe_nom' => $classe->nom,
                    'num_papa' => $eleve->num_papa,
                    'num_maman' => $eleve->num_maman,
                    'email_papa' => $emailPapa,
                    'email_maman' => $emailMaman,
                ];
            }
        }
        
        return response()->json([
            'success' => true,
            'classes' => $classes->map(fn($c) => ['id' => $c->id, 'nom' => $c->nom]),
            'eleves' => $data
        ]);
    }

public function addEleve(Request $request)
{
    $validator = Validator::make($request->all(), [
        'nom' => 'required|string',
        'prenom' => 'required|string',
        'sexe' => 'nullable|in:M,F,Masculin,Feminin',
        'classe_id' => 'required|exists:classes,id',
        'parents' => 'required|array',
        'parents.*.type_parent' => 'required|in:pere,mere,tuteur',
        'parents.*.nom' => 'required|string',
        'parents.*.prenom' => 'required|string',
        'parents.*.telephone' => 'required|string',
        'parents.*.email' => 'nullable|email',
    ]);
    
    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur de validation',
            'errors' => $validator->errors()
        ], 422);
    }
    
    DB::beginTransaction();
    
    try {
        // Extraire les numéros de téléphone des parents
        $numPapa = null;
        $numMaman = null;
        
        foreach ($request->parents as $parent) {
            if ($parent['type_parent'] == 'pere') {
                $numPapa = $parent['telephone'];
            } elseif ($parent['type_parent'] == 'mere') {
                $numMaman = $parent['telephone'];
            }
        }

        // Convertir le sexe au bon format
        $sexe = $request->sexe;
        if ($sexe == 'M') {
            $sexe = 'Masculin';
        } elseif ($sexe == 'F') {
            $sexe = 'Feminin';
        }
        
        // Créer l'élève
        $eleve = Eleve::create([
            'nom' => $request->nom,
            'prenom' => $request->prenom,
            'sexe' => $sexe,
            'num_papa' => $numPapa,
            'num_maman' => $numMaman,
            'classe_id' => $request->classe_id,
        ]);
        
        // Créer ou récupérer les parents et les associer
        foreach ($request->parents as $parentData) {
            // ✅ Vérifier si le parent existe déjà avec cet email
            $parent = null;
            if (!empty($parentData['email'])) {
                $parent = Famille::where('email', $parentData['email'])->first();
            }
            
            // Si le parent n'existe pas, on le crée
            if (!$parent) {
                $parent = Famille::create([
                    'nom' => $parentData['nom'],
                    'prenom' => $parentData['prenom'],
                    'type_parent' => $parentData['type_parent'],
                    'num_telephone' => $parentData['telephone'],
                    'email' => $parentData['email'] ?? null,
                    'is_active' => true,
                ]);
                $isNewParent = true;
            } else {
                $isNewParent = false;
            }
            
            // Vérifier si l'association parent-élève existe déjà
            $associationExists = DB::table('parent_eleves')
                        ->where('parent_id', $parent->id)
                        ->where('eleve_id', $eleve->id)
                        ->exists();
            
            if (!$associationExists) {
                DB::table('parent_eleves')->insert([
                    'parent_id' => $parent->id,
                    'eleve_id' => $eleve->id,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
            
            // ✅ Envoyer l'email uniquement si c'est un nouveau parent
            if ($parent->email && $isNewParent) {
                try {
                    $this->sendParentEmail($parent, $eleve);
                } catch (\Exception $e) {
                    Log::error('Erreur envoi email parent: ' . $e->getMessage());
                }
            }
        }
        
        DB::commit();
        
        return response()->json([
            'success' => true,
            'message' => 'Élève ajouté avec succès.',
            'data' => $eleve->load('parents')
        ]);
        
    } catch (\Exception $e) {
        DB::rollBack();
        return response()->json([
            'success' => false,
            'message' => 'Erreur: ' . $e->getMessage()
        ], 500);
    }
}   

public function updateEleve(Request $request, $eleveId)
{
    \Log::info('=== UPDATE ELEVE ===');
    \Log::info('ID reçu: ' . $eleveId);
    \Log::info('Méthode: ' . $request->method());
    \Log::info('Headers: ' . json_encode($request->headers->all()));
    \Log::info('Données reçues:', $request->all());
    
    $eleve = Eleve::find($eleveId);
    
    if (!$eleve) {
        \Log::error('Élève non trouvé: ' . $eleveId);
        return response()->json([
            'success' => false,
            'message' => 'Élève non trouvé'
        ], 404);
    }
    
    $validator = Validator::make($request->all(), [
        'nom' => 'required|string',
        'prenom' => 'required|string',
        'sexe' => 'nullable|in:M,F,Masculin,Feminin',
        'classe_id' => 'required|exists:classes,id',
        'num_papa' => 'nullable|string',
        'num_maman' => 'nullable|string',
    ]);
    
    if ($validator->fails()) {
        \Log::error('Erreur validation:', $validator->errors()->toArray());
        return response()->json([
            'success' => false,
            'message' => 'Erreur de validation',
            'errors' => $validator->errors()
        ], 422);
    }
    
    try {
        // Convertir le sexe si nécessaire
        $sexe = $request->sexe;
        if ($sexe == 'M') {
            $sexe = 'Masculin';
        } elseif ($sexe == 'F') {
            $sexe = 'Feminin';
        }
        
        $eleve->update([
            'nom' => $request->nom,
            'prenom' => $request->prenom,
            'sexe' => $sexe,
            'classe_id' => $request->classe_id,
            'num_papa' => $request->num_papa,
            'num_maman' => $request->num_maman,
        ]);
        
        \Log::info('Élève mis à jour avec succès');
        
        return response()->json([
            'success' => true,
            'message' => 'Élève modifié avec succès',
            'data' => $eleve->fresh()
        ]);
    } catch (\Exception $e) {
        \Log::error('Erreur update: ' . $e->getMessage());
        \Log::error('Stack trace: ' . $e->getTraceAsString());
        return response()->json([
            'success' => false,
            'message' => 'Erreur: ' . $e->getMessage()
        ], 500);
    }
}

public function deleteEleve($eleveId)
{
    \Log::info('=== DELETE ELEVE ===');
    \Log::info('ID reçu: ' . $eleveId);
    \Log::info('Méthode: ' . request()->method());
    
    try {
        $eleve = Eleve::find($eleveId);
        
        if (!$eleve) {
            \Log::error('Élève non trouvé: ' . $eleveId);
            return response()->json([
                'success' => false,
                'message' => 'Élève non trouvé'
            ], 404);
        }
        
        \Log::info('Élève trouvé: ' . $eleve->nom . ' ' . $eleve->prenom);
        
        // Supprimer les associations parent_eleve
        $deletedParentLinks = DB::table('parent_eleves')->where('eleve_id', $eleveId)->delete();
        \Log::info('Associations parent_eleve supprimées: ' . $deletedParentLinks);
        
        // Supprimer l'élève
        $eleve->delete();
        
        \Log::info('Élève supprimé avec succès');
        
        return response()->json([
            'success' => true,
            'message' => 'Élève supprimé avec succès'
        ]);
    } catch (\Exception $e) {
        \Log::error('Erreur delete: ' . $e->getMessage());
        \Log::error('Stack trace: ' . $e->getTraceAsString());
        return response()->json([
            'success' => false,
            'message' => 'Erreur: ' . $e->getMessage()
        ], 500);
    }
}
public function update(Request $request, $id)
{
    return $this->updateEleve($request, $id);
}

public function destroy($id)
{
    return $this->deleteEleve($id);
}

    // ✅ Méthode privée pour envoyer l'email au parent
    private function sendParentEmail($parent, $eleve)
    {
        $typeParent = '';
        switch ($parent->type_parent) {
            case 'pere': $typeParent = 'père'; break;
            case 'mere': $typeParent = 'mère'; break;
            case 'tuteur': $typeParent = 'tuteur'; break;
        }
        
        $data = [
            'parent' => $parent,
            'eleve' => $eleve,
            'typeParent' => $typeParent,
        ];
        
        Mail::send('emails.parent_credentials', $data, function ($message) use ($parent) {
            $message->to($parent->email)
                    ->subject('Inscription de votre enfant - SchoolApp Benin');
        });
    }
}