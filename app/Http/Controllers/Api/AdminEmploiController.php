<?php
// app/Http/Controllers/Api/AdminEmploiController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmploiDuTemps;
use App\Models\Classe;
use App\Models\Matiere;
use App\Models\Professeur;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminEmploiController extends Controller
{
  public function index()
{
    try {
        $emplois = EmploiDuTemps::with(['classe', 'matiere', 'professeur'])->get();
        
        $data = $emplois->map(function($emploi) {
            return [
                'id' => $emploi->id,
                'classe_id' => $emploi->classe_id,
                'classe_nom' => $emploi->classe->nom ?? 'N/A',
                'matiere_id' => $emploi->matiere_id,
                'matiere_nom' => $emploi->matiere->nom ?? 'N/A',
                'professeur_id' => $emploi->professeur_id,
                'professeur_nom' => $emploi->professeur->nom . ' ' . ($emploi->professeur->prenom ?? ''),
                'jour' => $emploi->jour,
                'heure_debut' => $emploi->heure_debut,
                'heure_fin' => $emploi->heure_fin,
                'type_cours' => $emploi->type_cours,
                'est_active' => $emploi->est_active,
            ];
        });
        
        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}



private function formatTime($time)
    {
        if (!$time) return '';
        if (preg_match('/^\d{2}:\d{2}$/', $time)) {
            return $time;
        }
        return date('H:i', strtotime($time));
}
 
public function store(Request $request)
{
    try {
        Log::info('=== STORE EMPLOI ===');
        Log::info('Données reçues: ', $request->all());
        
        $request->validate([
            'classe_id' => 'required|exists:classes,id',
            'matiere_id' => 'required|exists:matieres,id',
            'professeur_id' => 'required|exists:professeurs,id',
            'jour' => 'required|in:lundi,mardi,mercredi,jeudi,vendredi,samedi',
            'heure_debut' => 'required',
            'heure_fin' => 'required',
            'type_cours' => 'nullable|in:cours,td,tp,evaluation',
        ]);

        // Créer l'emploi du temps
        $emploi = EmploiDuTemps::create([
            'classe_id' => $request->classe_id,
            'matiere_id' => $request->matiere_id,
            'professeur_id' => $request->professeur_id,
            'jour' => $request->jour,
            'heure_debut' => $request->heure_debut,
            'heure_fin' => $request->heure_fin,
            'type_cours' => $request->type_cours,
            'est_active' => true,
        ]);

        // Charger les relations
        $emploi->load(['classe', 'matiere', 'professeur']);
        
        Log::info('Emploi créé avec ID: ' . $emploi->id);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $emploi->id,
                'classe_id' => $emploi->classe_id,
                'classe_nom' => $emploi->classe ? $emploi->classe->nom : '',
                'matiere_id' => $emploi->matiere_id,
                'matiere_nom' => $emploi->matiere ? $emploi->matiere->nom : '',
                'professeur_id' => $emploi->professeur_id,
                'professeur_nom' => $emploi->professeur ? $emploi->professeur->nom. ' ' . $emploi->professeur->prenom : '',
                'jour' => $emploi->jour,
                'heure_debut' => $this->formatTime($emploi->heure_debut),
                'heure_fin' => $this->formatTime($emploi->heure_fin),
                'type_cours' => $emploi->type_cours,
                'est_active' => $emploi->est_active,
            ],
            'message' => 'Cours ajouté avec succès',
        ]);
    } catch (\Exception $e) {
        Log::error('Erreur store emploi: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}
   public function update(Request $request, $id)
{
    \Log::info('Update emploi called', ['id' => $id, 'data' => $request->all()]);
    
    $request->validate([
        'classe_id' => 'required|exists:classes,id',
        'matiere_id' => 'required|exists:matieres,id',
        'professeur_id' => 'required|exists:professeurs,id',
        'jour' => 'required|in:lundi,mardi,mercredi,jeudi,vendredi,samedi',
        'heure_debut' => 'required',
        'heure_fin' => 'required',
        'type_cours' => 'required|in:cours,td,tp,evaluation',
    ]);

    try {
        $emploi = EmploiDuTemps::findOrFail($id);
        $emploi->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Emploi du temps modifié avec succès',
            'data' => $emploi
        ]);
    } catch (\Exception $e) {
        \Log::error('Update error: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 500);
    }
}

    public function destroy($id)
    {
        try {
            $emploi = EmploiDuTemps::findOrFail($id);
            $emploi->delete();

            return response()->json([
                'success' => true,
                'message' => 'Cours supprimé avec succès',
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur destroy emploi: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function toggleActive($id)
    {
        try {
            $emploi = EmploiDuTemps::findOrFail($id);
            $emploi->update(['est_active' => !$emploi->est_active]);

            return response()->json([
                'success' => true,
                'message' => 'Statut modifié avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

   public function getClasses()
{
    try {
        $classes = Classe::all();
        $data = $classes->map(function($classe) {
            return [
                'id' => $classe->id,
                'nom' => $classe->nom ?? '',
                'nom_complet' => $classe->nom ?? 'Classe ' . $classe->id,
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

    public function getMatieres()
    {
        $matieres = Matiere::all();
        return response()->json([
            'success' => true,
            'data' => $matieres,
        ]);
    }

    public function getProfesseurs()
    {
        try {
            $professeurs = Professeur::select('id', 'nom', 'prenom', 'matiere_id')->get();
            Log::info('Professeurs trouvés: ' . $professeurs->count());
            
            return response()->json([
                'success' => true,
                'data' => $professeurs,
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur getProfesseurs: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

}