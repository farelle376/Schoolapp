<?php

namespace Database\Seeders;

use App\Models\Note;
use App\Models\Eleve;
use App\Models\Matiere;
use Illuminate\Database\Seeder;

class NoteSeeder extends Seeder
{
    public function run(): void
    {
        Note::truncate();
        $this->command->info('Table note vidée avec succès.');
        $eleves = Eleve::with('classe.matieres')->get();
        $trimestres = ['1', '2', '3'];
        $note_type=['interrogation', 'devoir'];
        $notes = [];
        
        foreach ($eleves as $eleve) {
            // Récupérer les matières de la classe de l'élève
            $matieresDeLaClasse = $eleve->classe->matieres;
            
            foreach ($matieresDeLaClasse as $matiere) {
                foreach ($trimestres as $trimestre) {
                    // Générer une note aléatoire entre 0 et 20
                    $type_note=$note_type[array_rand($note_type)];
                    $noteValue = rand(0, 200) / 10;
                    
                    $notes[] = [
                        'eleve_id' => $eleve->id,
                        'matiere_id' => $matiere->id,
                        'note' => $noteValue,
                        'type_note'=>$type_note,
                        'trimestre' => $trimestre,
                        'is_validated' => rand(0, 1) ? true : false,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ];
                }
            }
        }
        
        // Insérer par lots
        foreach (array_chunk($notes, 100) as $chunk) {
            Note::insert($chunk);
        }
    }
}