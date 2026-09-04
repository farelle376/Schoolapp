<?php
// app/Http/Controllers/Api/AuthController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Professeur;
use App\Models\Matiere;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{ 

    public function changePassword(Request $request)
    {
    $request->validate([
        'current_password' => 'required|string',
        'new_password' => 'required|string|min:6|confirmed',
        // ✅ Le code secret (PIN) envoyé par l'app sous la clé "new_code" —
        // n'était jusqu'ici jamais lu ni enregistré par ce contrôleur.
        'new_code' => 'nullable|string|min:4',
    ]);

    $professeur = $request->user();

    if (!Hash::check($request->current_password, $professeur->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Mot de passe actuel incorrect'
        ], 401);
    }

    $professeur->password = Hash::make($request->new_password);

    // ✅ Enregistrer le nouveau code secret (stocké en clair dans la colonne
    // `code`, comme partout ailleurs dans l'app : cf. saveNotes()).
    if ($request->filled('new_code')) {
        $professeur->code = $request->new_code;
    }

    $professeur->first_login = false; // ✅ Marquer que ce n'est plus la première connexion
    $professeur->save();

    return response()->json([
        'success' => true,
        'message' => 'Mot de passe modifié avec succès'
    ]);
}

    public function loginProfesseur(Request $request)
    {
    $request->validate([
        'identifiant' => 'required|string',
        'password' => 'required|string'
    ]);

    $prof = Professeur::where('email', $request->identifiant)
        ->orWhere('numero', $request->identifiant)
        ->first();

    if (!$prof || !Hash::check($request->password, $prof->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Identifiants incorrects'
        ], 401);
    }

    $matiere = Matiere::find($prof->matiere_id);
    $token = $prof->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'message' => 'Connexion réussie',
        'first_login' => $prof->first_login, // ✅ Indique si c'est la première connexion
        'user' => [
            'id' => $prof->id,
            'nom' => $prof->nom,
            'prenom' => $prof->prenom,
            'email' => $prof->email,
            'numero' => $prof->numero,
            'matiere' => $matiere ? $matiere->nom : 'Non attribuée',
            'matiere_id' => $prof->matiere_id,
            'first_login' => $prof->first_login,
        ],
        'token' => $token,
        'token_type' => 'Bearer',
    ]);
}

    public function logout(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie'
        ]);
    }

    public function profile(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'id' => $request->user()->id,
                'nom' => $request->user()->nom,
                'prenom' => $request->user()->prenom,
                'email' => $request->user()->email,
                'numero' => $request->user()->numero,
            ]
        ]);
    }
}