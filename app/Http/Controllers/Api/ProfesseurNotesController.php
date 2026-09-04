<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Eleve;
use App\Models\Note;
use App\Services\WhatsAppService;

class NoteController extends Controller
{
    protected $whatsappService;
    
    public function __construct(WhatsAppService $whatsappService)
    {
        $this->whatsappService = $whatsappService;
    }
    
    public function store(Request $request)
    {
        // ... sauvegarde de la note
        
        $eleve = Eleve::find($request->eleve_id);
        $note = Note::with('matiere')->find($noteId);
        
        // Message personnalisé
        $message = "📝 *Nouvelle note*\n\n";
        $message .= "Matière: {$note->matiere->nom}\n";
        $message .= "Note: {$note->note}/20\n";
        $message .= "Trimestre: {$note->trimestre}\n";
        $message .= "Appréciation: {$note->appreciation}";
        
        // Envoyer aux deux parents
        $this->whatsappService->sendToBothParents(
            $eleve,
            'Nouvelle note scolaire',
            $message,
            'note',
            ['note_id' => $note->id]
        );
        
        return response()->json(['success' => true]);
    }
}