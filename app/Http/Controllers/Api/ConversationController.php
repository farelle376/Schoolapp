<?php
// app/Http/Controllers/Api/ConversationController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Famille;
use App\Models\Eleve;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ConversationController extends Controller
{
    /**
     * Récupérer toutes les conversations du parent
     */
    public function index(Request $request)
    {
        try {
            $parent = $request->user();
            
            $conversations = Conversation::where('parent_id', $parent->id)
                ->with(['eleve', 'dernierMessage'])
                ->orderBy('dernier_message_at', 'desc')
                ->get();
            
            $data = $conversations->map(function($conv) {
                // Gérer le cas où eleve_id est null
                $eleveNom = null;
                if ($conv->eleve_id && $conv->eleve) {
                    $eleveNom = $conv->eleve->prenom . ' ' . $conv->eleve->nom;
                }
                
                return [
                    'id' => $conv->id,
                    'parent_id' => $conv->parent_id,
                    'eleve_id' => $conv->eleve_id,
                    'eleve_nom' => $eleveNom ?? 'Discussion générale',
                    'sujet' => $conv->sujet,
                    'statut' => $conv->statut,
                    'dernier_message' => $conv->dernierMessage ? $conv->dernierMessage->message : null,
                    'dernier_message_at' => $conv->dernier_message_at,
                    'created_at' => $conv->created_at,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('Conversation index: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Créer une nouvelle conversation
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'sujet' => 'required|string',
                'eleve_id' => 'nullable|exists:eleves,id', // eleve_id peut être null
            ]);
            
            $parent = $request->user();
            
            $conversation = Conversation::create([
                'parent_id' => $parent->id,
                'eleve_id' => $request->eleve_id, // Peut être null
                'sujet' => $request->sujet,
                'statut' => 'ouvert',
                'dernier_message_at' => now(),
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $conversation,
                'message' => 'Conversation créée',
            ]);
        } catch (\Exception $e) {
            Log::error('Conversation store: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les messages d'une conversation
     */
    public function getMessages($id, Request $request)
    {
        try {
            $parent = $request->user();
            
            $conversation = Conversation::where('id', $id)
                ->where('parent_id', $parent->id)
                ->firstOrFail();
            
            $messages = Message::where('conversation_id', $id)
                ->orderBy('created_at', 'asc')
                ->get();
            
            // Marquer les messages de l'admin comme lus
            Message::where('conversation_id', $id)
                ->where('est_lu', false)
                ->where('admin_id', '!=', null)
                ->update([
                    'est_lu' => true,
                    'lu_at' => now(),
                ]);
            
            $data = $messages->map(function($msg) {
                return [
                    'id' => $msg->id,
                    'conversation_id' => $msg->conversation_id,
                    'message' => $msg->message,
                    'est_de_admin' => $msg->admin_id !== null,
                    'expediteur' => $msg->expediteur,
                    'created_at' => $msg->created_at->toISOString(),
                    'est_lu' => $msg->est_lu,
                    'lu_at' => $msg->lu_at,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('getMessages: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    /**
     * Envoyer un message dans une conversation
     */
    public function sendMessage(Request $request, $id)
    {
        try {
            $request->validate([
                'message' => 'required|string',
            ]);
            
            $conversation = Conversation::where('id', $id)
                ->where('parent_id', $request->user()->id)
                ->firstOrFail();
            
            $parent = $request->user();
            
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'parent_id' => $parent->id,
                'message' => $request->message,
                'est_lu' => false,
            ]);
            
            $conversation->update(['dernier_message_at' => now()]);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $message->id,
                    'conversation_id' => $message->conversation_id,
                    'message' => $message->message,
                    'est_de_admin' => false,
                    'expediteur' => $parent->prenom . ' ' . $parent->nom,
                    'created_at' => $message->created_at->toISOString(),
                    'est_lu' => false,
                ],
                'message' => 'Message envoyé',
            ]);
        } catch (\Exception $e) {
            Log::error('sendMessage: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}