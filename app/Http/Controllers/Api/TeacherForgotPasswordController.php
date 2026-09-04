<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Professeur;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Mail\ResetPasswordMail;

class TeacherForgotPasswordController extends Controller
{
    /**
     * Étape 1 : Envoyer le code (expiration 5 minutes)
     */
    public function sendCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:professeurs,email',
        ]);

        $professeur = Professeur::where('email', $request->email)->first();
        $code = random_int(100000, 999999);

        DB::table('password_resets')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => Hash::make($code),
                'created_at' => Carbon::now(),
            ]
        );

        try {
            Mail::to($request->email)->send(new ResetPasswordMail($code, $professeur->prenom));
        } catch (\Exception $e) {
            Log::error('Erreur envoi email : ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'envoi de l\'email.'
            ], 500);
        }

        return response()->json([
            'success' => true,
            'message' => 'Code envoyé avec succès (valable 5 minutes).'
        ]);
    }

    /**
     * Étape 2 : Vérifier le code (expiration 5 minutes)
     */
    public function verifyCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:professeurs,email',
            'code'  => 'required|string|size:6',
        ]);

        $resetRecord = DB::table('password_resets')
            ->where('email', $request->email)
            ->first();

        if (!$resetRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune demande de réinitialisation en cours.'
            ], 404);
        }

        // ⏰ Expiration : 5 MINUTES (au lieu de 1)
        $expiration = Carbon::parse($resetRecord->created_at)->addMinutes(5);
        if (Carbon::now()->gt($expiration)) {
            // Supprimer l'ancien code expiré
            DB::table('password_resets')->where('email', $request->email)->delete();
            return response()->json([
                'success' => false,
                'message' => 'Le code a expiré (5 minutes). Veuillez en demander un nouveau.'
            ], 400);
        }

        if (!Hash::check($request->code, $resetRecord->token)) {
            return response()->json([
                'success' => false,
                'message' => 'Code invalide.'
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'Code vérifié avec succès.'
        ]);
    }

    /**
     * Étape 3 : Réinitialiser le mot de passe (expiration 5 minutes)
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:professeurs,email',
            'code'  => 'required|string|size:6',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $resetRecord = DB::table('password_resets')
            ->where('email', $request->email)
            ->first();

        if (!$resetRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune demande de réinitialisation en cours.'
            ], 404);
        }

        // ⏰ Expiration : 5 MINUTES (au lieu de 1)
        $expiration = Carbon::parse($resetRecord->created_at)->addMinutes(5);
        if (Carbon::now()->gt($expiration)) {
            DB::table('password_resets')->where('email', $request->email)->delete();
            return response()->json([
                'success' => false,
                'message' => 'Le code a expiré (5 minutes). Veuillez recommencer.'
            ], 400);
        }

        if (!Hash::check($request->code, $resetRecord->token)) {
            return response()->json([
                'success' => false,
                'message' => 'Code invalide.'
            ], 400);
        }

        // Mise à jour du mot de passe
        $professeur = Professeur::where('email', $request->email)->first();
        $professeur->password = Hash::make($request->password);
        $professeur->save();

        // Supprimer le code utilisé
        DB::table('password_resets')->where('email', $request->email)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mot de passe réinitialisé avec succès.'
        ]);
    }
}