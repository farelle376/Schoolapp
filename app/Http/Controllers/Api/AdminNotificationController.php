<?php
// app/Http/Controllers/Api/AdminNotificationController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NotificationParent;
use App\Models\Famille;
use App\Models\Eleve;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminNotificationController extends Controller
{
    public function index()
    {
        try {
            // Charger les relations correctement
            $notifications = NotificationParent::with(['parent', 'eleve'])
                ->orderBy('created_at', 'desc')
                ->get();
            
            $data = $notifications->map(function($notif) {
                return [
                    'id' => $notif->id,
                    'parent_id' => $notif->parent_id,
                    'parent_nom' => $notif->parent ? $notif->parent->nom : '',
                    'parent_prenom' => $notif->parent ? $notif->parent->prenom : '',
                    'eleve_id' => $notif->eleve_id,
                    'eleve_nom' => $notif->eleve ? $notif->eleve->nom : null,
                    'titre' => $notif->titre,
                    'message' => $notif->message,
                    'type' => $notif->type,
                    'created_at' => $notif->created_at,
                    'est_lu' => $notif->est_lu,
                    'lu_at' => $notif->lu_at,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur index notifications: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $request->validate([
                'parent_id' => 'required|exists:familles,id',
                'titre' => 'required|string',
                'message' => 'required|string',
                'type' => 'nullable|in:info,warning,success,danger',
            ]);

            $notification = NotificationParent::create([
                'parent_id' => $request->parent_id,
                'eleve_id' => $request->eleve_id,
                'titre' => $request->titre,
                'message' => $request->message,
                'type' => $request->type ?? 'info',
                'est_lu' => false,
            ]);

            return response()->json([
                'success' => true,
                'data' => $notification,
                'message' => 'Notification envoyée avec succès',
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur store notification: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $notification = NotificationParent::findOrFail($id);
            $notification->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notification supprimée',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function getParents()
    {
        try {
            $parents = Famille::select('id', 'nom', 'prenom', 'num_telephone')->get();
            return response()->json([
                'success' => true,
                'data' => $parents,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    public function getEleves()
    {
        try {
            $eleves = Eleve::with('classe')->get();
            $data = $eleves->map(function($eleve) {
                return [
                    'id' => $eleve->id,
                    'nom' => $eleve->nom,
                    'prenom' => $eleve->prenom,
                    'nom_complet' => $eleve->prenom . ' ' . $eleve->nom,
                    'classe' => $eleve->classe ? $eleve->classe->nom : null,
                ];
            });
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
    public function sendToAllParents(Request $request)
    {
        try {
            $request->validate([
                'titre' => 'required|string',
                'message' => 'required|string',
                'type' => 'nullable|in:info,warning,success,danger',
            ]);

            // Récupérer tous les parents actifs
            $parents = Famille::where('is_active', true)->get();
            
            $count = 0;
            $errors = [];

            foreach ($parents as $parent) {
                try {
                    NotificationParent::create([
                        'parent_id' => $parent->id,
                        'eleve_id' => null, // Général
                        'titre' => $request->titre,
                        'message' => $request->message,
                        'type' => $request->type ?? 'info',
                        'est_lu' => false,
                    ]);
                    $count++;
                } catch (\Exception $e) {
                    $errors[] = "Parent ID {$parent->id}: " . $e->getMessage();
                }
            }

            return response()->json([
                'success' => true,
                'message' => "Notification envoyée à {$count} parent(s)",
                'data' => [
                    'total_parents' => $parents->count(),
                    'envoyes' => $count,
                    'erreurs' => $errors
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('sendToAllParents: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Envoyer une notification à plusieurs parents sélectionnés
     */
    public function sendToSelectedParents(Request $request)
    {
        try {
            $request->validate([
                'parent_ids' => 'required|array',
                'parent_ids.*' => 'exists:familles,id',
                'titre' => 'required|string',
                'message' => 'required|string',
                'type' => 'nullable|in:info,warning,success,danger',
            ]);

            $count = 0;
            foreach ($request->parent_ids as $parentId) {
                NotificationParent::create([
                    'parent_id' => $parentId,
                    'eleve_id' => null,
                    'titre' => $request->titre,
                    'message' => $request->message,
                    'type' => $request->type ?? 'info',
                    'est_lu' => false,
                ]);
                $count++;
            }

            return response()->json([
                'success' => true,
                'message' => "Notification envoyée à {$count} parent(s)"
            ]);

        } catch (\Exception $e) {
            Log::error('sendToSelectedParents: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}