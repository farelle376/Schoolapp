<?php
// app/Services/ParentAuthService.php

namespace App\Services;

use App\Models\Famille;
use App\Models\VerificationCode;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;

class ParentAuthService
{
    public function sendVerificationCode($phoneNumber)
    {
        try {
            $code = rand(1000, 9999);
            
            VerificationCode::create([
                'phone_number' => $phoneNumber,
                'code' => $code,
                'type' => 'login',
                'expires_at' => now()->addMinutes(10),
                'is_used' => false,
            ]);
            
            Log::info("=========================================");
            Log::info("📱 CODE DE VÉRIFICATION POUR {$phoneNumber}");
            Log::info("🔑 VOTRE CODE EST: {$code}");
            Log::info("⏱️  Valable 10 minutes");
            Log::info("=========================================");
            
            return true;
            
        } catch (\Exception $e) {
            Log::error("Erreur envoi code: " . $e->getMessage());
            return false;
        }
    }
    
    public function verifyCode($phoneNumber, $code)
    {
        $verificationCode = VerificationCode::where('phone_number', $phoneNumber)
            ->where('code', $code)
            ->where('is_used', false)
            ->first();
        
        if (!$verificationCode || !$verificationCode->isValid()) {
            return null;
        }
        
        $verificationCode->markAsUsed();
        
        // Utiliser Famille (ou Famille selon votre modèle)
        $parent = Famille::where('num_telephone', $phoneNumber)->first();
        
        if (!$parent) {
            return null;
        }
        
        $token = Str::random(60);
        
        return [
            'parent' => $parent,
            'token' => $token,
        ];
    }
}