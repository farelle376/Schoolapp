<?php
// app/Http/Middleware/ParentAuthenticate.php

namespace App\Http\Middleware;

use App\Models\Famille;
use App\Models\ParentSession;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ParentAuthenticate
{
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();
        
        Log::info('ParentAuthenticate - Token reçu: ' . ($token ? substr($token, 0, 20) . '...' : 'null'));
        
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Token non fourni'
            ], 401);
        }
        
        // Récupérer la session parent par le token
        $session = ParentSession::where('token', $token)
            ->where('expires_at', '>', now())
            ->first();
        
        if ($session) {
            // Mettre à jour la dernière activité
            $session->update(['last_activity' => now()]);
            
            // Récupérer le parent
            $parent = $session->parent;
            
            if ($parent) {
                Log::info('ParentAuthenticate - Parent trouvé: ' . $parent->id . ' - ' . $parent->prenom . ' ' . $parent->nom);
                $request->setUserResolver(function () use ($parent) {
                    return $parent;
                });
                return $next($request);
            }
        }
        
        Log::error('ParentAuthenticate - Session invalide pour le token');
        
        return response()->json([
            'success' => false,
            'message' => 'Session invalide. Veuillez vous reconnecter.'
        ], 401);
    }
}