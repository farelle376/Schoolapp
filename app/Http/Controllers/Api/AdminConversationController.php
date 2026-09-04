<?php
// app/Http/Controllers/Api/AdminConversationController.php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AdminConversationController extends Controller
{
    public function index()
    {
        try {
            $conversations = Conversation::with(['parent', 'eleve', 'dernierMessage'])
                ->orderBy('dernier_message_at', 'desc')
                ->get();
            
            $data = $conversations->map(function($conv) {
                return [
                    'id' => $conv->id,
                    'parent_id' => $conv->parent_id,
                    'parent_nom' => $conv->parent ? $conv->parent->nom : '',
                    'parent_prenom' => $conv->parent ? $conv->parent->prenom : '',
                    'eleve_id' => $conv->eleve_id,
                    'eleve_nom' => $conv->eleve ? $conv->eleve->nom : null,
                    'sujet' => $conv->sujet,
                    'statut' => $conv->statut,
                    'messages_non_lus' => $conv->messages_non_lus_count,
                    'created_at' => $conv->created_at->toISOString(),
                    'dernier_message' => $conv->dernierMessage ? $conv->dernierMessage->message : null,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur index conversations: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    public function getMessages($id)
    {
        try {
            Log::info('Récupération des messages pour la conversation: ' . $id);
            
            $conversation = Conversation::find($id);
            
            if (!$conversation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conversation non trouvée'
                ], 404);
            }
            
            $messages = Message::where('conversation_id', $id)
                ->orderBy('created_at', 'asc')
                ->get();
            
            // Marquer les messages de l'admin comme lus
            Message::where('conversation_id', $id)
                ->where('parent_id', null)
                ->where('est_lu', false)
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
                    'lu_at' => $msg->lu_at ? $msg->lu_at->toISOString() : null,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur getMessages: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }

    public function sendMessage(Request $request, $id)
    {
        try {
            $request->validate([
                'message' => 'required|string',
            ]);
            
            $conversation = Conversation::find($id);
            
            if (!$conversation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conversation non trouvée'
                ], 404);
            }
            
            $admin = $request->user();
            
            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin non authentifié'
                ], 401);
            }
            
            $message = Message::create([
                'conversation_id' => $conversation->id,
                'admin_id' => $admin->id,
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
                    'est_de_admin' => true,
                    'expediteur' => $admin->name,
                    'created_at' => $message->created_at->toISOString(),
                    'est_lu' => false,
                ],
                'message' => 'Message envoyé',
            ]);
        } catch (\Exception $e) {
            Log::error('Erreur sendMessage: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }
}