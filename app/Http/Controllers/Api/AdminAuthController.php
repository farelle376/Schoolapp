<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Utilisateur;
use App\Models\PasswordReset;
use Illuminate\Http\Request;
use App\Mail\ResetPasswordMail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AdminAuthController extends Controller
{
    /**
     * Connexion administrateur
     */

public function loginAdmin(Request $request) 
{
    $request->validate([
        'email' => 'required|email',
        'password' => 'required|string',
    ]);

    $admin = Utilisateur::where('email', $request->email)->first();

    if (!$admin || !Hash::check($request->password, $admin->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Email ou mot de passe incorrect'
        ], 401);
    }

    $token = $admin->createToken('admin-token', ['admin'])->plainTextToken;

    return response()->json([
        'success' => true,
        'message' => 'Connexion réussie',
        'user' => [
            'id' => $admin->id,
            'name' => $admin->name,
            'email' => $admin->email,
        ],
        'token' => $token,
        'token_type' => 'Bearer',
    ]);
}

 /**
     * Envoyer un code de réinitialisation par email
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:utilisateurs,email',
        ]);

        $admin = Utilisateur::where('email', $request->email)->first();

        // Générer un code à 6 chiffres aléatoire
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Supprimer l'ancien code s'il existe
    PasswordReset::where('email', $request->email)->delete();
    
    // Stocker le nouveau code
    PasswordReset::create([
        'email' => $request->email,
        'token' => Hash::make($code),
        'created_at' => now(),
    ]);
    
    // Envoyer l'email
    try {
        Mail::to($admin->email)->send(new ResetPasswordMail($code, $admin->name));
        
        return response()->json([
            'success' => true,
            'message' => 'Un code de réinitialisation a été envoyé à votre adresse email'
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Erreur lors de l\'envoi de l\'email: ' . $e->getMessage()
        ], 500);
    }
}

    /**
     * Vérifier le code
     */
    public function verifyCode(Request $request)
{
    $request->validate([
        'email' => 'required|email|exists:utilisateurs,email',
        'code' => 'required|string|size:6',
    ]);

    $passwordReset = PasswordReset::where('email', $request->email)->first();

    if (!$passwordReset) {
        return response()->json([
            'success' => false,
            'message' => 'Aucune demande trouvée'
        ], 404);
    }

    // Vérifier le code
    if (!Hash::check($request->code, $passwordReset->token)) {
        return response()->json([
            'success' => false,
            'message' => 'Code invalide'
        ], 400);
    }

    // Vérifier l'expiration (15 minutes)
    if (now()->diffInMinutes($passwordReset->created_at) > 15) {
        $passwordReset->delete();
        return response()->json([
            'success' => false,
            'message' => 'Code expiré. Veuillez recommencer'
        ], 400);
    }

    return response()->json([
        'success' => true,
        'message' => 'Code valide'
    ]);
}

    /**
     * Réinitialiser le mot de passe
     */
   public function resetPassword(Request $request)
{
    $request->validate([
        'email' => 'required|email|exists:utilisateurs,email',
        'code' => 'required|string|size:6',
        'password' => 'required|string|min:6|confirmed',
    ]);

    $passwordReset = PasswordReset::where('email', $request->email)->first();

    if (!$passwordReset) {
        return response()->json([
            'success' => false,
            'message' => 'Aucune demande trouvée'
        ], 404);
    }

    // Vérifier le code
    if (!Hash::check($request->code, $passwordReset->token)) {
        return response()->json([
            'success' => false,
            'message' => 'Code invalide'
        ], 400);
    }

    // Vérifier l'expiration (15 minutes)
    if (now()->diffInMinutes($passwordReset->created_at) > 15) {
        $passwordReset->delete();
        return response()->json([
            'success' => false,
            'message' => 'Code expiré. Veuillez recommencer'
        ], 400);
    }

    $admin = Utilisateur::where('email', $request->email)->first();
    $admin->password = Hash::make($request->password);
    $admin->save();

    $passwordReset->delete();

    return response()->json([
        'success' => true,
        'message' => 'Mot de passe réinitialisé avec succès'
    ]);
}
        public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie'
        ]);
    }

    public function profile(Request $request)
    {
        $admin = $request->user();
        return response()->json([
            'success' => true,
            'data' => [
                'id' => $admin->id,
                'name' => $admin->name,
                'email' => $admin->email,
            ]
        ]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        $admin = $request->user();

        if (!Hash::check($request->current_password, $admin->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Mot de passe actuel incorrect'
            ], 401);

            }

        $admin->password = Hash::make($request->new_password);
        $admin->save();

        return response()->json([
            'success' => true,
            'message' => 'Mot de passe modifié avec succès'
        ]);
    }
        /**
     * Vérifier si l'utilisateur est authentifié
     */
    public function check(Request $request)
    {
        return response()->json([
            'authenticated' => $request->user() ? true : false,
            'user' => $request->user() ? [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'email' => $request->user()->email,
            ] : null,
        ]);
    }
}

