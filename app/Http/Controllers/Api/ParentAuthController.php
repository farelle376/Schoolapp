<?php
// app/Http/Controllers/Api/ParentAuthController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Famille;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class ParentAuthController extends Controller
{
    /**
     * Étape 1: Envoyer le code OTP par email
     */
    public function sendCode(Request $request)
    {
        Log::info('📧 [sendCode] Début', ['email' => $request->email]);
        
        $request->validate([
            'email' => 'required|email|exists:familles,email',
        ]);

        try {
            $parent = Famille::where('email', $request->email)->first();
            
            if (!$parent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Email non trouvé'
                ], 404);
            }
            
            $otp = sprintf("%06d", mt_rand(1, 999999));
            
            cache(["parent_otp_{$parent->id}" => $otp], now()->addMinutes(10));
            
            Log::info('🔐 [sendCode] Code OTP généré', [
                'parent_id' => $parent->id,
                'otp' => $otp
            ]);
            
            // Envoi de l'email avec TA vue parent-otp
            try {
                Mail::send('emails.parent-otp', [
                    'parent' => $parent,
                    'otp' => $otp
                ], function ($message) use ($parent) {
                    $message->to($parent->email)
                            ->subject('🔐 Code de connexion - SchoolApp');
                });
                
                Log::info('📨 [sendCode] Email envoyé avec succès', [
                    'parent_id' => $parent->id,
                    'email' => $parent->email
                ]);
            } catch (\Exception $e) {
                Log::error('❌ [sendCode] Erreur envoi email: ' . $e->getMessage());
                // En développement, on retourne quand même le code
                if (app()->environment('local')) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Code envoyé (mode développement)',
                        'parent_id' => $parent->id,
                        'otp' => $otp
                    ]);
                }
                throw $e;
            }
            
            return response()->json([
                'success' => true,
                'message' => 'Code envoyé par email',
                'parent_id' => $parent->id,
                'otp' => app()->environment('local') ? $otp : null
            ]);
            
        } catch (\Exception $e) {
            Log::error('❌ [sendCode] Erreur générale: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'envoi du code: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Étape 2: Vérifier le code OTP et connecter
     */
    public function verifyCode(Request $request)
    {
        Log::info('🔑 [verifyCode] Début', ['parent_id' => $request->parent_id]);
        
        $request->validate([
            'parent_id' => 'required|exists:familles,id',
            'otp' => 'required|string|size:6',
        ]);

        try {
            $parent = Famille::find($request->parent_id);
            $cachedOtp = cache("parent_otp_{$parent->id}");
            
            Log::info('🔍 [verifyCode] Vérification', [
                'parent_id' => $parent->id,
                'code_saisi' => $request->otp,
                'code_stocke' => $cachedOtp
            ]);

            if (!$cachedOtp || $cachedOtp !== $request->otp) {
                return response()->json([
                    'success' => false,
                    'message' => 'Code invalide ou expiré'
                ], 401);
            }

            cache()->forget("parent_otp_{$parent->id}");
            
            // Supprimer les anciens tokens
            $parent->tokens()->delete();
            
            // Générer un nouveau token
            $token = $parent->createToken('parent-token')->plainTextToken;
            
            Log::info('✅ [verifyCode] Connexion réussie', ['parent_id' => $parent->id]);

            return response()->json([
                'success' => true,
                'message' => 'Connexion réussie',
                'token' => $token,
                'parent' => [
                    'id' => $parent->id,
                    'nom' => $parent->nom,
                    'prenom' => $parent->prenom,
                    'email' => $parent->email,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('❌ [verifyCode] Erreur: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Déconnexion
     */
    public function logout(Request $request)
    {
        try {
            $request->user()->currentAccessToken()->delete();
            return response()->json([
                'success' => true,
                'message' => 'Déconnexion réussie'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}