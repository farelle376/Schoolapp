<?php
// app/Services/WhatsAppService.php

namespace App\Services;

use Twilio\Rest\Client;
use App\Models\VerificationCode;
use Illuminate\Support\Facades\Log;

class WhatsAppService
{
    protected $twilio;
    
    public function __construct()
    {
        $this->twilio = new Client(
            env('TWILIO_SID'),
            env('TWILIO_AUTH_TOKEN')
        );
    }
    
    public function sendVerificationCode($phoneNumber)
    {
        try {
            // Générer un code à 4 chiffres
            $code = rand(1000, 9999);
            
            // Sauvegarder le code
            VerificationCode::create([
                'phone_number' => $phoneNumber,
                'code' => $code,
                'type' => 'login',
                'expires_at' => now()->addMinutes(10),
                'is_used' => false,
            ]);
            
            // Message WhatsApp
            $message = "🔐 *CODE DE VÉRIFICATION*\n\n";
            $message .= "Votre code de connexion SchoolApp est :\n";
            $message .= "*{$code}*\n\n";
            $message .= "Ce code est valable 10 minutes.\n";
            $message .= "Ne partagez ce code avec personne.";
            
            // Envoyer via Twilio WhatsApp
            $this->twilio->messages->create(
                "whatsapp:$phoneNumber",
                [
                    'from' => "whatsapp:" . env('TWILIO_WHATSAPP_NUMBER'),
                    'body' => $message
                ]
            );
            
            Log::info("Code WhatsApp envoyé à {$phoneNumber}: {$code}");
            return true;
            
        } catch (\Exception $e) {
            Log::error("Erreur envoi WhatsApp: " . $e->getMessage());
            return false;
        }
    }
}