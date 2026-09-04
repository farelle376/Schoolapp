<?php
// app/Http/Middleware/ParentAuth.php

namespace App\Http\Middleware;

use App\Models\ParentSession;
use Closure;
use Illuminate\Http\Request;

class ParentAuth
{
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();
        
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Token non fourni',
            ], 401);
        }
        
        $session = ParentSession::where('token', $token)
            ->where('expires_at', '>', now())
            ->first();
        
        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session invalide ou expirée',
            ], 401);
        }
        
        // Mettre à jour la dernière activité
        $session->update(['last_activity' => now()]);
        
        // Ajouter la session à la requête
        $request->merge(['parent_session' => $session]);
        
        return $next($request);
    }
}