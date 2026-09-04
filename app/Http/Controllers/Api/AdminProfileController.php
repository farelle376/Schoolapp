<?php
// app/Http/Controllers/Api/AdminProfileController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\LoginHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminProfileController extends Controller
{
        public function getLoginHistory(Request $request)
    {
        // Si tu as une table login_history, récupère les données
        // Sinon, retourne des données simulées pour le moment
        return response()->json([
            'success' => true,
            'data' => [
                ['date' => '10/04/2026 14:30', 'status' => 'success', 'ip' => '192.168.1.1'],
                ['date' => '09/04/2026 09:15', 'status' => 'success', 'ip' => '192.168.1.1'],
                ['date' => '08/04/2026 18:45', 'status' => 'success', 'ip' => '192.168.1.1'],
            ]
        ]);
    }

    public function updateProfile(Request $request)
{
    $admin = $request->user();
    
    $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:utilisateurs,email,' . $admin->id,
    ]);
    
    $admin->name = $request->name;
    $admin->email = $request->email;
    $admin->save();
    
    return response()->json([
        'success' => true,
        'message' => 'Profil mis à jour avec succès',
        'data' => [
            'id' => $admin->id,
            'name' => $admin->name,
            'email' => $admin->email,
        ]
    ]);
}
}