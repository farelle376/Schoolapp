<?php
// app/Http/Middleware/AdminMiddleware.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        // Vérifier si l'utilisateur est admin
        // Adaptez selon votre logique (par exemple, vérifier un rôle ou un email)
        if (!$user || $user->email !== 'admin@schoolapp.com') {
            return response()->json([
                'success' => false,
                'message' => 'Accès non autorisé'
            ], 403);
        }
        
        return $next($request);
    }
}