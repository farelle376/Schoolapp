<?php
// app/Http/Controllers/Api/ProfesseurAdminController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Professeur;
use App\Models\Matiere;
use App\Models\Classe;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class ProfesseurAdminController extends Controller
{
    public function index()
    {
        // L'association professeur ↔ classe passe par classe_annee_matieres
        // (classe_annee -> classe), plus par une table pivot classe_professeur.
        $professeurs = Professeur::with(['matiere', 'classeAnneeMatieres.classeAnnee.classe'])->get();

        return response()->json([
            'success' => true,
            'data' => $professeurs->map(function($prof) {
                $classes = $prof->classeAnneeMatieres
                    ->pluck('classeAnnee.classe')
                    ->filter()
                    ->unique('id')
                    ->values();

                return [
                    'id' => $prof->id,
                    'nom' => $prof->nom,
                    'prenom' => $prof->prenom,
                    'email' => $prof->email,
                    'numero' => $prof->numero,
                    'matiere_id' => $prof->matiere_id,
                    'matiere_nom' => $prof->matiere ? $prof->matiere->nom : null,
                    'classes_count' => $classes->count(),
                    'classes_names' => $classes->pluck('nom')->toArray(),
                    'classe_ids' => $classes->pluck('id'),
                ];
            })
        ]);
    }

    public function getMatieres()
    {
        $matieres = Matiere::all();
        return response()->json([
            'success' => true,
            'data' => $matieres
        ]);
    }

    public function getClassesList()
    {
        $classes = Classe::all();
        return response()->json([
            'success' => true,
            // `nom` est un accesseur (basé sur la colonne réelle `libelle`)
            // et n'est pas sérialisé automatiquement en JSON : on le mappe
            // explicitement, sinon le Flutter reçoit `nom: null` et plante
            // sur Text(classe['nom']).
            'data' => $classes->map(fn($c) => [
                'id' => $c->id,
                'nom' => $c->nom ?? '',
            ]),
        ]);
    }

    public function store(Request $request)
    {
        \Log::info('=== STORE PROFESSEUR - DEBUT ===');
        \Log::info('Données reçues:', $request->all());

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string',
            'prenom' => 'required|string',
            'email' => 'required|email|unique:professeurs',
            'numero' => 'required|string',
            'matiere_id' => 'required|exists:matieres,id',
            'password' => 'nullable|string|min:4',
            'code' => 'nullable|string|min:4',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }
        \Log::info('Validation passée');

        // Identifiants par défaut si l'admin ne les précise pas
        $plainPassword = $request->password ?? 'password';
        $plainCode = $request->code ?? '1234';

        try {
            \Log::info('Création du professeur...');
            $professeur = Professeur::create([
                'nom' => $request->nom,
                'prenom' => $request->prenom,
                'email' => $request->email,
                'numero' => $request->numero,
                'matiere_id' => $request->matiere_id,
                'password' => Hash::make($plainPassword),
                'code' => $plainCode,
                'first_login' => true,
            ]);
            \Log::info('Professeur créé avec ID: ' . $professeur->id);
            \Log::info('Professeur ajouté avec succès');

            // L'assignation aux classes se fait ensuite depuis la gestion des
            // classes (table classe_annee_matieres), pas à la création.

            // ✅ Envoyer l'email au professeur
            try {
                $this->sendProfesseurEmail($professeur, $plainPassword, $plainCode);
            } catch (\Exception $e) {
                \Log::error('Erreur envoi email: ' . $e->getMessage());
            }

            return response()->json([
                'success' => true,
                'message' => 'Professeur ajouté avec succès. Un email lui a été envoyé. '
                    . 'Vous pourrez lui assigner des classes depuis la gestion des classes.',
                'data' => $professeur
            ]);
        } catch (\Exception $e) {
            \Log::error('ERREUR: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $professeur = Professeur::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nom' => 'required|string',
            'prenom' => 'required|string',
            'email' => 'required|email|unique:professeurs,email,' . $id,
            'numero' => 'required|string',
            'matiere_id' => 'required|exists:matieres,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $professeur->update([
                'nom' => $request->nom,
                'prenom' => $request->prenom,
                'email' => $request->email,
                'numero' => $request->numero,
                'matiere_id' => $request->matiere_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Professeur modifié avec succès',
                'data' => $professeur
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        $professeur = Professeur::findOrFail($id);
        $professeur->delete();

        return response()->json([
            'success' => true,
            'message' => 'Professeur supprimé avec succès'
        ]);
    }

    // ✅ Méthode pour envoyer l'email au professeur
    private function sendProfesseurEmail($professeur, $plainPassword, $plainCode)
    {
        $matiere = Matiere::find($professeur->matiere_id);

        $classesNoms = $professeur->classeAnneeMatieres()
            ->with('classeAnnee.classe')
            ->get()
            ->pluck('classeAnnee.classe.nom')
            ->filter()
            ->unique()
            ->implode(', ');

        $data = [
            'professeur' => $professeur,
            'plainPassword' => $plainPassword,
            'plainCode' => $plainCode,
            'matiereNom' => $matiere ? $matiere->nom : 'Non définie',
            'classesNom' => $classesNoms !== '' ? $classesNoms : 'Aucune classe pour le moment',
        ];

        Mail::send('emails.professeur_credentials', $data, function ($message) use ($professeur) {
            $message->to($professeur->email)
                    ->subject('Vos identifiants de connexion - SchoolApp Benin');
        });
    }
}
