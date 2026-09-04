<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Eleve;
use App\Models\Note;
use App\Models\Classe;
use App\Models\Interrogation;
use App\Models\Devoir;
use App\Services\WhatsAppService;
use Illuminate\Http\Request;

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
    public function getStructure(Request $request)
    {
        $classeId = $request->query('classe_id');
        $professeurId = $request->query('professeur_id');
        
        // Récupérer les interrogations de la classe
        $interrogations = Interrogation::where('classe_id', $classeId)
            ->where('professeur_id', $professeurId)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'nom' => $item->nom,
                    'date' => $item->date,
                    'max_note' => $item->max_note,
                ];
            });
        
        // Récupérer les devoirs de la classe
        $devoirs = Devoir::where('classe_id', $classeId)
            ->where('professeur_id', $professeurId)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'nom' => $item->nom,
                    'date' => $item->date,
                    'max_note' => $item->max_note,
                ];
            });
        
        // Récupérer les élèves
        $eleves = Classe::find($classeId)->eleves;
        
        // Construire la map des notes
        $notesMap = [];
        foreach ($eleves as $eleve) {
            $notes = Note::where('eleve_id', $eleve->id)
                ->where('professeur_id', $professeurId)
                ->get();
            
            $eleveNotes = [];
            foreach ($notes as $note) {
                if ($note->interrogation_id) {
                    $eleveNotes['interro_' . $note->interrogation_id] = $note->valeur;
                }
                if ($note->devoir_id) {
                    $eleveNotes['devoir_' . $note->devoir_id] = $note->valeur;
                }
            }
            $notesMap[$eleve->id] = $eleveNotes;
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'interrogations' => $interrogations,
                'devoirs' => $devoirs,
                'notes_map' => $notesMap,
            ]
        ]);
    }
}